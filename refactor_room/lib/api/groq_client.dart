// Groq OpenAI-compatible streaming client — same stage API as ClaudeClient.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'claude_client.dart';
import 'prompts.dart';

class GroqClient implements PipelineLlmClient {
  final String apiKey;
  final http.Client _http;

  GroqClient({required this.apiKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  @override
  void close() => _http.close();

  @override
  StageRun runSkeleton({required String idea}) {
    return _stream(
      stage: 'skeleton',
      maxTokens: 1500,
      system: Prompts.skeletonSystem,
      userContent: Prompts.skeleton(idea: idea),
    );
  }

  @override
  StageRun runTransplants({
    required String skeletonOutput,
    String? domainLock,
  }) {
    return _stream(
      stage: 'transplants',
      maxTokens: 8192,
      system: Prompts.transplantsSystem,
      userContent: Prompts.transplants(
        skeletonOutput: skeletonOutput,
        domainLock: domainLock,
      ),
    );
  }

  StageRun _stream({
    required String stage,
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
          Uri.parse(ApiConfig.groqBaseUrl),
        );
        request.headers.addAll({
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        });
        request.body = jsonEncode({
          'model': ApiConfig.groqModel,
          'max_tokens': maxTokens,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': userContent},
          ],
        });

        final streamed = await _http.send(request).timeout(
              const Duration(seconds: 180),
              onTimeout: () => throw ClaudeApiError(
                stage: stage,
                message: 'Request timed out after 180 seconds.',
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

        await for (final line in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (!line.startsWith('data: ')) continue;
          final payload = line.substring(6).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final text = delta?['content'] as String? ?? '';
            if (text.isNotEmpty) {
              buffer.write(text);
              if (!controller.isClosed) controller.add(text);
            }
          } catch (e) {
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

  String _humanizeHttpError(int code, String body) {
    switch (code) {
      case 401:
        return 'Groq API key is invalid or missing.';
      case 429:
        return 'Groq rate limit hit. Wait a moment and try again.';
      default:
        return 'Groq error (HTTP $code).';
    }
  }
}
