import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/lesson_repository.dart';
import 'lesson_state.dart';

/// Owns lesson list state. UI widgets read via BlocBuilder/context.watch
/// and never touch LessonRepository or Lesson JSON directly
/// NOTE: this is OU-2's foundation only — a single fetch of the full list.
/// Pagination (`hasReachedMax`, `loadMoreLessons`) is OU-10's scope and
/// will build on top of this state shape without changing it.
class LessonCubit extends Cubit<LessonState> {
  final LessonRepository repository;

  LessonCubit(this.repository) : super(const LessonState());

  /// Pass [forceRefresh] for pull-to-refresh / retry, so it actually
  /// re-hits the API instead of silently returning the repository's
  /// cached result.
  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (state.status == LessonStatus.loading) return;
    emit(state.copyWith(status: LessonStatus.loading));
    try {
      final lessons = await repository.getLessons(forceRefresh: forceRefresh);
      emit(state.copyWith(
        status: LessonStatus.success,
        lessons: lessons,
        hasReachedMax: true, // no pagination yet — OU-10 will manage this
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LessonStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}
