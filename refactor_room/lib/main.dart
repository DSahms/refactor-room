import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point.  We load .env before runApp so every part of the app
/// (including non-widget service code) can read the API key synchronously
/// via dotenv.env['ANTHROPIC_API_KEY'].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // flutter_dotenv reads the asset declared in pubspec.yaml.
  await dotenv.load(fileName: '.env');

  runApp(
    // ProviderScope is the Riverpod root — all providers live inside it.
    const ProviderScope(
      child: RefactorRoomApp(),
    ),
  );
}
