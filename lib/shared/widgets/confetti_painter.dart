import 'dart:math';

import 'package:flutter/material.dart';

/// A single confetti particle.
///
/// Position and velocity are in fractional screen units (0..1) so a burst
/// scales identically on any screen size.
class ConfettiParticle {
  const ConfettiParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
    required this.isRect,
  });

  /// Launch point as a fraction of the screen (0..1 in each axis).
  final Offset origin;

  /// Launch direction in radians (`-pi/2` is straight up).
  final double angle;

  /// Initial speed as a fraction of the screen per unit of progress.
  final double speed;

  final Color color;

  /// Particle size in logical pixels.
  final double size;

  /// Number of full rotations over the animation.
  final double spin;

  /// Rectangle vs. circle — mixing shapes reads as confetti.
  final bool isRect;
}

/// Paints a lightweight confetti burst.
///
/// [progress] runs 0 -> 1 over the animation. Each particle launches outward
/// from its origin and falls under gravity (simple projectile motion), then
/// fades out near the end. Kept cheap — a bounded particle list, no allocations
/// in [paint] beyond a single reused [Paint].
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({required this.particles, required this.progress});

  final List<ConfettiParticle> particles;
  final double progress;

  /// Downward acceleration, in fractions of screen height per unit of progress².
  static const double _gravity = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    // Hold full opacity, then fade over the final 35%.
    final opacity = t < 0.65 ? 1.0 : (1.0 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final dx = (p.origin.dx + cos(p.angle) * p.speed * t) * size.width;
      final dy =
          (p.origin.dy + sin(p.angle) * p.speed * t + 0.5 * _gravity * t * t) *
              size.height;
      if (dy > size.height + 40) continue; // already off-screen

      paint.color = p.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(p.spin * t * 2 * pi);
      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}

/// Builds a festive burst of [count] particles launching upward/outward from
/// near the top-centre. Pass a seeded [random] for deterministic output.
List<ConfettiParticle> generateConfetti({int count = 40, Random? random}) {
  final rnd = random ?? Random();
  const palette = <Color>[
    Color(0xFFEF476F),
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFF8338EC),
    Color(0xFFFB5607),
  ];
  return List<ConfettiParticle>.generate(count, (_) {
    // Spread of roughly ±90° around straight up.
    final angle = -pi / 2 + (rnd.nextDouble() - 0.5) * pi;
    return ConfettiParticle(
      origin: Offset(0.5 + (rnd.nextDouble() - 0.5) * 0.1, 0.25),
      angle: angle,
      speed: 0.5 + rnd.nextDouble() * 0.6,
      color: palette[rnd.nextInt(palette.length)],
      size: 8 + rnd.nextDouble() * 8,
      spin: 1 + rnd.nextDouble() * 3,
      isRect: rnd.nextBool(),
    );
  });
}
