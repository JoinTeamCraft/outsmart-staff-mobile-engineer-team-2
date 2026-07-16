import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streaklearn/features/streaks/presentation/cubit/streak_cubit.dart';
import 'package:streaklearn/features/streaks/presentation/cubit/streak_state.dart';

void main() {
  group('StreakCubit', () {
    blocTest<StreakCubit, StreakState>(
      'emits incremented streak and pending celebration',
      build: () => StreakCubit(),
      act: (cubit) => cubit.incrementStreak(),
      expect: () => [
        const StreakState(
          currentStreak: 1,
          longestStreak: 1,
          celebrationPending: true,
        ),
      ],
    );

    blocTest<StreakCubit, StreakState>(
      'updates longest streak when current streak exceeds it',
      build: () => StreakCubit(),
      seed: () => const StreakState(
        currentStreak: 5,
        longestStreak: 5,
      ),
      act: (cubit) => cubit.incrementStreak(),
      expect: () => [
        const StreakState(
          currentStreak: 6,
          longestStreak: 6,
          celebrationPending: true,
        ),
      ],
    );

    blocTest<StreakCubit, StreakState>(
      'does not reduce longest streak when current streak resets',
      build: () => StreakCubit(),
      seed: () => const StreakState(
        currentStreak: 5,
        longestStreak: 5,
      ),
      act: (cubit) => cubit.resetStreak(),
      expect: () => [
        const StreakState(
          currentStreak: 0,
          longestStreak: 5,
          celebrationPending: false,
        ),
      ],
    );

    blocTest<StreakCubit, StreakState>(
      'clears celebration pending after acknowledging celebration',
      build: () => StreakCubit(),
      seed: () => const StreakState(
        currentStreak: 1,
        longestStreak: 1,
        celebrationPending: true,
      ),
      act: (cubit) => cubit.acknowledgeCelebration(),
      expect: () => [
        const StreakState(
          currentStreak: 1,
          longestStreak: 1,
          celebrationPending: false,
        ),
      ],
    );

    blocTest<StreakCubit, StreakState>(
      'does nothing when acknowledging an already consumed celebration',
      build: () => StreakCubit(),
      act: (cubit) => cubit.acknowledgeCelebration(),
      expect: () => [],
    );
  });
}
