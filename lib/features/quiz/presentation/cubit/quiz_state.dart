import 'package:equatable/equatable.dart';
import '../../domain/quiz.dart';

const _unset = Object();

/// Mutually exclusive lifecycle states for loading and completing a quiz.
///
/// [empty] indicates the requested lesson has no quiz available.
/// [complete] is the signal OU-18 should listen for to trigger the streak
/// celebration.
enum QuizStatus { initial, loading, empty, inProgress, complete, failure }

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

  /// Human-readable failure reason.
  /// Only populated when [status] is [QuizStatus.failure], typically from
  /// an [ApiException].
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz,
    this.currentQuestionIndex = 0,
    this.correctAnswers = 0,
    this.errorMessage,
  });

  /// Convenience for UI listeners that need to handle the expected case where
  /// a lesson does not have quiz content available.
  bool get isEmpty => status == QuizStatus.empty;

  /// Convenience for listeners (OU-18) that only care about the specific
  /// moment a quiz attempt finishes, without comparing the enum directly.
  bool get isComplete => status == QuizStatus.complete;

  /// Indicates whether the current state represents an unrecoverable quiz
  /// loading failure, such as a network or parsing error.
  bool get hasFailure => status == QuizStatus.failure;

  /// Uses sentinels for nullable fields that need to support explicit clearing.
  /// Passing `quiz: null` or `errorMessage: null` explicitly removes the
  /// existing value instead of preserving it. Every other field
  /// is carried over unchanged. Always emit through this rather than
  /// constructing `QuizState(...)` directly.
  QuizState copyWith({
    QuizStatus? status,
    Object? quiz = _unset,
    int? currentQuestionIndex,
    int? correctAnswers,
    Object? errorMessage = _unset,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: identical(quiz, _unset) ? this.quiz : quiz as Quiz?,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props =>
      [status, quiz, currentQuestionIndex, correctAnswers, errorMessage];
}
