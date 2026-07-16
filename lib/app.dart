import 'package:flutter/material.dart';
import 'package:streaklearn/core/di/app_providers.dart';
import 'package:streaklearn/shared/widgets/state_demo_widget.dart';
import 'core/theme/app_theme.dart';
import 'features/lessons/presentation/screens/lesson_feed_screen.dart';

class StreakLearnApp extends StatelessWidget {
  const StreakLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'StreakLearn',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LessonFeedScreen(),
        },
      ),
    );
  }
}
