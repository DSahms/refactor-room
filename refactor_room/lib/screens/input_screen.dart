// lib/screens/input_screen.dart
//
// Screen 01 — Capture. The user meets the app mid-thought. One field,
// mic-first, type fallback. Domain Lock optionally constrains the
// analysis to a single industry.
//
// Layout follows the design system PDF Screen 01 exactly:
//   - Brand mark + section eyebrow
//   - Editorial serif prompt ("What are you working on?")
//   - Input card with gilt focus ring when active, mic button inset
//     bottom-right, char counter caption
//   - Domain Lock card (toggle + monospace value field when on)
//   - Gilt CTA + "TWO STAGES · ~45 SECONDS" caption

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/constants.dart';
import '../services/markdown_import.dart';
import '../state/input_state.dart';
import '../state/pipeline_state.dart';
import '../theme/tokens.dart';
import '../widgets/domain_lock_card.dart';
import '../widgets/mic_button.dart';
import 'processing_screen.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(inputProvider).draft;
    _textController = TextEditingController(text: initial);
    _focusNode = FocusNode();
    _initSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        // 'listening' → 'notListening' → 'done' is the iOS lifecycle.
        if (status == 'notListening' || status == 'done') {
          if (mounted) {
            ref
                .read(inputProvider.notifier)
                .setMicStatus(MicStatus.idle);
          }
        }
      },
      onError: (err) {
        if (mounted) {
          ref.read(inputProvider.notifier).setMicStatus(
                MicStatus.error,
                error: 'Mic unavailable. Type your idea instead.',
              );
        }
      },
    );
    if (mounted) {
      setState(() => _speechReady = available);
    }
  }

  Future<void> _toggleMic() async {
    final currentStatus = ref.read(inputProvider).mic;

    if (currentStatus == MicStatus.listening) {
      await _speech.stop();
      ref.read(inputProvider.notifier).setMicStatus(MicStatus.idle);
      return;
    }

    if (!_speechReady) {
      ref.read(inputProvider.notifier).setMicStatus(
            MicStatus.error,
            error: 'Mic permission not granted. Tap to enable in Settings.',
          );
      return;
    }

    ref.read(inputProvider.notifier).setMicStatus(MicStatus.listening);
    await _speech.listen(
      onResult: (result) {
        // speech_to_text returns the full recognized phrase each tick.
        // We feed it to the state, which replaces the draft, and we
        // also update the controller so the field reflects it visually.
        ref
            .read(inputProvider.notifier)
            .appendTranscript(result.recognizedWords);
        _textController.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _importMarkdown() async {
    _focusNode.unfocus();
    if (ref.read(inputProvider).mic == MicStatus.listening) {
      await _speech.stop();
      ref.read(inputProvider.notifier).setMicStatus(MicStatus.idle);
    }

    try {
      final imported = await MarkdownImport.pickAndRead();
      if (!mounted || imported == null) return;

      ref.read(inputProvider.notifier).setFromImportedFile(
            content: imported.content,
            fileName: imported.fileName,
          );
      _textController.value = TextEditingValue(
        text: imported.content,
        selection: TextSelection.collapsed(offset: imported.content.length),
      );
    } on MarkdownImportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that file.')),
      );
    }
  }

  void _runAnalysis() {
    final input = ref.read(inputProvider);
    if (!input.canRunAnalysis) return;

    // Stop the mic if it's still hot.
    if (input.mic == MicStatus.listening) {
      _speech.stop();
    }

    _focusNode.unfocus();

    ref.read(pipelineRunProvider.notifier).start(
          idea: input.draft.trim(),
          domainLock: input.effectiveDomainLock,
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProcessingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(inputProvider);

    // Keep the controller in sync if state changed externally (e.g.,
    // mic transcript). We only push if values differ to avoid cursor
    // jumps while the user is typing.
    if (_textController.text != input.draft) {
      _textController.value = TextEditingValue(
        text: input.draft,
        selection: TextSelection.collapsed(offset: input.draft.length),
      );
    }

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandMark(),
              const SizedBox(height: 48),
              Text(
                'NEW ANALYSIS',
                style: T.eyebrow.copyWith(color: Vellum.c2),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: T.displaySerif.copyWith(color: Vellum.c0),
                  children: [
                    const TextSpan(text: 'What are you\n'),
                    TextSpan(
                      text: 'working on?',
                      style: T.displaySerif.copyWith(
                        color: Vellum.c0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _InputCard(
                controller: _textController,
                focusNode: _focusNode,
                micStatus: input.mic,
                onMicTap: _toggleMic,
                onTextChanged: (v) =>
                    ref.read(inputProvider.notifier).setDraft(v),
                charCount: input.draft.length,
                errorMessage: input.micError,
                sourceFileName: input.sourceFileName,
                onClearImport: () {
                  ref.read(inputProvider.notifier).clearImportedFile();
                },
              ),
              const SizedBox(height: 12),
              _ImportMarkdownButton(onTap: _importMarkdown),
              const SizedBox(height: 16),
              DomainLockCard(
                enabled: input.domainLockEnabled,
                value: input.domainLockValue,
                onToggle: (v) =>
                    ref.read(inputProvider.notifier).toggleDomainLock(v),
                onValueChanged: (v) => ref
                    .read(inputProvider.notifier)
                    .setDomainLockValue(v),
              ),
              const SizedBox(height: 32),
              _RunAnalysisButton(
                enabled: input.canRunAnalysis,
                onTap: _runAnalysis,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'TWO STAGES  ·  ~45 SECONDS',
                  style: T.caption.copyWith(color: Vellum.c3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── BRAND MARK

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Vellum.c1, width: 1),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Vellum.c1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('The Refactor ', style: T.brandSans.copyWith(color: Vellum.c0)),
        Text(
          'Room',
          style: T.brandSerif.copyWith(
            color: Vellum.c0,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Text(
          AppConstants.appVersionLabel,
          style: T.mono.copyWith(color: Vellum.c3, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── INPUT CARD

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final MicStatus micStatus;
  final VoidCallback onMicTap;
  final ValueChanged<String> onTextChanged;
  final int charCount;
  final String? errorMessage;
  final String? sourceFileName;
  final VoidCallback onClearImport;

  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.micStatus,
    required this.onMicTap,
    required this.onTextChanged,
    required this.charCount,
    required this.errorMessage,
    required this.sourceFileName,
    required this.onClearImport,
  });

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Surface.c1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus ? Gilt.base : Line.c1,
          width: hasFocus ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onTextChanged,
            maxLines: null,
            minLines: 3,
            cursorColor: Gilt.base,
            style: T.bodySerif.copyWith(color: Vellum.c0),
            decoration: InputDecoration(
              hintText: 'A marketplace for second-hand industrial '
                  'machinery in emerging markets.',
              hintStyle: T.bodySerif.copyWith(color: Vellum.c3),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          if (sourceFileName != null && sourceFileName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImportedFileChip(
              fileName: sourceFileName!,
              onClear: onClearImport,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  errorMessage ??
                      (sourceFileName != null
                          ? '$charCount chars  ·  imported from file'
                          : '$charCount chars  ·  raw input'),
                  style: T.caption.copyWith(
                    color: errorMessage != null ? Tier.risk : Vellum.c3,
                  ),
                ),
              ),
              MicButton(status: micStatus, onTap: onMicTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportedFileChip extends StatelessWidget {
  final String fileName;
  final VoidCallback onClear;

  const _ImportedFileChip({
    required this.fileName,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Surface.c2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Gilt.dim, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: Gilt.base, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.mono.copyWith(color: Vellum.c1, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'CLEAR',
              style: T.eyebrow.copyWith(color: Vellum.c3, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportMarkdownButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportMarkdownButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Surface.c1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Line.c1, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Gilt.base, size: 18),
            const SizedBox(width: 10),
            Text(
              'Import markdown or text file',
              style: T.bodySans.copyWith(color: Vellum.c1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── CTA

class _RunAnalysisButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _RunAnalysisButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
          color: Gilt.base,
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Gilt.base.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Run Analysis',
                  style: T.button.copyWith(color: Surface.c0),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Surface.c0, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
