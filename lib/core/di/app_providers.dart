import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/service_locator.dart';
import '../../features/lessons/data/lesson_repository.dart';
import '../../features/lessons/presentation/cubit/lesson_cubit.dart';
import '../../features/quiz/data/quiz_repository.dart';
import '../../features/quiz/presentation/cubit/quiz_cubit.dart';
import '../../features/quiz/presentation/cubit/quiz_completion_cubit.dart';
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
          create: (_) =>
              LessonCubit(locator<LessonRepository>())..loadLessons(),
        ),
        BlocProvider(create: (_) => QuizCubit(locator<QuizRepository>())),
        // OU-13: emits QuizResult on quiz completion for other tracks to
        // subscribe to. `lazy: false` so it is alive from startup and never
        // misses a completion, even before a consumer (OU-14/OU-16/OU-18)
        // mounts. Reads the QuizCubit provided above.
        BlocProvider(
          lazy: false,
          create: (context) => QuizCompletionCubit(context.read<QuizCubit>()),
        ),
        BlocProvider(create: (_) => StreakCubit()),
      ],
      child: child,
    );
  }
}
