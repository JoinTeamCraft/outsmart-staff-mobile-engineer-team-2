import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/streaks/presentation/cubit/streak_cubit.dart';
import '../../features/streaks/presentation/cubit/streak_state.dart';

/// Minimal proof-of-life widget for OU-2's acceptance criteria:
/// tapping the button mutates StreakCubit state and the UI reflects
/// it immediately via BlocBuilder — no other track's code required.
class StateDemoWidget extends StatelessWidget {
  const StateDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'State Management Demo (OU-2)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BlocBuilder<StreakCubit, StreakState>(
              builder: (context, state) {
                return Text(
                  'Current streak: ${state.currentStreak}',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<StreakCubit>().incrementStreak(),
              child: const Text('Increment Streak'),
            ),
          ],
        ),
      ),
    );
  }
}
