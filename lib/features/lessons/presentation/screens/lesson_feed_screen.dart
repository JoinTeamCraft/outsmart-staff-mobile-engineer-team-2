import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lesson_cubit.dart';
import '../cubit/lesson_state.dart';
import '../widgets/lesson_card.dart';

/// OU-6 + OU-10: Main lesson feed with virtualized scrolling and client-side
/// pagination. The UI renders directly from LessonCubit state.
class LessonFeedScreen extends StatefulWidget {
  const LessonFeedScreen({super.key});

  @override
  State<LessonFeedScreen> createState() => _LessonFeedScreenState();
}

class _LessonFeedScreenState extends State<LessonFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;

    if (position.pixels == position.maxScrollExtent)  {
      context.read<LessonCubit>().loadMoreLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreakLearn'),
      ),
      body: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          final hasLessons = state.lessons.isNotEmpty;

          // Initial load only.
          if (!hasLessons &&
              (state.status == LessonStatus.initial ||
                  state.status == LessonStatus.loading)) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!hasLessons && state.status == LessonStatus.failure) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () {
                context
                    .read<LessonCubit>()
                    .loadLessons(forceRefresh: true);
              },
            );
          }

          if (!hasLessons) {
            return const Center(
              child: Text('No lessons yet.'),
            );
          }

          final showFooterLoader =
              state.status == LessonStatus.loadingMore;

          final itemCount =
              state.lessons.length + (showFooterLoader ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              await context
                  .read<LessonCubit>()
                  .loadLessons(forceRefresh: true);
            },
            child: ListView.builder(
              key: const PageStorageKey('lesson_feed_list'),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: itemCount,
              cacheExtent: 500,

              itemBuilder: (context, index) {
                if (showFooterLoader &&
                    index == state.lessons.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                final lesson = state.lessons[index];

                return LessonCard(
                  key: ValueKey(lesson.id),
                  lesson: lesson,
                  onTap: () {
                    // Navigate to lesson details (OU-11).
                  },
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
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
