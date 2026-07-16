import 'package:flutter/material.dart';
import 'package:streaklearn/core/di/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/lessons/presentation/screens/lesson_feed_screen.dart';
import 'shared/widgets/celebration_overlay.dart';

class StreakLearnApp extends StatelessWidget {
  const StreakLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'StreakLearn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // OU-17: the celebration overlay sits above every route so a quiz
        // completion animates regardless of which screen is showing.
        builder: (context, child) =>
            CelebrationOverlay(child: child ?? const SizedBox.shrink()),
        initialRoute: '/',
        routes: {
          '/': (context) => const LessonFeedScreen(),
        },
      ),
    );
  }
}
