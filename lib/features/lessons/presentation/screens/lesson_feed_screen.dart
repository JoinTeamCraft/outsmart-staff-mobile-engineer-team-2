import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quiz/presentation/screens/quiz_screen.dart';
import '../cubit/lesson_cubit.dart';
import '../cubit/lesson_state.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_filter_bar.dart';

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
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.extentAfter < 200) {
      context.read<LessonCubit>().loadMoreLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreakLearn'),
        // OU-9: search field + topic chips live in the AppBar's bottom slot so
        // they stay visible across the loading/empty/list states below.
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: LessonFilterBar(),
        ),
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
                context.read<LessonCubit>().loadLessons(forceRefresh: true);
              },
            );
          }

          if (!hasLessons) {
            // Distinguish "no data at all" from "filter matched nothing" (OU-9).
            final isFiltering =
                state.searchQuery.isNotEmpty || state.selectedTopic != null;
            return Center(
              child: Text(
                isFiltering
                    ? 'No lessons match your search.'
                    : 'No lessons yet.',
              ),
            );
          }

          final showFooterLoader = state.status == LessonStatus.loadingMore;

          final itemCount = state.lessons.length + (showFooterLoader ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<LessonCubit>().loadLessons(forceRefresh: true);
            },
            child: ListView.builder(
              key: const PageStorageKey('lesson_feed_list'),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: itemCount,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                if (showFooterLoader && index == state.lessons.length) {
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
                    // TEMPORARY (OU-12): until OU-11's lesson-detail screen and
                    // its "Start Quiz" CTA exist, tapping a lesson opens its
                    // quiz directly so the quiz flow is reachable and testable.
                    // OU-11 will replace this with navigation to the detail
                    // screen, whose CTA then pushes QuizScreen.
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuizScreen(lessonId: lesson.id),
                      ),
                    );
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
