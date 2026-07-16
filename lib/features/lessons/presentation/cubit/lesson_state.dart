import 'package:equatable/equatable.dart';
import '../../domain/lesson.dart';

/// Sentinel used by copyWith to distinguish "not provided" from
/// "explicitly clear this nullable field".
const _unset = Object();

/// Mutually exclusive lifecycle states for the lesson list.
///
/// An enum rather than separate booleans (`isLoading`, `hasError`, ...) so
/// illegal combinations (e.g. loading + error at once) can't be represented.
/// `loadingMore` represents fetching the next page while keeping existing
/// lessons visible.
enum LessonStatus { initial, loading, loadingMore, success, failure }

/// Immutable state for [LessonCubit]. Compared by value via [Equatable] so
/// `BlocBuilder` only rebuilds when a field actually changes.
class LessonState extends Equatable {
  /// Current lifecycle phase — see [LessonStatus].
  final LessonStatus status;

  /// Lessons currently loaded and ready to display.
  /// Empty during initial loading or refresh until data is available.
  final List<Lesson> lessons;

  /// True when all available lessons have been loaded.
  /// Remains false while additional pages are available to load.
  final bool hasReachedMax;

  /// Human-readable failure reason, set only when [status] is
  /// [LessonStatus.failure]. Sourced from `ApiException.message` — see
  /// [LessonCubit].
  final String? errorMessage;

  /// Current search query applied to the list (OU-9). Empty means no search.
  final String searchQuery;

  /// Selected topic filter (OU-9); `null` means all topics.
  final String? selectedTopic;

  const LessonState({
    this.status = LessonStatus.initial,
    this.lessons = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedTopic,
  });

  /// Returns a copy with only the given fields replaced — every other field
  /// is carried over unchanged. Always emit through this rather than
  /// constructing `LessonState(...)` directly, so an emit that only changes
  /// e.g. [status] can't accidentally reset [lessons] back to empty.
  LessonState copyWith({
    LessonStatus? status,
    List<Lesson>? lessons,
    bool? hasReachedMax,
    Object? errorMessage = _unset,
    String? searchQuery,
    Object? selectedTopic = _unset,
  }) {
    return LessonState(
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTopic: identical(selectedTopic, _unset)
          ? this.selectedTopic
          : selectedTopic as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lessons,
        hasReachedMax,
        errorMessage,
        searchQuery,
        selectedTopic,
      ];
}
