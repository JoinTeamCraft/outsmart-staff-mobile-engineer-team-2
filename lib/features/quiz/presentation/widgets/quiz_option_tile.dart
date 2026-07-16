import 'package:flutter/material.dart';

/// Visual state of a single answer option (OU-12).
///
/// [neutral] before an answer is locked in (and for the non-answers afterwards),
/// [correct] for the right option once answered, [incorrect] for a wrong pick.
enum QuizOptionState { neutral, correct, incorrect }

/// A tappable multiple-choice answer that animates between its states.
///
/// The colour/border transition (neutral -> correct/incorrect) is driven by an
/// [AnimatedContainer], so selecting an answer reads as a smooth highlight
/// rather than an instant swap — this is the "animate choice selection states"
/// part of the OU-12 acceptance criteria.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final QuizOptionState state;

  /// Whether this option can still be tapped. False once an answer is locked
  /// in, so a question cannot be answered twice.
  final bool enabled;

  /// Invoked on tap; ignored while [enabled] is false.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Material 3 has a semantic error role but no success role, so we pair the
    // theme's error colour for "incorrect" with a brightness-adjusted green for
    // "correct". Backgrounds are translucent tints over the surface, so the
    // option label keeps full contrast in both light and dark themes; neutral
    // leans on surface tokens.
    final Color correctAccent =
        isDark ? Colors.green.shade400 : Colors.green.shade700;
    final double tintAlpha = isDark ? 0.22 : 0.12;

    final (Color background, Color border, IconData? icon, Color iconColor) =
        switch (state) {
      QuizOptionState.correct => (
          correctAccent.withValues(alpha: tintAlpha),
          correctAccent,
          Icons.check_circle,
          correctAccent,
        ),
      QuizOptionState.incorrect => (
          scheme.error.withValues(alpha: tintAlpha),
          scheme.error,
          Icons.cancel,
          scheme.error,
        ),
      QuizOptionState.neutral => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          scheme.outlineVariant,
          null,
          scheme.onSurface,
        ),
    };

    // Announce the outcome to screen readers once an answer is locked in, so
    // options with similar text stay distinguishable by state (not just label).
    final String? semanticValue = switch (state) {
      QuizOptionState.correct => 'Correct',
      QuizOptionState.incorrect => 'Incorrect',
      QuizOptionState.neutral => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: state != QuizOptionState.neutral,
        value: semanticValue,
        label: label,
        child: Material(
          // InkWell needs a Material ancestor for its ink. A transparent
          // Material lets the AnimatedContainer own the visible surface while
          // InkWell adds focus/hover/ripple and keyboard activation — the
          // Material semantics a bare GestureDetector lacks.
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            // Explicit radius (matching the Material clip) keeps the ink shape
            // correct even if the surrounding clip ever changes.
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 12),
                    Icon(icon, color: iconColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
