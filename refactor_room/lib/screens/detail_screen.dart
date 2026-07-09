// lib/screens/detail_screen.dart
//
// Screen 04 — Detail. Full drilldown for a single RankedTransplant.
// Shows rank, title, viability tier, every parsed field, risk
// flags as a list, top-three-only fields (current workaround,
// failure mode, unfair advantage) when present, and the raw output
// in a collapsible block at the bottom for full transparency.
//
// Visual rules inherited from results_screen.dart:
//   - Editorial serif headlines with italic accent
//   - Eyebrow caps labels, letter-spaced
//   - Hairline rules between sections
//   - Vellum text on Surface backgrounds, Gilt accents
//   - Tier chip color-coded from the design system

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/analysis.dart';
import '../theme/tokens.dart';

class DetailScreen extends StatelessWidget {
  final RankedTransplant result;
  const DetailScreen({super.key, required this.result});

  Future<void> _copyTransplant(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: result.toClipboardText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: T.bodySans.copyWith(color: Vellum.c0),
        ),
        backgroundColor: Surface.c2,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = result.rank <= 3;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              onBack: () => Navigator.of(context).pop(),
              onCopy: () => _copyTransplant(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(result: result, isTopThree: isTopThree),
                    const SizedBox(height: 32),
                    _PrimaryFields(result: result),
                    if (result.riskFlags.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _RiskFlagsBlock(flags: result.riskFlags),
                    ],
                    if (isTopThree) ...[
                      if (result.currentWorkaround != null &&
                          result.currentWorkaround!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _DeepField(
                          eyebrow: 'CURRENT WORKAROUND',
                          body: result.currentWorkaround!,
                        ),
                      ],
                      if (result.failureMode != null &&
                          result.failureMode!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _DeepField(
                          eyebrow: 'FAILURE MODE',
                          body: result.failureMode!,
                        ),
                      ],
                      if (result.unfairAdvantage != null &&
                          result.unfairAdvantage!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _DeepField(
                          eyebrow: 'UNFAIR ADVANTAGE',
                          body: result.unfairAdvantage!,
                        ),
                      ],
                    ],
                    if (result.rawOutput.trim().isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _RawOutputBlock(
                        raw: result.rawOutput,
                        initiallyExpanded: !result.hasStructuredFields,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TOP BAR

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCopy;
  const _TopBar({required this.onBack, required this.onCopy});

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
            tooltip: 'Back',
          ),
          const Spacer(),
          Text(
            'TRANSPLANT DETAIL',
            style: T.eyebrow.copyWith(color: Vellum.c2),
          ),
          const Spacer(),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, color: Vellum.c1, size: 20),
            splashRadius: 22,
            tooltip: 'Copy transplant',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── HEADER

class _Header extends StatelessWidget {
  final RankedTransplant result;
  final bool isTopThree;
  const _Header({required this.result, required this.isTopThree});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'RANK',
              style: T.eyebrow.copyWith(color: Vellum.c3),
            ),
            const SizedBox(width: 8),
            Text(
              result.rank.toString().padLeft(2, '0'),
              style: T.mono.copyWith(
                color: isTopThree ? Gilt.base : Vellum.c1,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            _TierChip(tier: result.viabilityTier),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          result.title.isNotEmpty
              ? result.title
              : 'Transplant ${result.rank}',
          style: T.displaySerif.copyWith(
            color: Vellum.c0,
            fontSize: 32,
            fontStyle: isTopThree ? FontStyle.italic : FontStyle.normal,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: T.eyebrow.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── PRIMARY FIELDS

class _PrimaryFields extends StatelessWidget {
  final RankedTransplant result;
  const _PrimaryFields({required this.result});

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      if (result.targetUser.isNotEmpty) ('TARGET USER', result.targetUser),
      if (result.adaptation.isNotEmpty) ('ADAPTATION', result.adaptation),
      if (result.mvp.isNotEmpty) ('MVP', result.mvp),
      if (result.firstDollar.isNotEmpty)
        ('FIRST DOLLAR', result.firstDollar),
    ];

    if (fields.isEmpty) {
      return Text(
        'No structured fields parsed. See raw output below.',
        style: T.bodySans.copyWith(color: Vellum.c3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          _FieldRow(eyebrow: fields[i].$1, body: fields[i].$2),
          if (i < fields.length - 1) ...[
            const SizedBox(height: 20),
            const _Hairline(),
            const SizedBox(height: 20),
          ],
        ],
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String eyebrow;
  final String body;
  const _FieldRow({required this.eyebrow, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: T.eyebrow.copyWith(color: Vellum.c2)),
        const SizedBox(height: 8),
        Text(body, style: T.bodySerif.copyWith(color: Vellum.c0)),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Line.c1);
  }
}

// ─────────────────────────────────────────────────────────── RISK FLAGS

class _RiskFlagsBlock extends StatelessWidget {
  final List<String> flags;
  const _RiskFlagsBlock({required this.flags});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Surface.c1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Tier.risk.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: Tier.risk, size: 16),
              const SizedBox(width: 8),
              Text(
                'RISK FLAGS',
                style: T.eyebrow.copyWith(color: Tier.risk),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < flags.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == flags.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Tier.risk.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      flags[i],
                      style: T.bodySerif.copyWith(
                        color: Vellum.c1,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── DEEP FIELD

class _DeepField extends StatelessWidget {
  final String eyebrow;
  final String body;
  const _DeepField({required this.eyebrow, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Surface.c2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Gilt.dim, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: T.eyebrow.copyWith(color: Gilt.light)),
          const SizedBox(height: 12),
          Text(body, style: T.bodySerif.copyWith(color: Vellum.c0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── RAW OUTPUT

class _RawOutputBlock extends StatefulWidget {
  final String raw;
  final bool initiallyExpanded;
  const _RawOutputBlock({
    required this.raw,
    this.initiallyExpanded = false,
  });

  @override
  State<_RawOutputBlock> createState() => _RawOutputBlockState();
}

class _RawOutputBlockState extends State<_RawOutputBlock> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
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
                    'RAW OUTPUT',
                    style: T.eyebrow.copyWith(color: Vellum.c3),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Vellum.c3,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SelectableText(
                widget.raw,
                style: T.mono.copyWith(color: Vellum.c1, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

