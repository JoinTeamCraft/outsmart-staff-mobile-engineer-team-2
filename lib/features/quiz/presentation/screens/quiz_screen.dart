import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/question.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/quiz_state.dart';
import '../widgets/quiz_option_tile.dart';

/// OU-12: Quiz screen with a progressive multiple-choice selector.
///
/// Reads the app-wide [QuizCubit] (provided in `AppProviders`) instead of
/// creating its own, so the completion event (OU-13) and the celebration
/// animation that listens to it (OU-17) fire off the same instance — a locally
/// created cubit would be invisible to those app-level listeners.
///
/// State flow: [QuizCubit] owns loading, progression and scoring; this screen
/// owns only the transient per-question feedback. The tapped option is held in
/// [_selectedIndex] to highlight correct/incorrect and gate the "Next" button;
/// committing the answer via [QuizCubit.answerQuestion] advances the cubit
/// (emitting `QuizStatus.complete` on the last question). Keeping feedback local
/// leaves the OU-2 state layer untouched while meeting the OU-12 criteria.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lessonId});

  /// Which lesson's quiz to load, via `QuizRepository.getQuizByLessonId` (OU-1).
  final String lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// The option the user tapped for the current question, or null if it is not
  /// answered yet. Drives the correct/incorrect highlight and enables "Next";
  /// reset to null each time we advance so the next question starts clean.
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Load this lesson's quiz into the app-wide cubit on entry.
    context.read<QuizCubit>().loadQuiz(widget.lessonId);
  }

  void _onOptionTap(int index) {
    // Ignore taps once an answer is locked in — a question is answered once.
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
  }

  void _onNext() {
    final selected = _selectedIndex;
    if (selected == null) return;
    // Commit the answer: the cubit tallies correctness and advances, emitting
    // QuizStatus.complete on the final question (OU-13/OU-17 react to that).
    context.read<QuizCubit>().answerQuestion(selected);
    setState(() => _selectedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          switch (state.status) {
            case QuizStatus.initial:
            case QuizStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case QuizStatus.empty:
              return const _CenteredMessage(
                icon: Icons.quiz_outlined,
                message: 'This lesson has no quiz yet.',
              );
            case QuizStatus.failure:
              return _CenteredMessage(
                icon: Icons.error_outline,
                message: state.errorMessage ?? 'Could not load the quiz.',
                onRetry: () => context.read<QuizCubit>().loadQuiz(
                      widget.lessonId,
                      forceRefresh: true,
                    ),
              );
            case QuizStatus.complete:
              return _QuizCompleteView(
                correct: state.correctAnswers,
                total: state.quiz?.questionCount ?? 0,
                onDone: () => Navigator.of(context).maybePop(),
              );
            case QuizStatus.inProgress:
              return _QuizQuestionView(
                state: state,
                selectedIndex: _selectedIndex,
                onOptionTap: _onOptionTap,
                onNext: _onNext,
              );
          }
        },
      ),
    );
  }
}

/// The active-question layout: progress indicator, prompt, animated options,
/// and the Next/Finish button.
class _QuizQuestionView extends StatelessWidget {
  const _QuizQuestionView({
    required this.state,
    required this.selectedIndex,
    required this.onOptionTap,
    required this.onNext,
  });

  final QuizState state;
  final int? selectedIndex;
  final ValueChanged<int> onOptionTap;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final quiz = state.quiz!;
    final index = state.currentQuestionIndex;
    final question = quiz.questions[index];
    final total = quiz.questionCount;
    final answered = selectedIndex != null;
    final isLast = index == total - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${index + 1} of $total',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (index + 1) / total,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, i) => QuizOptionTile(
                  label: question.options[i],
                  state: _optionState(question, i, selectedIndex),
                  enabled: !answered,
                  onTap: () => onOptionTap(i),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                // Enabled only once an option is chosen.
                onPressed: answered ? onNext : null,
                child: Text(isLast ? 'Finish' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resolves each option's visual state once an answer is locked in: the
  /// correct option turns green, a wrong pick turns red, everything else stays
  /// neutral. Before answering (selected == null), all options are neutral.
  QuizOptionState _optionState(Question question, int i, int? selected) {
    if (selected == null) return QuizOptionState.neutral;
    if (question.isCorrect(i)) return QuizOptionState.correct;
    if (i == selected) return QuizOptionState.incorrect;
    return QuizOptionState.neutral;
  }
}

/// Shown on the final question's completion. The confetti celebration itself is
/// handled globally by the OU-17 overlay reacting to the OU-13 completion event.
class _QuizCompleteView extends StatelessWidget {
  const _QuizCompleteView({
    required this.correct,
    required this.total,
    required this.onDone,
  });

  final int correct;
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Quiz complete!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $correct out of $total',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onDone, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

/// Simple centred icon + message, with an optional retry action, reused for the
/// empty and failure states.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
