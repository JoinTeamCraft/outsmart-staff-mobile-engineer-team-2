import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/service_locator.dart';
import '../../features/lessons/data/lesson_repository.dart';
import '../../features/lessons/presentation/cubit/lesson_cubit.dart';
import '../../features/quiz/data/quiz_repository.dart';
import '../../features/quiz/presentation/cubit/quiz_cubit.dart';
import '../../features/streaks/presentation/cubit/streak_cubit.dart';

/// All app-wide Cubit providers in one place. Add new cubits here as
/// tracks land (OU-11 lesson detail, OU-12 quiz flow, etc.) — app.dart
/// itself should never need to change when a new cubit is added.
class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LessonCubit(locator<LessonRepository>())..loadLessons(),
        ),
        BlocProvider(create: (_) => QuizCubit(locator<QuizRepository>())),
        BlocProvider(create: (_) => StreakCubit()),
      ],
      child: child,
    );
  }
}