import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LlmBackend { venice, groq, anthropic }

class EnvConfig {
  EnvConfig._();

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
    if (fromEnv.isEmpty || fromEnv == 'your_groq_key_here') {
      throw StateError(
        'GROQ_API_KEY is not set. Copy .env.example to .env and add your key.',
      );
    }
    return fromEnv;
  }

  static String get veniceApiKey {
    final fromEnv = dotenv.env['VENICE_API_KEY']?.trim() ?? '';
    if (fromEnv.isEmpty || fromEnv == 'your_venice_key_here') {
      throw StateError(
        'VENICE_API_KEY is not set. Copy .env.example to .env and add your key.',
      );
    }
    return fromEnv;
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
