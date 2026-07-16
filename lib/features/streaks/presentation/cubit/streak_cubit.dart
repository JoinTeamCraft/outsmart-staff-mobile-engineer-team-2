import 'package:flutter_bloc/flutter_bloc.dart';
import 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit() : super(const StreakState());

  void incrementStreak() {
    final newStreak = state.currentStreak + 1;
    emit(state.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > state.longestStreak ? newStreak : state.longestStreak,
      celebrationPending: true,
    ));
  }

  void resetStreak() {
    emit(state.copyWith(currentStreak: 0, celebrationPending: false));
  }

  /// Called by the animation widget once it has consumed the
  /// celebration trigger, so it doesn't fire again on rebuild.
  void acknowledgeCelebration() {
    if (!state.celebrationPending) return;
    emit(state.copyWith(celebrationPending: false));
  }
}
