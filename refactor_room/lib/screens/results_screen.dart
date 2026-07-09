// lib/screens/results_screen.dart
//
// Screen 03 — Results. Renders the completed Analysis: idea echo,
// skeleton (collapsible), all ten ranked transplants (top three with
// stronger visual weight, the other seven shown in full but calmer),
// and the wildcard at the bottom.
//
// Design rules inherited from input_screen.dart and processing_screen.dart:
//   - Editorial serif headlines with italic first word
//   - Eyebrow labels in caps, letter-spaced
//   - Hairline rules and gilt accents
//   - Monospace for meta info (rank numbers, tier chips)
//   - Vellum text hierarchy on Surface backgrounds
//
// Tap any ranked card to push DetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analysis.dart';
import '../state/pipeline_state.dart';
import '../theme/tokens.dart';
import 'detail_screen.dart';
import 'input_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(analysisProvider);
    final analysis = analysisState.analysis;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: analysis == null
            ? _EmptyState(
                error: analysisState.error?.message,
                onRestart: () => _restart(context, ref),
              )
            : _ResultsBody(
                analysis: analysis,
                onRestart: () => _restart(context, ref),
              ),
      ),
    );
  }

  void _restart(BuildContext context, WidgetRef ref) {
    ref.read(analysisProvider.notifier).clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const InputScreen()),
      (route) => false,
    );
  }
}

// ─────────────────────────────────────────────────────────── EMPTY / ERROR

class _EmptyState extends StatelessWidget {
  final String? error;
  final VoidCallback onRestart;

