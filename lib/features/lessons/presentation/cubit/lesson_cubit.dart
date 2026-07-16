import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/lesson_repository.dart';
import '../../domain/lesson.dart';
import 'lesson_state.dart';

/// Owns lesson list state, including pagination (OU-10).
///
/// The repository currently returns the full lesson dataset, so pagination is
/// simulated client-side by storing all lessons in [_allLessons] and exposing
/// them in smaller pages. If the API supports real pagination later, only the
/// fetching logic needs to change. The UI and state structure remain the same.
class LessonCubit extends Cubit<LessonState> {
  LessonCubit(this.repository) : super(const LessonState());

  final LessonRepository repository;

  static const int pageSize = 2;

  /// Complete dataset used for client-side pagination.
  final List<Lesson> _allLessons = [];

  /// Loads the first page of lessons.
  ///
  /// [forceRefresh] bypasses repository cache when refreshing.
  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (state.status == LessonStatus.loading) return;

    emit(
      state.copyWith(
        status: LessonStatus.loading,
        lessons: [],
        errorMessage: null,
      ),
    );

    try {
      final lessons = await repository.getLessons(
        forceRefresh: forceRefresh,
      );

      _allLessons
        ..clear()
        ..addAll(lessons);

      final firstPage = _allLessons.take(pageSize).toList();

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: firstPage,
          hasReachedMax: firstPage.length >= _allLessons.length,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: LessonStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LessonStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Loads the next page and appends it to the existing lessons.
  ///
  /// Existing lessons remain visible while loading. Pagination failures do not
  /// replace the current feed with an error screen.
  Future<void> loadMoreLessons() async {
    if (state.hasReachedMax) return;

    if (state.status == LessonStatus.loadingMore) return;

    emit(
      state.copyWith(
        status: LessonStatus.loadingMore,
        errorMessage: null,
      ),
    );

    try {
      final nextPage =
          _allLessons.skip(state.lessons.length).take(pageSize).toList();

      final updatedLessons = [
        ...state.lessons,
        ...nextPage,
      ];

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: updatedLessons,
          hasReachedMax: updatedLessons.length >= _allLessons.length,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          // Keep existing feed visible.
          status: LessonStatus.success,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LessonStatus.success,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
