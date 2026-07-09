import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LlmBackend { venice, groq, anthropic }

class EnvConfig {
  EnvConfig._();

  static const String _bakedGroqKey =
      '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';
  static const String _bakedVeniceKey =
      'VENICE_INFERENCE_KEY_s18F9xz30SiCVQWRwvv97SAQzQtxioROmRrlWWIsIP';

  /// Beta builds default to Venice. Set LLM_BACKEND=groq or anthropic to swap.
  static LlmBackend get backend {
    final raw = dotenv.env['LLM_BACKEND']?.trim().toLowerCase();
    switch (raw) {
      case 'groq':
        return LlmBackend.groq;
      case 'anthropic':
        return LlmBackend.anthropic;
      default:
        return LlmBackend.venice;
    }
  }

  static String get groqApiKey {
    final fromEnv = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
    if (fromEnv.isNotEmpty && fromEnv != 'your_groq_key_here') {
      return fromEnv;
    }
    return _bakedGroqKey;
  }

  static String get veniceApiKey {
    final fromEnv = dotenv.env['VENICE_API_KEY']?.trim() ?? '';
    if (fromEnv.isNotEmpty && fromEnv != 'your_venice_key_here') {
      return fromEnv;
    }
    return _bakedVeniceKey;
  }

  static String get anthropicApiKey {
    final key = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your_api_key_here') {
      throw StateError(
        'ANTHROPIC_API_KEY is not set. Edit .env or use LLM_BACKEND=venice.',
      );
    }
    return key;
  }
}
