/// Static configuration for the Anthropic Messages API.
///
/// All values here are non-secret and safe to commit.  The API key itself
/// lives in .env and is accessed via EnvConfig.anthropicApiKey.
class ApiConfig {
  ApiConfig._(); // prevent instantiation

  /// Base URL for the Anthropic API (no trailing slash).
  static const String baseUrl = 'https://api.anthropic.com';

  /// Anthropic API version header value.
  static const String anthropicVersion = '2023-06-01';

  /// Stage 1 & 2 model — fast, high-quality reasoning.
  static const String modelSonnet = 'claude-sonnet-4-5';

  /// Stage 3 model — deeper synthesis quality for the stress-test pass.
  static const String modelOpus = 'claude-opus-4-5';

  /// Groq — dev fallback (all stages use same model).
  static const String groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.3-70b-versatile';

  /// Venice — beta default (all stages use same model).
  static const String veniceBaseUrl =
      'https://api.venice.ai/api/v1/chat/completions';
  static const String veniceModel = 'llama-3.3-70b';
}
