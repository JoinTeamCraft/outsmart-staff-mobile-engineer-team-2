import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streaklearn/features/lessons/presentation/cubit/lesson_cubit.dart';
import 'package:streaklearn/features/lessons/presentation/cubit/lesson_state.dart';
import 'package:streaklearn/features/lessons/data/lesson_repository.dart';
import 'package:streaklearn/core/network/api_exception.dart';

class MockLessonRepository extends Mock implements LessonRepository {}

void main() {
  late LessonRepository repository;

  setUp(() {
    repository = MockLessonRepository();
  });

  blocTest<LessonCubit, LessonState>(
    'emits loading then success when lessons load successfully',
    build: () {
      when(
            () => repository.getLessons(),
      ).thenAnswer((_) async => []);

      return LessonCubit(repository);
    },
    act: (cubit) => cubit.loadLessons(),
    expect: () => [
      const LessonState(
        status: LessonStatus.loading,
      ),
      const LessonState(
        status: LessonStatus.success,
        lessons: [],
        hasReachedMax: true,
      ),
    ],
  );

  blocTest<LessonCubit, LessonState>(
    'emits failure when repository throws ApiException',
    build: () {
      when(
            () => repository.getLessons(),
      ).thenThrow(
        const NetworkException('Network failed'),
      );

      return LessonCubit(repository);
    },
    act: (cubit) => cubit.loadLessons(),
    expect: () => [
      const LessonState(
        status: LessonStatus.loading,
      ),
      const LessonState(
        status: LessonStatus.failure,
        errorMessage: 'Network failed',
      ),
    ],
  );
}