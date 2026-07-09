/// App-wide constants that are not secrets and are safe to commit.
class AppConstants {
  AppConstants._();

  static const String claudeSonnetModel = 'claude-sonnet-4-5';
  static const String claudeOpusModel = 'claude-opus-4-5';

  static const String claudeApiUrl =
      'https://api.anthropic.com/v1/messages';

  static const int rankedTransplantCount = 10;
  static const int bonusTransplantCount = 5;

  static const int maxTokens = 4096;

  /// Upper bound for typed or imported idea text (API + UI sanity).
  static const int maxIdeaChars = 30000;

  /// Keep in sync with pubspec version — shown on home screen so installs
  /// are easy to verify (transplants build, not legacy lenses build).
  static const String appVersionLabel = 'v1.1.0 · transplants';
}
