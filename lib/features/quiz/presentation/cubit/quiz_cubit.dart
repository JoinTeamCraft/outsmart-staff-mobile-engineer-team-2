import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/quiz_repository.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  final QuizRepository repository;

  QuizCubit(this.repository) : super(const QuizState());

  Future<void> loadQuiz(String lessonId, {bool forceRefresh = false}) async {
    if (state.status == QuizStatus.loading) return;

    emit(
      state.copyWith(
        status: QuizStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final quiz = await repository.getQuizByLessonId(
        lessonId,
        forceRefresh: forceRefresh,
      );

      // A missing or empty quiz means this lesson does not have quiz content.
      // This is an expected business state, not an error condition.
      if (quiz == null || quiz.isEmpty) {
        emit(
          state.copyWith(
            status: QuizStatus.empty,
            quiz: null,
            errorMessage: null,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: QuizStatus.inProgress,
          quiz: quiz,
          currentQuestionIndex: 0,
          correctAnswers: 0,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  /// Advances to the next question, tallying correctness. Emits
  /// QuizStatus.complete on the final question — this is the signal
  /// StreakCubit/animation code (OU-18) should listen for.
  void answerQuestion(int selectedIndex) {
    final quiz = state.quiz;
    if (quiz == null || state.status != QuizStatus.inProgress) return;

    final question = quiz.questions[state.currentQuestionIndex];
    final isCorrect = question.isCorrect(selectedIndex);
    final nextIndex = state.currentQuestionIndex + 1;
    final isLastQuestion = nextIndex >= quiz.questions.length;

    emit(state.copyWith(
      status: isLastQuestion ? QuizStatus.complete : QuizStatus.inProgress,
      currentQuestionIndex:
      isLastQuestion ? state.currentQuestionIndex : nextIndex,
      correctAnswers: state.correctAnswers + (isCorrect ? 1 : 0),
    ));
  }
}
