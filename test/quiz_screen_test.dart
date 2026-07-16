import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/network/api_exception.dart';
import 'package:streaklearn/features/quiz/data/quiz_repository.dart';
import 'package:streaklearn/features/quiz/domain/question.dart';
import 'package:streaklearn/features/quiz/domain/quiz.dart';
import 'package:streaklearn/features/quiz/presentation/cubit/quiz_cubit.dart';
import 'package:streaklearn/features/quiz/presentation/screens/quiz_screen.dart';
import 'package:streaklearn/features/quiz/presentation/widgets/quiz_option_tile.dart';

// Extends Fake (flutter_test) so any repository member the test does not stub
// throws UnimplementedError instead of silently misbehaving — type-safe, unlike
// a catch-all noSuchMethod. Only getQuizByLessonId is exercised here.
class _FakeQuizRepo extends Fake implements QuizRepository {
  _FakeQuizRepo(this._quiz);
  final Quiz? _quiz;
  @override
  Future<Quiz?> getQuizByLessonId(
    String lessonId, {
    bool forceRefresh = false,
  }) async =>
      _quiz;
}

// Always fails, to exercise the failure UI + retry path.
class _ThrowingQuizRepo extends Fake implements QuizRepository {
  @override
  Future<Quiz?> getQuizByLessonId(
    String lessonId, {
    bool forceRefresh = false,
  }) async =>
      throw const NetworkException('boom');
}

Quiz _quizWith2() => const Quiz(
      lessonId: 'l1',
      questions: [
        Question(
          id: 'q1',
          question: 'One plus one?',
          options: ['1', '2', '3'],
          correctIndex: 1,
        ),
        Question(
          id: 'q2',
          question: 'Capital of France?',
          options: ['Paris', 'Rome'],
          correctIndex: 0,
        ),
      ],
    );

Widget _wrap(QuizCubit cubit) => MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const QuizScreen(lessonId: 'l1'),
      ),
    );

void main() {
  testWidgets('progresses through all questions and shows completion + score',
      (tester) async {
    final cubit = QuizCubit(_FakeQuizRepo(_quizWith2()));
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    // Q1 shown with progress.
    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Answer Q1 correctly -> a correct-state tile appears, Next enables.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    final correctTiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .where((t) => t.state == QuizOptionState.correct);
    expect(correctTiles, isNotEmpty);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Q2 shown; last question shows "Finish".
    expect(find.text('Question 2 of 2'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    // Answer Q2 incorrectly -> selected tile is incorrect.
    await tester.tap(find.text('Rome'));
    await tester.pumpAndSettle();
    final incorrectTiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .where((t) => t.state == QuizOptionState.incorrect);
    expect(incorrectTiles, isNotEmpty);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    // Completion view with score (1 correct of 2).
    expect(find.text('Quiz complete!'), findsOneWidget);
    expect(find.text('You scored 1 out of 2'), findsOneWidget);
  });

  testWidgets('empty quiz shows the empty state', (tester) async {
    final cubit = QuizCubit(_FakeQuizRepo(null));
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();
    expect(find.text('This lesson has no quiz yet.'), findsOneWidget);
  });

  testWidgets('load failure shows the error message and a retry action',
      (tester) async {
    final cubit = QuizCubit(_ThrowingQuizRepo());
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
