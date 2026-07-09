// lib/widgets/mic_button.dart
//
// Mic affordance for the Input card. Three visual states driven by
// MicStatus (from input_state.dart):
//   idle      — gilt-filled circle, mic icon. Resting.
//   listening — gilt fill + ambient gilt halo, pulsing. Hot.
//   error     — muted/outline, mic-off icon. Tap to retry.
//
// Contract (called from input_screen.dart line ~338):
//   MicButton(status: micStatus, onTap: onMicTap)

import 'package:flutter/material.dart';

import '../state/input_state.dart';
import '../theme/tokens.dart';

class MicButton extends StatelessWidget {
  final MicStatus status;
  final VoidCallback onTap;

  const MicButton({super.key, required this.status, required this.onTap});

  bool get _listening => status == MicStatus.listening;
  bool get _error => status == MicStatus.error;

  @override
  Widget build(BuildContext context) {
    final Color fill = _error ? Surface.c2 : Gilt.base;
    final Color icon = _error ? Tier.risk : Surface.c0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: _error ? Border.all(color: Tier.risk, width: 1) : null,
          boxShadow: _listening
              ? [
                  BoxShadow(
                    color: Gilt.base.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(_error ? Icons.mic_off : Icons.mic, color: icon, size: 20),
      ),
    );
  }
}
