import 'package:equatable/equatable.dart';

/// Immutable payload emitted when a quiz attempt completes (OU-13).
///
/// This is the cross-track contract other tickets subscribe to: the results
/// summary (OU-14), the streak counter + celebration animations (OU-16 / OU-17
/// via OU-18), and reminder cancellation (OU-27). It carries the raw counts
/// (not just a percentage) so every consumer has what it needs and can derive
/// its own presentation.
class QuizResult extends Equatable {
  const QuizResult({
    required this.lessonId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.completedAt,
  });

  /// The lesson whose quiz was completed.
  final String lessonId;

  /// Number of questions answered correctly this attempt.
  final int correctAnswers;

  /// Total number of questions in the quiz.
  final int totalQuestions;

  /// When the attempt finished. Injected via a clock at the emit site so it
  /// stays deterministic under test.
  final DateTime completedAt;

  /// Score as a percentage in `[0, 100]`; `0` when the quiz had no questions
  /// (guards against divide-by-zero).
  double get scorePercent =>
      totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  /// True when every question was answered correctly.
  bool get isPerfect => totalQuestions > 0 && correctAnswers == totalQuestions;

  @override
  List<Object?> get props => [
        lessonId,
        correctAnswers,
        totalQuestions,
        completedAt,
      ];

  @override
  String toString() =>
      'QuizResult(lessonId: $lessonId, $correctAnswers/$totalQuestions, '
      'at: $completedAt)';
}
