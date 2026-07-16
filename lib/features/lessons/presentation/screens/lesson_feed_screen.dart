import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/lesson_cubit.dart';
import '../cubit/lesson_state.dart';
import '../widgets/lesson_card.dart';

/// OU-6: main entry feed. Renders directly off LessonCubit's state — no
/// static arrays, no local List<Lesson> field on this widget. Virtualized
/// via ListView.builder, which only builds visible items (+ a small cache
/// extent) regardless of list length.
///
/// NOTE: `hasReachedMax` is always true and `LessonStatus.loadingMore` is
/// never emitted yet — pagination is OU-10's scope, built on top of this
/// same state shape without changing it. The `loadingMore` branch below is
/// handled only so the switch stays exhaustive.
class LessonFeedScreen extends StatelessWidget {
  const LessonFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreakLearn')),
      body: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          final hasLessons = state.lessons.isNotEmpty;

          // A refresh retains the previously loaded list. Replacing it with a
          // page-level spinner disposes every image widget, which causes their
          // placeholders to flash (and can leave a failed request appearing to
          // load again).
          if (!hasLessons &&
              (state.status == LessonStatus.initial ||
                  state.status == LessonStatus.loading)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!hasLessons && state.status == LessonStatus.failure) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () =>
                  context.read<LessonCubit>().loadLessons(forceRefresh: true),
            );
          }

          if (!hasLessons) {
            return const Center(child: Text('No lessons yet.'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<LessonCubit>().loadLessons(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.lessons.length,
              itemBuilder: (context, index) {
                final lesson = state.lessons[index];
                return RepaintBoundary(
                  child: LessonCard(
                    key: ValueKey(lesson.id),
                    lesson: lesson,
                    onTap: () {
                      // Lesson detail / quiz launch point — wired up
                      // once Track C's quiz screen (OU-11/OU-12) exists.
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
