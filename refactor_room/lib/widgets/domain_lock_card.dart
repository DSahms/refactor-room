// lib/widgets/domain_lock_card.dart
//
// The Domain Lock card on the Input screen. When the toggle is off it
// shows a single row with a label and the switch. When on, a monospace
// text field expands below for the industry value.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class DomainLockCard extends StatefulWidget {
  final bool enabled;
  final String value;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onValueChanged;

  const DomainLockCard({
    super.key,
    required this.enabled,
    required this.value,
    required this.onToggle,
    required this.onValueChanged,
  });

  @override
  State<DomainLockCard> createState() => _DomainLockCardState();
}

class _DomainLockCardState extends State<DomainLockCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(DomainLockCard old) {
    super.didUpdateWidget(old);
    // Sync controller if value changed externally (e.g., state restore).
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
    // Auto-focus the field when the toggle is turned on.
    if (widget.enabled && !old.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Surface.c1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.enabled ? Gilt.base.withValues(alpha: 0.5) : Line.c1,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOMAIN LOCK',
                      style: T.eyebrow.copyWith(color: Vellum.c2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.enabled
                          ? 'All ten ranked transplants stay within this industry.'
                          : 'Constrain ranked transplants to one industry.',
                      style: T.caption.copyWith(color: Vellum.c3),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.enabled,
                onChanged: widget.onToggle,
                activeThumbColor: Gilt.base,
                activeTrackColor: Gilt.dim,
                inactiveThumbColor: Vellum.c3,
                inactiveTrackColor: Line.c0,
              ),
            ],
          ),
          // ── Value field (animated expand) ───────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: widget.enabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onValueChanged,
                style: T.mono.copyWith(color: Vellum.c0),
                cursorColor: Gilt.base,
                decoration: InputDecoration(
                  hintText: 'e.g. healthcare',
                  hintStyle: T.mono.copyWith(color: Vellum.c3),
                  filled: true,
                  fillColor: Surface.c2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Gilt.base, width: 1.5),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
