import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/lesson_repository.dart';
import '../../domain/lesson.dart';
import 'lesson_state.dart';

/// Owns lesson list state, including pagination (OU-10).
///
/// NOTE on pagination strategy: [LessonRepository.getLessons] returns the
/// entire dataset in one call — there's no real offset/limit query on the
/// mock API. So this Cubit fetches the full (repository-cached) list once,
/// keeps it in [_allLessons], and pages through it client-side. If the API
/// ever gains real pagination, only [loadMoreLessons] needs to change to
/// call a paginated repository method instead of slicing — the UI and
/// state shape stay the same.
class LessonCubit extends Cubit<LessonState> {
  final LessonRepository repository;
  static const int pageSize = 2;

  List<Lesson> _allLessons = [];

  LessonCubit(this.repository) : super(const LessonState());

  /// Loads the first page. Pass [forceRefresh] for pull-to-refresh / retry,
  /// so it actually re-hits the API instead of silently returning the
  /// repository's cached result.
  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (state.status == LessonStatus.loading) return;

    emit(
      state.copyWith(
        status: LessonStatus.loading,
        errorMessage: null,
        lessons: [],
        hasReachedMax: false,
      ),
    );

    try {
      _allLessons = await repository.getLessons(forceRefresh: forceRefresh);
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
    }
  }

  /// Called when the scroll position nears the bottom of the list.
  /// Appends the next page without touching the lessons already shown.
  ///
  /// The try/on ApiException here is currently unreachable — slicing
  /// [_allLessons] is synchronous and can't throw. It's kept deliberately
  /// as the seam for real server-side pagination: once
  /// [LessonRepository] gains a paginated method (e.g. `getLessons(page:,
  /// pageSize:)`), only the fetch line inside the try block changes to an
  /// actual `await repository.getLessons(...)` call — the ApiException
  /// handling below already matches the convention every other repository
  /// call in this codebase uses, so it works unchanged once that line
  /// becomes a real network call.
  Future<void> loadMoreLessons() async {
    if (state.hasReachedMax ||
        state.status == LessonStatus.loadingMore ||
        state.status == LessonStatus.loading ||
        state.status == LessonStatus.initial) {
      return;
    }

    emit(
      state.copyWith(
        status: LessonStatus.loadingMore,
        errorMessage: null,
      ),
    );

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
      ),
    );
  }
}