  const _EmptyState({required this.error, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error != null ? 'ANALYSIS FAILED' : 'NO RESULTS',
            style: T.eyebrow.copyWith(
              color: error != null ? Tier.risk : Vellum.c2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Run an analysis to see results.',
            style: T.bodySerif.copyWith(color: Vellum.c1),
          ),
          const Spacer(),
          _PrimaryButton(label: 'New Analysis', onTap: onRestart),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── BODY

class _ResultsBody extends StatelessWidget {
  final Analysis analysis;
  final VoidCallback onRestart;

  const _ResultsBody({required this.analysis, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TopBar(onRestart: onRestart),
              const SizedBox(height: 32),
              _IdeaEcho(idea: analysis.idea, domainLock: analysis.domainLock),
              const SizedBox(height: 32),
              _SkeletonBlock(skeleton: analysis.skeleton),
              const SizedBox(height: 40),
              _SectionEyebrow(
                label: '§ 02  ·  ALL TRANSPLANTS RANKED',
                caption: '10 ranked  ·  by viability',
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          sliver: SliverList.separated(
            itemCount: analysis.rankedTransplants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final result = analysis.rankedTransplants[index];
              final isTopThree = result.rank <= 3;
              return _TransplantCard(
                result: result,
                isTopThree: isTopThree,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailScreen(result: result),
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (analysis.bonusTransplants.isNotEmpty) ...[
                _SectionEyebrow(
                  label: '§ 03  ·  BONUS TRANSPLANTS',
                  caption: 'viable in distant domains',
                ),
                const SizedBox(height: 16),
                ...analysis.bonusTransplants.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BonusCard(bonus: b),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _PrimaryButton(label: 'New Analysis', onTap: onRestart),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── TOP BAR

class _TopBar extends StatelessWidget {
  final VoidCallback onRestart;
  const _TopBar({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'ANALYSIS COMPLETE',
          style: T.eyebrow.copyWith(color: Vellum.c2),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onRestart,
          child: Text(
            'NEW',
            style: T.eyebrow.copyWith(color: Gilt.base),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── IDEA ECHO

class _IdeaEcho extends StatelessWidget {
  final String idea;
  final String? domainLock;

  const _IdeaEcho({required this.idea, required this.domainLock});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THE IDEA', style: T.eyebrow.copyWith(color: Vellum.c3)),
        const SizedBox(height: 12),
        Text(
          idea,
          style: T.bodySerif.copyWith(
            color: Vellum.c0,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (domainLock != null && domainLock!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'DOMAIN LOCK',
                style: T.eyebrow.copyWith(color: Vellum.c3),
              ),
              const SizedBox(width: 8),
              Text(
                domainLock!,
                style: T.mono.copyWith(color: Gilt.light),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── SKELETON

class _SkeletonBlock extends StatefulWidget {
  final Skeleton skeleton;
  const _SkeletonBlock({required this.skeleton});

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.skeleton;
    return Container(
      decoration: BoxDecoration(
        color: Surface.c1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Line.c1, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '§ 01  ·  THE SKELETON',
                    style: T.eyebrow.copyWith(color: Vellum.c2),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Vellum.c2,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonField(
                      label: 'The skeleton', body: s.theSkeleton),
                  _SkeletonField(
                      label: 'Problem archetype',
                      body: s.problemArchetype),
                  _SkeletonField(
                      label: 'Value mechanic', body: s.valueMechanic),
                  _SkeletonField(
                      label: 'Dependencies', body: s.dependencies),
                  _SkeletonField(
                      label: 'Hidden constraint',
                      body: s.hiddenConstraint,
                      isLast: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SkeletonField extends StatelessWidget {
  final String label;
  final String body;
  final bool isLast;
  const _SkeletonField({
    required this.label,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: T.eyebrow.copyWith(color: Vellum.c3),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: T.bodySerif.copyWith(color: Vellum.c0),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TRANSPLANT CARD

class _TransplantCard extends StatelessWidget {
  final RankedTransplant result;
  final bool isTopThree;
  final VoidCallback onTap;

  const _TransplantCard({
    required this.result,
    required this.isTopThree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isTopThree ? Surface.c2 : Surface.c1;
    final borderColor = isTopThree ? Gilt.dim : Line.c1;
    final borderWidth = isTopThree ? 1.5 : 1.0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  result.rank.toString().padLeft(2, '0'),
                  style: T.mono.copyWith(
                    color: isTopThree ? Gilt.base : Vellum.c3,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    result.title.isNotEmpty
                        ? result.title
                        : 'Transplant ${result.rank}',
                    style: (isTopThree
                            ? T.headlineSerif
                            : T.headlineSerif.copyWith(fontSize: 19))
                        .copyWith(
                      color: Vellum.c0,
                      fontStyle:
                          isTopThree ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TierChip(tier: result.viabilityTier),
              ],
            ),
            if (result.targetUser.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CardField(
                label: 'Target user',
                body: result.targetUser,
                emphasized: isTopThree,
              ),
            ],
            if (result.adaptation.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CardField(
                label: 'Adaptation',
                body: result.adaptation,
                emphasized: isTopThree,
              ),
            ],
            if (result.mvp.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CardField(
                label: 'MVP',
                body: result.mvp,
                emphasized: isTopThree,
              ),
            ],
            if (result.firstDollar.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CardField(
                label: 'First dollar',
                body: result.firstDollar,
                emphasized: isTopThree,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'TAP FOR FULL ANALYSIS',
                  style: T.eyebrow.copyWith(color: Vellum.c3),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward,
                  color: isTopThree ? Gilt.base : Vellum.c2,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _BonusCard extends StatelessWidget {
  final BonusTransplant bonus;
  const _BonusCard({required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Surface.c1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Gilt.dim, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bonus.rank.toString().padLeft(2, '0'),
                style: T.mono.copyWith(color: Gilt.base, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bonus.title,
                  style: T.headlineSerif.copyWith(
                    color: Vellum.c0,
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          if (bonus.domain.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bonus.domain.toUpperCase(),
              style: T.eyebrow.copyWith(color: Vellum.c3),
            ),
          ],
          if (bonus.targetUser.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bonus.targetUser,
              style: T.bodySerif.copyWith(color: Vellum.c1),
            ),
          ],
          if (bonus.rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bonus.rationale,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: T.bodySerif.copyWith(color: Vellum.c0),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String body;
  final bool emphasized;

  const _CardField({
    required this.label,
    required this.body,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: T.eyebrow.copyWith(color: Vellum.c3),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          maxLines: emphasized ? 4 : 2,
          overflow: TextOverflow.ellipsis,
          style: T.bodySerif.copyWith(
            color: emphasized ? Vellum.c0 : Vellum.c1,
            fontSize: emphasized ? 15 : 14,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── TIER CHIP

class _TierChip extends StatelessWidget {
  final ViabilityTier tier;
  const _TierChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (tier) {
      ViabilityTier.strong => (Tier.strong, 'STRONG'),
      ViabilityTier.viable => (Tier.viable, 'VIABLE'),
      ViabilityTier.weak => (Tier.weak, 'WEAK'),
      ViabilityTier.highRisk => (Tier.risk, 'HIGH RISK'),
      ViabilityTier.unknown => (Tier.unknown, '—'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: T.eyebrow.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── SECTION EYEBROW

class _SectionEyebrow extends StatelessWidget {
  final String label;
  final String caption;
  const _SectionEyebrow({required this.label, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.eyebrow.copyWith(color: Vellum.c2)),
        const SizedBox(height: 6),
        Text(caption, style: T.bodySans.copyWith(color: Vellum.c3)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── PRIMARY BUTTON

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Gilt.base,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Gilt.base.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: T.button.copyWith(color: Surface.c0)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Surface.c0, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
