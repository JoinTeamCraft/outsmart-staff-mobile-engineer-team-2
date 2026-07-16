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

  /// Distinct topics, cached; recomputed only when [_allLessons] changes.
  List<String> _topics = const [];

  /// Lessons matching the active search/topic, cached; recomputed only when the
  /// query, topic, or [_allLessons] changes — never on every read or rebuild.
  List<Lesson> _filtered = const [];

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

      _recomputeTopics();
      _filtered = _computeFiltered(state.searchQuery, state.selectedTopic);
      final firstPage = _filtered.take(pageSize).toList();

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: firstPage,
          hasReachedMax: firstPage.length >= _filtered.length,
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
          _filtered.skip(state.lessons.length).take(pageSize).toList();

      final updatedLessons = [
        ...state.lessons,
        ...nextPage,
      ];

      emit(
        state.copyWith(
          status: LessonStatus.success,
          lessons: updatedLessons,
          hasReachedMax: updatedLessons.length >= _filtered.length,
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

  /// Distinct topics for the filter chips (OU-9) — a cached O(1) read.
  List<String> get topics => _topics;

  void _recomputeTopics() {
    _topics = _allLessons.map((l) => l.topic).toSet().toList()..sort();
  }

  /// Filters [_allLessons] by [query] (case-insensitive title match) and
  /// [topic]. Only invoked when inputs change (load or filter), so it never
  /// runs on a rebuild/read.
  List<Lesson> _computeFiltered(String query, String? topic) {
    final normalized = query.trim().toLowerCase();
    return _allLessons.where((lesson) {
      final matchesQuery =
          normalized.isEmpty || lesson.title.toLowerCase().contains(normalized);
      final matchesTopic = topic == null || lesson.topic == topic;
      return matchesQuery && matchesTopic;
    }).toList(growable: false);
  }

  /// Applies a new search [query] and resets to the first page of results.
  void search(String query) =>
      _emitFiltered(query: query, topic: state.selectedTopic);

  /// Applies a topic filter ([topic] `null` = all) and resets to first page.
  void selectTopic(String? topic) =>
      _emitFiltered(query: state.searchQuery, topic: topic);

  void _emitFiltered({required String query, required String? topic}) {
    _filtered = _computeFiltered(query, topic);
    final firstPage = _filtered.take(pageSize).toList();
    emit(
      state.copyWith(
        status: LessonStatus.success,
        searchQuery: query,
        selectedTopic: topic,
        lessons: firstPage,
        hasReachedMax: firstPage.length >= _filtered.length,
        errorMessage: null,
      ),
    );
  }
}
