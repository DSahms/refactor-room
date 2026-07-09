// lib/state/pipeline_state.dart
//
// Holds the in-flight PipelineRun and the final Analysis result.
// The Processing screen watches pipelineRunProvider for live events;
// the Results screen watches analysisProvider for the completed model.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/claude_client.dart';
import '../api/groq_client.dart';
import '../api/pipeline.dart';
import '../api/venice_client.dart';
import '../core/env_config.dart';
import '../models/analysis.dart';

// ─────────────────────────────────────────────────────────── PIPELINE RUN STATE

/// Wraps the active [PipelineRun] plus the last completed/failed result
/// so the Processing screen can handle the case where the run finishes
/// before the screen subscribes.
class PipelineRunState {
  final PipelineRun? activeRun;
  final Analysis? lastAnalysis;
  final String? lastError;

  const PipelineRunState({
    this.activeRun,
    this.lastAnalysis,
    this.lastError,
  });

  PipelineRunState copyWith({
    PipelineRun? activeRun,
    bool clearRun = false,
    Analysis? lastAnalysis,
    String? lastError,
    bool clearError = false,
  }) {
    return PipelineRunState(
      activeRun: clearRun ? null : (activeRun ?? this.activeRun),
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

// ─────────────────────────────────────────────────────────── NOTIFIER

class PipelineRunNotifier extends Notifier<PipelineRunState> {
  Pipeline? _pipeline;

  @override
  PipelineRunState build() => const PipelineRunState();

  /// Kick off a new pipeline run. Replaces any previous run.
  void start({required String idea, String? domainLock}) {
    _pipeline?.cancel();

    final client = switch (EnvConfig.backend) {
      LlmBackend.groq => GroqClient(apiKey: EnvConfig.groqApiKey),
      LlmBackend.venice => VeniceClient(apiKey: EnvConfig.veniceApiKey),
      LlmBackend.anthropic =>
        ClaudeClient(apiKey: EnvConfig.anthropicApiKey),
    };

    _pipeline = Pipeline(client: client);

    final run = _pipeline!.run(idea: idea, domainLock: domainLock);
    state = PipelineRunState(activeRun: run);

    run.completed.then(
      (analysis) {
        ref.read(analysisProvider.notifier).setResult(analysis);
        state = state.copyWith(clearRun: true, lastAnalysis: analysis);
      },
      onError: (Object err) {
        final msg = err is ClaudeApiError ? err.message : err.toString();
        ref.read(analysisProvider.notifier).setError(
              err is ClaudeApiError
                  ? err
                  : ClaudeApiError(
                      stage: 'pipeline',
                      message: msg,
                      cause: err,
                    ),
            );
        state = state.copyWith(clearRun: true, lastError: msg);
      },
    );
  }

  void cancel() {
    _pipeline?.cancel();
    state = const PipelineRunState();
  }
}

final pipelineRunProvider =
    NotifierProvider<PipelineRunNotifier, PipelineRunState>(
  PipelineRunNotifier.new,
);

// Convenience provider that exposes the Pipeline instance for cancel calls
// from the Processing screen's back handler.
final pipelineProvider = Provider<PipelineRunNotifier>(
  (ref) => ref.read(pipelineRunProvider.notifier),
);

// ─────────────────────────────────────────────────────────── ANALYSIS RESULT

/// Holds the completed [Analysis] (or the error) after the pipeline finishes.
class AnalysisState {
  final Analysis? analysis;
  final ClaudeApiError? error;
  final bool isLoading;

  const AnalysisState({
    this.analysis,
    this.error,
    this.isLoading = false,
  });

  bool get hasResult => analysis != null;
  bool get hasError => error != null;
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  void setLoading() {
    state = const AnalysisState(isLoading: true);
  }

  void setResult(Analysis analysis) {
    state = AnalysisState(analysis: analysis);
  }

  void setError(ClaudeApiError error) {
    state = AnalysisState(error: error);
  }

  void clear() {
    state = const AnalysisState();
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);
