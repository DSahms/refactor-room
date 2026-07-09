// lib/api/pipeline.dart
//
// Two-stage analysis: skeleton → transplants (ranked 10 + bonus 5).

import 'dart:async';

import '../models/analysis.dart';
import 'claude_client.dart';

enum StageId { skeleton, transplants }

enum StageStatus { queued, running, done, failed }

class PipelineEvent {
  final StageId stage;
  final StageStatus status;
  final double stageProgress;
  final double overallProgress;
  final String? errorMessage;

  const PipelineEvent({
    required this.stage,
    required this.status,
    required this.stageProgress,
    required this.overallProgress,
    this.errorMessage,
  });
}

class Pipeline {
  final PipelineLlmClient client;

  static const _weightSkeleton = 0.35;
  static const _weightTransplants = 0.65;

  static const _estCharsSkeleton = 2400;
  static const _estCharsTransplants = 14000;

  bool _cancelled = false;

  Pipeline({required this.client});

  void cancel() {
    _cancelled = true;
  }

  PipelineRun run({
    required String idea,
    String? domainLock,
  }) {
    final events = StreamController<PipelineEvent>();
    final completer = Completer<Analysis>();

    () async {
      try {
        _emit(events, StageId.skeleton, StageStatus.running, 0.0, 0.0);
        final skeletonBody = await _runStage(
          events: events,
          stage: StageId.skeleton,
          weightBefore: 0.0,
          weight: _weightSkeleton,
          estChars: _estCharsSkeleton,
          run: client.runSkeleton(idea: idea),
        );
        if (_cancelled) throw _CancelledException();
        _emit(events, StageId.skeleton, StageStatus.done, 1.0, _weightSkeleton);

        _emit(events, StageId.transplants, StageStatus.running, 0.0,
            _weightSkeleton);
        final transplantsBody = await _runStage(
          events: events,
          stage: StageId.transplants,
          weightBefore: _weightSkeleton,
          weight: _weightTransplants,
          estChars: _estCharsTransplants,
          run: client.runTransplants(
            skeletonOutput: skeletonBody,
            domainLock: domainLock,
          ),
        );
        if (_cancelled) throw _CancelledException();
        _emit(events, StageId.transplants, StageStatus.done, 1.0, 1.0);

        final analysis = Analysis.parse(
          idea: idea,
          domainLock: domainLock,
          skeletonRaw: skeletonBody,
          transplantsRaw: transplantsBody,
        );

        await events.close();
        completer.complete(analysis);
      } on _CancelledException {
        await events.close();
        if (!completer.isCompleted) {
          completer.completeError(
            ClaudeApiError(
              stage: 'pipeline',
              message: 'Analysis cancelled.',
            ),
          );
        }
      } catch (e, st) {
        final err = e is ClaudeApiError
            ? e
            : ClaudeApiError(
                stage: 'pipeline',
                message: 'Pipeline failed.',
                cause: e,
              );
        if (!events.isClosed) {
          events.add(PipelineEvent(
            stage: _currentStageFromError(err),
            status: StageStatus.failed,
            stageProgress: 0.0,
            overallProgress: 0.0,
            errorMessage: err.message,
          ));
          await events.close();
        }
        if (!completer.isCompleted) completer.completeError(err, st);
      }
    }();

    return PipelineRun(events: events.stream, completed: completer.future);
  }

  Future<String> _runStage({
    required StreamController<PipelineEvent> events,
    required StageId stage,
    required double weightBefore,
    required double weight,
    required int estChars,
    required StageRun run,
  }) async {
    var charsSoFar = 0;
    final sub = run.stream.listen((delta) {
      charsSoFar += delta.length;
      final raw = charsSoFar / estChars;
      final fraction = raw >= 1.0 ? 0.99 : raw;
      _emit(
        events,
        stage,
        StageStatus.running,
        fraction,
        weightBefore + (weight * fraction),
      );
    });

    try {
      return await run.completed;
    } finally {
      await sub.cancel();
    }
  }

  void _emit(
    StreamController<PipelineEvent> events,
    StageId stage,
    StageStatus status,
    double stageProgress,
    double overallProgress,
  ) {
    if (events.isClosed) return;
    events.add(PipelineEvent(
      stage: stage,
      status: status,
      stageProgress: stageProgress.clamp(0.0, 1.0),
      overallProgress: overallProgress.clamp(0.0, 1.0),
    ));
  }

  StageId _currentStageFromError(ClaudeApiError err) {
    switch (err.stage) {
      case 'skeleton':
        return StageId.skeleton;
      case 'transplants':
        return StageId.transplants;
      default:
        return StageId.skeleton;
    }
  }
}

class _CancelledException implements Exception {}

class PipelineRun {
  final Stream<PipelineEvent> events;
  final Future<Analysis> completed;

  PipelineRun({required this.events, required this.completed});
}
