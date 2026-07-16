import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streaklearn/core/network/api_exception.dart';
import 'package:streaklearn/features/quiz/data/quiz_repository.dart';
import 'package:streaklearn/features/quiz/domain/question.dart';
import 'package:streaklearn/features/quiz/domain/quiz.dart';
import 'package:streaklearn/features/quiz/presentation/cubit/quiz_cubit.dart';
import 'package:streaklearn/features/quiz/presentation/cubit/quiz_state.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

void main() {
  late QuizRepository repository;

  const testQuiz = Quiz(
    lessonId: 'lesson-1',
    questions: [
      Question(
        id: 'q1',
        question: 'What is the core building block of a Flutter UI?',
        options: [
          'Widget',
          'Activity',
          'Component',
          'View',
        ],
        correctIndex: 0,
      ),
      Question(
        id: 'q2',
        question: 'Which tree is responsible for handling layouts and paints?',
        options: [
          'Widget Tree',
          'Element Tree',
          'RenderObject Tree',
          'State Tree',
        ],
        correctIndex: 2,
      ),
    ],
  );

  setUp(() {
    repository = MockQuizRepository();
  });

  group('loadQuiz', () {
    blocTest<QuizCubit, QuizState>(
      'emits loading then inProgress when quiz exists',
      build: () {
        when(
              () => repository.getQuizByLessonId(
            'lesson-1',
            forceRefresh: false,
          ),
        ).thenAnswer(
              (_) async => testQuiz,
        );

        return QuizCubit(repository);
      },
      act: (cubit) => cubit.loadQuiz('lesson-1'),
      expect: () => [
        const QuizState(
          status: QuizStatus.loading,
        ),
        const QuizState(
          status: QuizStatus.inProgress,
          quiz: testQuiz,
        ),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'emits empty when lesson has no quiz',
      build: () {
        when(
              () => repository.getQuizByLessonId(
            'lesson-1',
            forceRefresh: false,
          ),
        ).thenAnswer(
              (_) async => null,
        );

        return QuizCubit(repository);
      },
      act: (cubit) => cubit.loadQuiz('lesson-1'),
      expect: () => [
        const QuizState(
          status: QuizStatus.loading,
        ),
        const QuizState(
          status: QuizStatus.empty,
        ),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'emits failure when repository throws ApiException',
      build: () {
        when(
              () => repository.getQuizByLessonId(
            'lesson-1',
            forceRefresh: false,
          ),
        ).thenThrow(
          const NetworkException(
            'Failed to load quiz',
          ),
        );

        return QuizCubit(repository);
      },
      act: (cubit) => cubit.loadQuiz('lesson-1'),
      expect: () => [
        const QuizState(
          status: QuizStatus.loading,
        ),
        const QuizState(
          status: QuizStatus.failure,
          errorMessage: 'Failed to load quiz',
        ),
      ],
    );
  });

  group('answerQuestion', () {
    blocTest<QuizCubit, QuizState>(
      'moves to next question after answering correctly',
      build: () => QuizCubit(repository),
      seed: () => const QuizState(
        status: QuizStatus.inProgress,
        quiz: testQuiz,
      ),
      act: (cubit) => cubit.answerQuestion(0),
      expect: () => [
        const QuizState(
          status: QuizStatus.inProgress,
          quiz: testQuiz,
          currentQuestionIndex: 1,
          correctAnswers: 1,
        ),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'emits complete after final question is answered',
      build: () => QuizCubit(repository),
      seed: () => const QuizState(
        status: QuizStatus.inProgress,
        quiz: testQuiz,
        currentQuestionIndex: 1,
      ),
      act: (cubit) => cubit.answerQuestion(2),
      expect: () => [
        const QuizState(
          status: QuizStatus.complete,
          quiz: testQuiz,
          currentQuestionIndex: 1,
          correctAnswers: 1,
        ),
      ],
    );
  });
}