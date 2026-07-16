import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/quiz_result.dart';
import 'quiz_cubit.dart';
import 'quiz_state.dart';

/// Emits a [QuizResult] each time a quiz attempt completes (OU-13).
///
/// This is the subscribable completion event other tracks consume — the
/// results summary (OU-14), the streak counter / celebration animations
/// (OU-16 / OU-17, wired by OU-18) and reminder cancellation (OU-27) all listen
/// here via `BlocListener<QuizCompletionCubit, QuizResult?>`.
///
/// It projects [QuizCubit]'s `QuizStatus.complete` transition into a typed
/// [QuizResult]. Observing the quiz cubit's stream — rather than editing
/// [QuizCubit] — keeps the OU-2 state layer untouched, while still exposing an
/// idiomatic Cubit for consumers to listen to.
///
/// It deliberately does NOT mutate the streak. Reacting to completion (streak
/// increment + firing animations) is owned by OU-18; OU-13 only defines and
/// emits the event. See the OU-13/OU-18 boundary agreed in team chat.
///
/// State lifecycle: the state holds the latest [QuizResult] only from a
/// completion until the next quiz starts, then resets to `null`. This keeps the
/// cubit event-like — a widget that reads `state` never processes a stale
/// result from an old attempt — and, because the state passes through `null`
/// between attempts, two completions with an identical score still both emit
/// (each is a `null -> result` change), independent of the timestamp. Consumers
/// should filter the `null` the stream emits on reset (e.g. `whereType`).
class QuizCompletionCubit extends Cubit<QuizResult?> {
  QuizCompletionCubit(this._quizCubit, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now,
        super(null) {
    _lastStatus = _quizCubit.state.status;
    _subscription = _quizCubit.stream.listen(_onQuizState);
  }

  final QuizCubit _quizCubit;
  final DateTime Function() _now;
  late final StreamSubscription<QuizState> _subscription;
  late QuizStatus _lastStatus;

  void _onQuizState(QuizState state) {
    final status = state.status;

    // A new quiz starting clears any previous result, so a widget reading
    // `state` never sees a stale result from an old attempt, and consecutive
    // completions always emit (each is a null -> result change).
    if (status == QuizStatus.loading && _lastStatus != QuizStatus.loading) {
      _lastStatus = status;
      emit(null);
      return;
    }

    // Emit only on the transition INTO complete, so the result fires once per
    // attempt (the cubit stays in `complete` until the next quiz loads).
    final justCompleted =
        status == QuizStatus.complete && _lastStatus != QuizStatus.complete;
    _lastStatus = status;
    if (!justCompleted) return;

    final quiz = state.quiz;
    if (quiz == null) return; // defensive: complete should always carry a quiz

    emit(
      QuizResult(
        lessonId: quiz.lessonId,
        correctAnswers: state.correctAnswers,
        totalQuestions: quiz.questionCount,
        completedAt: _now(),
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
