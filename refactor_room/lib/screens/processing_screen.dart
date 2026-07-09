// lib/screens/processing_screen.dart
//
// Screen 02 — Pipeline. Two sequential stages with live progress.
//
// The screen subscribes to pipelineRunProvider.activeRun.events and
// keeps a local per-stage progress map. When the pipeline emits
// status: done (overallProgress == 1.0), we navigate to
// Results. Errors emit a final 'failed' event which we render inline
// rather than crashing into a toast.
//
// Back button cancels the in-flight run before popping. Without this,
// hitting back mid-analysis leaves an orphan pipeline streaming into
// state nobody reads.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/pipeline.dart';
import '../state/pipeline_state.dart';
import '../theme/tokens.dart';
import 'results_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  StreamSubscription<PipelineEvent>? _sub;

  // Per-stage status + progress. Initialized to queued / 0.0 so the
  // initial frame renders correctly even before the first event lands.
  final Map<StageId, StageStatus> _statuses = {
    StageId.skeleton: StageStatus.queued,
    StageId.transplants: StageStatus.queued,
  };
  final Map<StageId, double> _progress = {
    StageId.skeleton: 0.0,
    StageId.transplants: 0.0,
  };
  double _overall = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Subscribe after the first frame so the provider read happens in
    // a safe context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final runState = ref.read(pipelineRunProvider);
    final run = runState.activeRun;

    // No active run — either the user landed here by mistake or the
    // run already completed before we subscribed. Fall back to the
    // results screen if there's an analysis, otherwise pop.
    if (run == null) {
      if (runState.lastAnalysis != null) {
        _goToResults();
      } else if (runState.lastError != null) {
        setState(() {
          _errorMessage = runState.lastError;
        });
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    _sub = run.events.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _statuses[event.stage] = event.status;
          _progress[event.stage] = event.stageProgress;
          _overall = event.overallProgress;
          if (event.status == StageStatus.failed) {
            _errorMessage = event.errorMessage;
          }
        });
      },
      onDone: () {
        if (!mounted) return;
        // Stream closed cleanly. If all stages are done, navigate.
        final allDone = _statuses.values.every((s) => s == StageStatus.done);
        if (allDone) _goToResults();
      },
      onError: (_) {
        // Errors come through the events stream as failed events too,
        // so this is a belt-and-suspenders catch.
      },
    );
  }

  void _goToResults() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
    );
  }

  Future<void> _handleBack() async {
    // Cancel the in-flight run before popping.
    ref.read(pipelineProvider).cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: _handleBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _liveStageEyebrow(),
                        style: T.eyebrow.copyWith(color: Vellum.c2),
                      ),
                      const SizedBox(height: 16),
                      _StageHero(
                        title: _liveStageTitle(),
                        subtitle: '10 ranked  ·  5 bonus',
                        errorMessage: _errorMessage,
                      ),
                      const SizedBox(height: 40),
                      _StageRow(
                        index: 1,
                        title: 'Skeleton',
                        status: _statuses[StageId.skeleton]!,
                        progress: _progress[StageId.skeleton]!,
                      ),
                      const SizedBox(height: 28),
                      _StageRow(
                        index: 2,
                        title: 'Transplants',
                        status: _statuses[StageId.transplants]!,
                        progress: _progress[StageId.transplants]!,
                      ),
                    ],
                  ),
                ),
              ),
              _OverallBar(progress: _overall, hasError: _errorMessage != null),
            ],
          ),
        ),
      ),
    );
  }

  // ───── COPY HELPERS ─────

  String _liveStageEyebrow() {
    if (_errorMessage != null) return 'ANALYSIS STOPPED';
    final live = _currentLiveStage();
    if (live == null) return 'ANALYZING';
    switch (live) {
      case StageId.skeleton:
        return 'STAGE 01 OF 02';
      case StageId.transplants:
        return 'STAGE 02 OF 02';
    }
  }

  String _liveStageTitle() {
    if (_errorMessage != null) return 'Something broke.';
    final live = _currentLiveStage();
    if (live == null) return 'Starting up…';
    switch (live) {
      case StageId.skeleton:
        return 'Extracting the skeleton.';
      case StageId.transplants:
        return 'Ranking transplants.';
    }
  }

  StageId? _currentLiveStage() {
    for (final id in [StageId.skeleton, StageId.transplants]) {
      if (_statuses[id] == StageStatus.running) return id;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────── TOP BAR

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Vellum.c1, size: 22),
            splashRadius: 22,
          ),
          const Spacer(),
          Text(
            'ANALYZING',
            style: T.eyebrow.copyWith(color: Vellum.c2),
          ),
          const Spacer(),
          const SizedBox(width: 44), // visual balance with back arrow
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── HERO

