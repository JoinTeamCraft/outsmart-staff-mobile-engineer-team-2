import 'package:equatable/equatable.dart';

class StreakState extends Equatable {
  final int currentStreak;
  final int longestStreak;

  /// True for exactly one emission after a streak increment. Listener
  /// widgets should fire their celebration animation then call
  /// StreakCubit.acknowledgeCelebration() to reset it — this is what
  /// keeps hot-reload/rebuild from re-triggering the animation (OU-18).
  final bool celebrationPending;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.celebrationPending = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    bool? celebrationPending,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      celebrationPending: celebrationPending ?? this.celebrationPending,
    );
  }

  @override
  List<Object?> get props => [currentStreak, longestStreak, celebrationPending];
}
