// lib/models/analysis.dart
//
// Structured output from the two-stage pipeline.

import '../core/constants.dart';

class Skeleton {
  final String theSkeleton;
  final String problemArchetype;
  final String valueMechanic;
  final String dependencies;
  final String hiddenConstraint;
  final String rawOutput;

  const Skeleton({
    required this.theSkeleton,
    required this.problemArchetype,
    required this.valueMechanic,
    required this.dependencies,
    required this.hiddenConstraint,
    required this.rawOutput,
  });

  factory Skeleton.fromRaw(String raw) {
    return Skeleton(
      theSkeleton: _section(raw, ['1. THE SKELETON'], ['2. THE PROBLEM ARCHETYPE']),
      problemArchetype: _section(
          raw, ['2. THE PROBLEM ARCHETYPE'], ['3. THE VALUE MECHANIC']),
      valueMechanic:
          _section(raw, ['3. THE VALUE MECHANIC'], ['4. THE DEPENDENCIES']),
      dependencies:
          _section(raw, ['4. THE DEPENDENCIES'], ['5. THE HIDDEN CONSTRAINT']),
      hiddenConstraint: _section(raw, ['5. THE HIDDEN CONSTRAINT'], null),
      rawOutput: raw,
    );
  }
}

/// One ranked transplant from § 02.
class RankedTransplant {
  final int rank;
  final String title;
  final ViabilityTier viabilityTier;
  final String targetUser;
  final String adaptation;
  final String mvp;
  final String firstDollar;
  final List<String> riskFlags;
  final String? currentWorkaround;
  final String? failureMode;
  final String? unfairAdvantage;
  final String rawOutput;

  const RankedTransplant({
    required this.rank,
    required this.title,
    required this.viabilityTier,
    required this.targetUser,
    required this.adaptation,
    required this.mvp,
    required this.firstDollar,
    required this.riskFlags,
    this.currentWorkaround,
    this.failureMode,
    this.unfairAdvantage,
    required this.rawOutput,
  });

  bool get hasStructuredFields =>
      targetUser.isNotEmpty ||
      adaptation.isNotEmpty ||
      mvp.isNotEmpty ||
      firstDollar.isNotEmpty;

  /// Plain-text export for clipboard / share.
  String toClipboardText() {
    final buf = StringBuffer();
    buf.writeln(
      '${rank.toString().padLeft(2, '0')} — ${title.isNotEmpty ? title : 'Transplant $rank'}',
    );
    buf.writeln('Viability tier: ${_tierLabel(viabilityTier)}');
    if (targetUser.isNotEmpty) buf.writeln('\nTarget user:\n$targetUser');
    if (adaptation.isNotEmpty) buf.writeln('\nAdaptation:\n$adaptation');
    if (mvp.isNotEmpty) buf.writeln('\nMVP:\n$mvp');
    if (firstDollar.isNotEmpty) buf.writeln('\nFirst dollar:\n$firstDollar');
    if (riskFlags.isNotEmpty) {
      buf.writeln('\nRisk flags:');
      for (final flag in riskFlags) {
        buf.writeln('• $flag');
      }
    }
    if (currentWorkaround != null && currentWorkaround!.isNotEmpty) {
      buf.writeln('\nCurrent workaround:\n$currentWorkaround');
    }
    if (failureMode != null && failureMode!.isNotEmpty) {
      buf.writeln('\nFailure mode:\n$failureMode');
    }
    if (unfairAdvantage != null && unfairAdvantage!.isNotEmpty) {
      buf.writeln('\nUnfair advantage:\n$unfairAdvantage');
    }
    if (!hasStructuredFields && rawOutput.trim().isNotEmpty) {
      buf.writeln('\n---\n$rawOutput');
    }
    return buf.toString().trim();
  }
}

/// Cross-domain bonus transplant from § 03.
class BonusTransplant {
  final int rank;
  final String title;
  final String domain;
  final String targetUser;
  final String rationale;
  final String rawOutput;

  const BonusTransplant({
    required this.rank,
    required this.title,
    required this.domain,
    required this.targetUser,
    required this.rationale,
    required this.rawOutput,
  });
}

enum ViabilityTier { strong, viable, weak, highRisk, unknown }

