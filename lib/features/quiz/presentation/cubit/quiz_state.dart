import 'package:equatable/equatable.dart';
import '../../domain/quiz.dart';

/// Mutually exclusive lifecycle states for an in-progress quiz attempt.
///
/// [complete] is the specific signal OU-18 (animation sync) should listen
/// for to trigger the streak celebration — see [QuizCubit.answerQuestion].
enum QuizStatus { initial, loading, inProgress, complete, failure }

/// Immutable state for [QuizCubit]. Compared by value via [Equatable] so
/// `BlocBuilder` only rebuilds when a field actually changes.
class QuizState extends Equatable {
  /// Current lifecycle phase — see [QuizStatus].
  final QuizStatus status;

  /// The quiz currently being attempted. Null until [QuizCubit.loadQuiz]
  /// succeeds.
  final Quiz? quiz;

  /// Zero-based index of the question currently being answered.
  final int currentQuestionIndex;

  /// Running count of correctly answered questions this attempt.
  final int correctAnswers;

  /// Human-readable failure reason, set only when [status] is
  /// [QuizStatus.failure]. Sourced from `ApiException.message`, or a plain
  /// "no quiz found" message when the repository returns no quiz for the
  /// lesson — see [QuizCubit].
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz,
    this.currentQuestionIndex = 0,
    this.correctAnswers = 0,
    this.errorMessage,
  });

  /// Convenience for listeners (OU-18) that only care about the specific
  /// moment a quiz attempt finishes, without comparing the enum directly.
  bool get isComplete => status == QuizStatus.complete;

  /// Returns a copy with only the given fields replaced — every other field
  /// is carried over unchanged. Always emit through this rather than
  /// constructing `QuizState(...)` directly.
  QuizState copyWith({
    QuizStatus? status,
    Quiz? quiz,
    int? currentQuestionIndex,
    int? correctAnswers,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, quiz, currentQuestionIndex, correctAnswers, errorMessage];
}