class _StageHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? errorMessage;

  const _StageHero({
    required this.title,
    required this.subtitle,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Italicize the first word of the title — matches the editorial
    // serif treatment in the PDF ("Running the lenses").
    final words = title.split(' ');
    final firstWord = words.isNotEmpty ? words.first : title;
    final rest = words.length > 1 ? ' ${words.sublist(1).join(' ')}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: T.displaySerif.copyWith(color: Vellum.c0),
            children: [
              TextSpan(
                text: firstWord,
                style: T.displaySerif.copyWith(
                  color: Vellum.c0,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(text: rest),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? subtitle,
          style: T.bodySans.copyWith(
            color: errorMessage != null ? Tier.risk : Vellum.c2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── STAGE ROW

class _StageRow extends StatelessWidget {
  final int index;
  final String title;
  final StageStatus status;
  final double progress;

  const _StageRow({
    required this.index,
    required this.title,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == StageStatus.done;
    final isLive = status == StageStatus.running;
    final isFailed = status == StageStatus.failed;

    final iconColor = isFailed
        ? Tier.risk
        : isDone
            ? Vellum.c1
            : isLive
                ? Gilt.base
                : Vellum.c3;

    final titleColor = (isDone || isLive) ? Vellum.c0 : Vellum.c3;

    final captionText = isFailed
        ? 'failed'
        : isDone
            ? 'complete'
            : isLive
                ? 'running…'
                : 'queued';

    final captionColor = isFailed ? Tier.risk : Vellum.c3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageIcon(status: status, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '0$index  ',
                    style: T.mono.copyWith(color: Vellum.c3),
                  ),
                  Text(
                    title,
                    style: T.headlineSerif.copyWith(
                      color: titleColor,
                      fontStyle: isLive ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Hairline(progress: progress, live: isLive, failed: isFailed),
              const SizedBox(height: 6),
              Text(
                captionText,
                style: T.mono.copyWith(color: captionColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageIcon extends StatelessWidget {
  final StageStatus status;
  final Color color;

  const _StageIcon({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final isLive = status == StageStatus.running;

    final IconData icon;
    switch (status) {
      case StageStatus.done:
        icon = Icons.check;
        break;
      case StageStatus.failed:
        icon = Icons.priority_high;
        break;
      case StageStatus.running:
        icon = Icons.adjust;
        break;
      case StageStatus.queued:
        icon = Icons.circle_outlined;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Line.c2, width: 1),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: Gilt.base.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(child: Icon(icon, color: color, size: 16)),
    );
  }
}

class _Hairline extends StatelessWidget {
  final double progress;
  final bool live;
  final bool failed;

  const _Hairline({
    required this.progress,
    required this.live,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = failed ? Tier.risk : (live ? Gilt.base : Vellum.c1);
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        color: Line.c1,
        borderRadius: BorderRadius.circular(1),
      ),
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── OVERALL BAR

class _OverallBar extends StatelessWidget {
  final double progress;
  final bool hasError;

  const _OverallBar({required this.progress, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);
    final fillColor = hasError ? Tier.risk : Gilt.base;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('OVERALL', style: T.eyebrow.copyWith(color: Vellum.c3)),
              const Spacer(),
              Text(
                '$percent%',
                style: T.mono.copyWith(color: Vellum.c2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: Line.c1,
              borderRadius: BorderRadius.circular(1),
            ),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 280),
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
