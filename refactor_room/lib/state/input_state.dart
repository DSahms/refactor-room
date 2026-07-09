// lib/state/input_state.dart
//
// Holds everything the Input screen needs to read and mutate:
//   - The idea draft (typed or transcribed)
//   - Mic status (idle / listening / error)
//   - Domain Lock toggle + value
//
// Exposed as a Riverpod AsyncNotifier so the screen can watch it
// reactively without any setState calls.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────── MIC STATUS

enum MicStatus { idle, listening, error }

// ─────────────────────────────────────────────────────────── STATE

class InputState {
  final String draft;
  final String? sourceFileName;
  final MicStatus mic;
  final String? micError;
  final bool domainLockEnabled;
  final String domainLockValue;

  const InputState({
    this.draft = '',
    this.sourceFileName,
    this.mic = MicStatus.idle,
    this.micError,
    this.domainLockEnabled = false,
    this.domainLockValue = '',
  });

  /// True when there is enough text to kick off the pipeline.
  bool get canRunAnalysis => draft.trim().length >= 10;

  bool get hasImportedFile =>
      sourceFileName != null && sourceFileName!.trim().isNotEmpty;

  /// Returns the domain lock string if the toggle is on and the field
  /// has content, otherwise null (Pipeline treats null as "no lock").
  String? get effectiveDomainLock =>
      domainLockEnabled && domainLockValue.trim().isNotEmpty
          ? domainLockValue.trim()
          : null;

  InputState copyWith({
    String? draft,
    String? sourceFileName,
    bool clearSourceFile = false,
    MicStatus? mic,
    String? micError,
    bool clearMicError = false,
    bool? domainLockEnabled,
    String? domainLockValue,
  }) {
    return InputState(
      draft: draft ?? this.draft,
      sourceFileName:
          clearSourceFile ? null : (sourceFileName ?? this.sourceFileName),
      mic: mic ?? this.mic,
      micError: clearMicError ? null : (micError ?? this.micError),
      domainLockEnabled: domainLockEnabled ?? this.domainLockEnabled,
      domainLockValue: domainLockValue ?? this.domainLockValue,
    );
  }
}

// ─────────────────────────────────────────────────────────── NOTIFIER

class InputNotifier extends Notifier<InputState> {
  @override
  InputState build() => const InputState();

  void setDraft(String value) {
    state = state.copyWith(
      draft: value,
      clearMicError: true,
      clearSourceFile: true,
    );
  }

  void setFromImportedFile({
    required String content,
    required String fileName,
  }) {
    state = state.copyWith(
      draft: content,
      sourceFileName: fileName,
      clearMicError: true,
    );
  }

  void clearImportedFile() {
    state = state.copyWith(clearSourceFile: true);
  }

  /// Called by speech_to_text on each partial/final result.
  /// Replaces the draft with the full recognised phrase (STT returns
  /// the cumulative transcript, not a delta).
  void appendTranscript(String words) {
    state = state.copyWith(draft: words);
  }

  void setMicStatus(MicStatus status, {String? error}) {
    state = state.copyWith(
      mic: status,
      micError: error,
      clearMicError: error == null,
    );
  }

  void toggleDomainLock(bool enabled) {
    state = state.copyWith(domainLockEnabled: enabled);
  }

  void setDomainLockValue(String value) {
    state = state.copyWith(domainLockValue: value);
  }

  /// Called after a successful pipeline start to reset the screen for
  /// the next run (preserves domain lock settings).
  void reset() {
    state = InputState(
      domainLockEnabled: state.domainLockEnabled,
      domainLockValue: state.domainLockValue,
    );
  }
}

// ─────────────────────────────────────────────────────────── PROVIDER

final inputProvider = NotifierProvider<InputNotifier, InputState>(
  InputNotifier.new,
);
