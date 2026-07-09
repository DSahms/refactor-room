import 'package:flutter/material.dart';

import 'screens/input_screen.dart';
import 'theme/tokens.dart';

/// Root of the widget tree. Keeps theme and routing in one place so
/// swapping themes or adding named routes later is a one-file change.
class RefactorRoomApp extends StatelessWidget {
  const RefactorRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Refactor Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Gilt.base,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Surface.c0,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const InputScreen(),
    );
  }
}
