// lib/api/claude_client.dart
//
// Single source of truth for talking to the Anthropic Messages API.
// Three stages, two models, one streaming entry point per stage.
//
// The prompts live in lib/api/prompts.dart and are NEVER user-visible.
// Callers pass the user's idea (Stage 1) or prior-stage output (Stages
// 2 and 3) and receive a Stream<String> of incremental text plus a
// Future<String> of the final assembled body. The processing screen
// reads the stream for live feedback; the results screen reads the
// final body.
//
// Errors are typed. A pipeline that fails mid-stage stops cleanly and
// surfaces a ClaudeApiError with enough context to render a humane
// message — not a stack trace.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'prompts.dart';

// ─────────────────────────────────────────────────────────── ERRORS

class ClaudeApiError implements Exception {
  final String stage; // 'skeleton' | 'transplants'
  final int? statusCode; // null if network/parse failure
  final String message; // human-readable, safe to surface
  final Object? cause; // underlying error for logs

  ClaudeApiError({
    required this.stage,
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() =>
      'ClaudeApiError(stage: $stage, status: $statusCode, message: $message)';
}

// ─────────────────────────────────────────────────────────── RESULT

/// One stage's live + final output. Subscribe to [stream] for incremental
/// text deltas (drive UI); await [completed] for the assembled body
/// (pass to next stage).
class StageRun {
  final Stream<String> stream;
  final Future<String> completed;

  StageRun({required this.stream, required this.completed});
}

// ─────────────────────────────────────────────────────────── CLIENT

abstract class PipelineLlmClient {
  void close();
  StageRun runSkeleton({required String idea});
  StageRun runTransplants({
    required String skeletonOutput,
    String? domainLock,
  });
}

class ClaudeClient implements PipelineLlmClient {
  final String apiKey;
  final http.Client _http;

  ClaudeClient({required this.apiKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  @override
  void close() => _http.close();

  // ───── PUBLIC STAGE ENTRY POINTS ─────

  /// Stage 1 — Skeleton Extraction. Input: raw user idea.
  @override
  StageRun runSkeleton({required String idea}) {
    final userContent = Prompts.skeleton(idea: idea);
    return _stream(
      stage: 'skeleton',
      model: ApiConfig.modelSonnet,
      maxTokens: 1500,
      system: Prompts.skeletonSystem,
      userContent: userContent,
    );
  }

  /// Stage 2 — Ranked transplants + bonus cross-domain picks.
  @override
  StageRun runTransplants({
    required String skeletonOutput,
    String? domainLock,
  }) {
    final userContent = Prompts.transplants(
      skeletonOutput: skeletonOutput,
      domainLock: domainLock,
    );
    return _stream(
      stage: 'transplants',
      model: ApiConfig.modelSonnet,
      maxTokens: 8192,
      system: Prompts.transplantsSystem,
      userContent: userContent,
    );
  }

  // ───── INTERNAL: STREAMING REQUEST ─────

  StageRun _stream({
    required String stage,
    required String model,
    required int maxTokens,
    required String system,
    required String userContent,
  }) {
    final controller = StreamController<String>();
    final buffer = StringBuffer();
    final completer = Completer<String>();

    () async {
      try {
        final request = http.Request(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/v1/messages'),
        );
        request.headers.addAll({
          'x-api-key': apiKey,
          'anthropic-version': ApiConfig.anthropicVersion,
          'content-type': 'application/json',
          'accept': 'text/event-stream',
        });
        request.body = jsonEncode({
          'model': model,
          'max_tokens': maxTokens,
          'stream': true,
          'system': system,
          'messages': [
            {'role': 'user', 'content': userContent},
          ],
        });

        final streamed = await _http.send(request).timeout(
              const Duration(seconds: 120),
              onTimeout: () => throw ClaudeApiError(
                stage: stage,
                message: 'Request timed out after 120 seconds.',
              ),
            );

        if (streamed.statusCode != 200) {
          final body = await streamed.stream.bytesToString();
          throw ClaudeApiError(
            stage: stage,
            statusCode: streamed.statusCode,
            message: _humanizeHttpError(streamed.statusCode, body),
          );
        }

        // SSE parser. Anthropic sends `event: <type>\ndata: <json>\n\n`.
        // We only care about `content_block_delta` for text_delta.
        final lines = streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final payload = line.substring(6).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final type = json['type'] as String?;

            if (type == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              if (delta?['type'] == 'text_delta') {
                final text = delta?['text'] as String? ?? '';
                if (text.isNotEmpty) {
                  buffer.write(text);
                  if (!controller.isClosed) controller.add(text);
                }
              }
            } else if (type == 'message_stop') {
              // Stream terminator. Loop ends naturally on next read.
            } else if (type == 'error') {
              final err = json['error'] as Map<String, dynamic>?;
              throw ClaudeApiError(
                stage: stage,
                message: err?['message'] as String? ??
                    'Stream returned an error event.',
              );
            }
          } catch (e) {
            // Malformed SSE payload — skip the line, keep streaming.
            if (e is ClaudeApiError) rethrow;
          }
        }

        final assembled = buffer.toString();
        if (assembled.isEmpty) {
          throw ClaudeApiError(
            stage: stage,
            message: 'Empty response from model.',
          );
        }

        await controller.close();
        completer.complete(assembled);
      } catch (e, st) {
        final err = e is ClaudeApiError
            ? e
            : ClaudeApiError(
                stage: stage,
                message: 'Network or parser failure.',
                cause: e,
              );
        if (!controller.isClosed) controller.addError(err);
        await controller.close();
        if (!completer.isCompleted) completer.completeError(err, st);
      }
    }();

    return StageRun(stream: controller.stream, completed: completer.future);
  }

  // ───── ERROR HUMANIZATION ─────

  String _humanizeHttpError(int code, String body) {
    switch (code) {
      case 400:
        return 'The request was malformed. This is a bug, not your fault.';
      case 401:
        return 'API key is invalid or missing.';
      case 403:
        return 'API key is valid but not authorized for this model.';
      case 429:
        return 'Rate limit hit. Wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Anthropic is having a moment. Try again in a few seconds.';
      default:
        return 'Unexpected response (HTTP $code).';
    }
  }
}
