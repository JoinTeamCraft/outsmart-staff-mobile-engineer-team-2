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

      final filtered = _filteredLessons;
      final firstPage = filtered.take(pageSize).toList();

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: firstPage,
          hasReachedMax: firstPage.length >= filtered.length,
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
      final filtered = _filteredLessons;
      final nextPage =
          filtered.skip(state.lessons.length).take(pageSize).toList();

      final updatedLessons = [
        ...state.lessons,
        ...nextPage,
      ];

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: updatedLessons,
          hasReachedMax: updatedLessons.length >= filtered.length,
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

  /// Distinct topics across all loaded lessons, for the filter chips (OU-9).
  List<String> get topics =>
      _allLessons.map((l) => l.topic).toSet().toList()..sort();

  /// Lessons matching the current search query and selected topic (OU-9).
  List<Lesson> get _filteredLessons =>
      _applyFilters(_allLessons, state.searchQuery, state.selectedTopic);

  List<Lesson> _applyFilters(List<Lesson> source, String query, String? topic) {
    final normalized = query.trim().toLowerCase();
    return source.where((lesson) {
      final matchesQuery =
          normalized.isEmpty || lesson.title.toLowerCase().contains(normalized);
      final matchesTopic = topic == null || lesson.topic == topic;
      return matchesQuery && matchesTopic;
    }).toList();
  }

  /// Applies a new search [query] and resets to the first page of results.
  void search(String query) =>
      _emitFiltered(query: query, topic: state.selectedTopic);

  /// Applies a topic filter ([topic] `null` = all) and resets to first page.
  void selectTopic(String? topic) =>
      _emitFiltered(query: state.searchQuery, topic: topic);

  void _emitFiltered({required String query, required String? topic}) {
    final filtered = _applyFilters(_allLessons, query, topic);
    final firstPage = filtered.take(pageSize).toList();
    emit(
      state.copyWith(
        status: LessonStatus.success,
        searchQuery: query,
        selectedTopic: topic,
        lessons: firstPage,
        hasReachedMax: firstPage.length >= filtered.length,
        errorMessage: null,
      ),
    );
  }
}
