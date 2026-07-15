import 'package:flutter/material.dart';
import 'package:streaklearn/core/di/app_providers.dart';
import 'package:streaklearn/shared/widgets/state_demo_widget.dart';
import 'core/theme/app_theme.dart';

class StreakLearnApp extends StatelessWidget {
  const StreakLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Why AppProviders widget needed here?
    // It wraps the app in all cubit providers (Lesson/Quiz/Streak) needed
    // app-wide. Pulled out into AppProviders (core/di/app_providers.dart)
    // instead of inlined here, so this file only describes the app shell
    // (theme, routes) — new cubits get added there, not here, keeping
    // this file stable as more tracks land.
    return AppProviders(
      child: MaterialApp(
        title: 'StreakLearn',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreenPlaceholder(),
        },
      ),
    );
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreakLearn')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Welcome to StreakLearn Hackathon!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tracks B, C, and D will replace this screen with the Lesson Feed, Lesson Detail/Quiz, and Streak Animation system.',
                textAlign: TextAlign.center,
              ),
            ),
            StateDemoWidget(),
          ],
        ),
      ),
    );
  }
}