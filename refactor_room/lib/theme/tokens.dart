// lib/theme/tokens.dart
//
// Single source of truth for every colour, type scale, and spacing
// constant used in the UI. Nothing in the widget tree should reach
// for a raw Color literal or a hard-coded TextStyle — it comes from
// here.
//
// Palette naming follows the design system PDF:
//   Vellum  — warm off-white text hierarchy (c0 = primary, c3 = ghost)
//   Gilt    — gold accent (CTA, focus ring, active states)
//   Ink     — dark background surfaces
//   Line    — border / divider tones
//   Tier    — viability tier colours (strong → high-risk)

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────── PALETTE

abstract final class Vellum {
  static const c0 = Color(0xFFF5F0E8); // primary text
  static const c1 = Color(0xFFD9D0BC); // secondary text
  static const c2 = Color(0xFFADA494); // tertiary / eyebrow
  static const c3 = Color(0xFF6B6358); // ghost / caption
}

abstract final class Gilt {
  static const base = Color(0xFFB8962E); // gold CTA / focus ring
  static const light = Color(0xFFD4AF5A); // hover / highlight
  static const dim = Color(0xFF7A6420); // pressed / shadow tint
}

// Surface colours (named Ink in the design system PDF, but renamed here
// to avoid collision with Flutter's built-in Ink widget).
abstract final class Surface {
  static const c0 = Color(0xFF0E0D0B); // deepest background
  static const c1 = Color(0xFF1A1814); // card surface
  static const c2 = Color(0xFF252219); // elevated card
  static const c3 = Color(0xFF302D23); // hover surface
}

abstract final class Line {
  static const c0 = Color(0xFF3D3A30); // strong border
  static const c1 = Color(0xFF2A2820); // default border
  static const c2 = Color(0xFF1E1C15); // subtle divider
}

abstract final class Tier {
  static const strong = Color(0xFF4CAF82); // green — Strong
  static const viable = Color(0xFF8BC4E8); // blue — Viable
  static const weak = Color(0xFFD4A84B); // amber — Weak
  static const risk = Color(0xFFE07070); // red — High Risk
  static const unknown = Color(0xFF6B6358); // grey — Unknown
}

// Convenience alias used in the input screen.
abstract final class C {
  static const bg = Surface.c0;
}

// ─────────────────────────────────────────────────────────── TYPE SCALE

abstract final class T {
  // Brand mark
  static const brandSans = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );
  static const brandSerif = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
  );

  // Display
  static const displaySerif = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.5,
  );

  // Headline (stage titles on the processing screen)
  static const headlineSerif = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // Eyebrow (all-caps label above headings)
  static const eyebrow = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.5,
  );

  // Body
  static const bodySerif = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const bodySans = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Mono (domain lock field, raw output)
  static const mono = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
  );

  // Caption
  static const caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  // Button
  static const button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  // Stage label (processing screen hairlines)
  static const stageLabel = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
  );
}