class Analysis {
  final String idea;
  final String? domainLock;
  final Skeleton skeleton;
  final List<RankedTransplant> rankedTransplants;
  final List<BonusTransplant> bonusTransplants;
  final String skeletonRaw;
  final String transplantsRaw;

  const Analysis({
    required this.idea,
    this.domainLock,
    required this.skeleton,
    required this.rankedTransplants,
    required this.bonusTransplants,
    required this.skeletonRaw,
    required this.transplantsRaw,
  });

  factory Analysis.parse({
    required String idea,
    String? domainLock,
    required String skeletonRaw,
    required String transplantsRaw,
  }) {
    final refinedSkeleton = _section(
      transplantsRaw,
      ['§ 01 — THE REFINED SKELETON', '01 — THE REFINED SKELETON'],
      ['§ 02 — ALL TRANSPLANTS RANKED', '02 — ALL TRANSPLANTS RANKED', 'ALL TRANSPLANTS RANKED'],
    );

    return Analysis(
      idea: idea,
      domainLock: domainLock,
      skeleton: refinedSkeleton.isNotEmpty
          ? Skeleton.fromRaw(refinedSkeleton)
          : Skeleton.fromRaw(skeletonRaw),
      rankedTransplants: _parseRankedTransplants(transplantsRaw),
      bonusTransplants: _parseBonusTransplants(transplantsRaw),
      skeletonRaw: skeletonRaw,
      transplantsRaw: transplantsRaw,
    );
  }
}

String _section(
  String raw,
  List<String> startHeadings,
  List<String>? endHeadings,
) {
  final start = _indexOfHeading(raw, startHeadings);
  if (start == -1) return '';
  final matchedStart = _matchedHeading(raw, startHeadings, start)!;
  final contentStart = start + matchedStart.length;
  if (endHeadings == null || endHeadings.isEmpty) {
    return raw.substring(contentStart).trim();
  }
  final end = _indexOfHeading(raw, endHeadings, contentStart);
  if (end == -1) return raw.substring(contentStart).trim();
  return raw.substring(contentStart, end).trim();
}

int _indexOfHeading(String raw, List<String> headings, [int start = 0]) {
  final lower = raw.toLowerCase();
  var best = -1;
  for (final heading in headings) {
    final idx = lower.indexOf(heading.toLowerCase(), start);
    if (idx != -1 && (best == -1 || idx < best)) best = idx;
  }
  return best;
}

String? _matchedHeading(String raw, List<String> headings, int index) {
  for (final heading in headings) {
    if (index + heading.length > raw.length) continue;
    if (raw.substring(index, index + heading.length).toLowerCase() ==
        heading.toLowerCase()) {
      return heading;
    }
  }
  return null;
}

String _field(String block, String fieldName) {
  final escaped = RegExp.escape(fieldName);

  // Inline: "Field: value" on one line (common Venice / Llama output).
  final linePattern = RegExp(
    '^$escaped\\s*:\\s*(.*)\$',
    caseSensitive: false,
    multiLine: true,
  );
  final lineMatch = linePattern.firstMatch(block);
  if (lineMatch != null) {
    final value = lineMatch.group(1)!.trim();
    if (value.isNotEmpty) return value;
  }

  // Multiline: "Field:\nvalue"
  final multiPattern = RegExp(
    '$escaped\\s*:\\s*\\n([\\s\\S]+?)(?=\\n[A-Za-z][^\\n]*:|\\n\\d{2}\\s*[—–-]|\\Z)',
    caseSensitive: false,
  );
  return multiPattern.firstMatch(block)?.group(1)?.trim() ?? '';
}

String _tierLabel(ViabilityTier tier) => switch (tier) {
      ViabilityTier.strong => 'Strong',
      ViabilityTier.viable => 'Viable',
      ViabilityTier.weak => 'Weak',
      ViabilityTier.highRisk => 'High Risk',
      ViabilityTier.unknown => 'Unknown',
    };

String? _fieldOrNull(String block, String fieldName) {
  final value = _field(block, fieldName);
  return value.isEmpty ? null : value;
}

