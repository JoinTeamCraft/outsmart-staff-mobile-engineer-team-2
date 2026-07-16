import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/quiz/domain/quiz_result.dart';
import '../../features/quiz/presentation/cubit/quiz_completion_cubit.dart';
import 'confetti_painter.dart';

/// App-wide overlay that plays a confetti celebration when a quiz completes
/// (OU-17).
///
/// It listens to [QuizCompletionCubit] (OU-13) and paints a lightweight
/// confetti burst above whatever screen is showing. Mounted via
/// `MaterialApp.builder` so it covers every route. The paint is isolated in a
/// [RepaintBoundary] and wrapped in [IgnorePointer], so it never repaints or
/// blocks the UI underneath.
///
/// OU-17/OU-18 boundary: OU-17 both builds this celebration and self-triggers
/// it off the completion event; OU-18 owns the streak-counter (OU-16)
/// orchestration.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<ConfettiParticle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Drop the particles once the burst finishes so nothing is painted.
          setState(() => _particles = const []);
        }
      });
  }

  void _celebrate() {
    setState(() => _particles = generateConfetti());
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizCompletionCubit, QuizResult?>(
      // Fire only on a real completion; ignore the null the cubit emits on the
      // new-quiz reset.
      listenWhen: (previous, current) => current != null,
      listener: (_, __) => _celebrate(),
      child: Stack(
        children: [
          widget.child,
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: ConfettiPainter(
                        particles: _particles,
                        progress: _controller.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