List<RankedTransplant> _parseRankedTransplants(String raw) {
  final rankedSection = _section(
    raw,
    ['§ 02 — ALL TRANSPLANTS RANKED', '02 — ALL TRANSPLANTS RANKED', 'ALL TRANSPLANTS RANKED'],
    ['§ 03 — BONUS TRANSPLANTS', '03 — BONUS TRANSPLANTS', 'BONUS TRANSPLANTS'],
  );

  final entryPattern = RegExp(
    r'(?:^|\n)\s*(\d{1,2})\s*[—–\-:]\s*(.+?)\s*(?=\n|$)',
  );
  final matches = entryPattern.allMatches(rankedSection).toList();
  final sections = rankedSection.split(entryPattern);

  final results = <RankedTransplant>[];

  for (var i = 0; i < matches.length && results.length < 10; i++) {
    final rank = int.tryParse(matches[i].group(1) ?? '') ?? (i + 1);
    var title = matches[i].group(2)!.trim();
    if (_looksLikeLensTitle(title)) continue;
    final block = i + 1 < sections.length ? sections[i + 1] : '';

    final tierMatch = RegExp(
      r'Viability tier[:\s]*(Strong|Viable|Weak|High Risk)',
      caseSensitive: false,
    ).firstMatch(block);
    final tierStr = tierMatch?.group(1)?.toLowerCase() ?? '';
    final tier = switch (tierStr) {
      'strong' => ViabilityTier.strong,
      'viable' => ViabilityTier.viable,
      'weak' => ViabilityTier.weak,
      'high risk' => ViabilityTier.highRisk,
      _ => ViabilityTier.unknown,
    };

    final riskSection = _field(block, 'Risk flags');
    final riskFlags = riskSection
        .split(RegExp(r'[\n;]+'))
        .map((l) => l.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    results.add(RankedTransplant(
      rank: rank,
      title: title,
      viabilityTier: tier,
      targetUser: _field(block, 'Target user'),
      adaptation: _field(block, 'Adaptation'),
      mvp: _field(block, 'MVP'),
      firstDollar: _field(block, 'First dollar'),
      riskFlags: riskFlags,
      currentWorkaround: _fieldOrNull(block, 'Current workaround'),
      failureMode: _fieldOrNull(block, 'Failure mode'),
      unfairAdvantage: _fieldOrNull(block, 'Unfair advantage'),
      rawOutput: block.trim(),
    ));
  }

  while (results.length < AppConstants.rankedTransplantCount) {
    results.add(RankedTransplant(
      rank: results.length + 1,
      title: '',
      viabilityTier: ViabilityTier.unknown,
      targetUser: '',
      adaptation: '',
      mvp: '',
      firstDollar: '',
      riskFlags: const [],
      rawOutput: '',
    ));
  }

  return results;
}

List<BonusTransplant> _parseBonusTransplants(String raw) {
  final bonusSection = _section(
    raw,
    ['§ 03 — BONUS TRANSPLANTS', '03 — BONUS TRANSPLANTS', 'BONUS TRANSPLANTS'],
    null,
  );

  final entryPattern = RegExp(
    r'(?:^|\n)\s*(\d{1,2})\s*[—–\-:]\s*(.+?)\s*(?=\n|$)',
  );
  final matches = entryPattern.allMatches(bonusSection).toList();
  final sections = bonusSection.split(entryPattern);

  final results = <BonusTransplant>[];

  for (var i = 0; i < matches.length && results.length < 5; i++) {
    final rank = int.tryParse(matches[i].group(1) ?? '') ?? (i + 1);
    var title = matches[i].group(2)!.trim();
    if (_looksLikeLensTitle(title)) continue;
    final block = i + 1 < sections.length ? sections[i + 1] : '';

    results.add(BonusTransplant(
      rank: rank,
      title: title,
      domain: _field(block, 'Domain'),
      targetUser: _field(block, 'Target user'),
      rationale: _field(block, 'Why viable'),
      rawOutput: block.trim(),
    ));
  }

  return results;
}

bool _looksLikeLensTitle(String title) {
  final lower = title.toLowerCase();
  return lower.contains(' lens') ||
      lower.endsWith(' lens') ||
      RegExp(r'\b(apple|tesla|openai|google|netflix|stripe|amazon)\b')
          .hasMatch(lower);
}
