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
    final scheme = Theme.of(context).colorScheme;

    // Resolve the tile's appearance from its answer state. Correct/incorrect
    // use fixed semantic green/red (legible in light and dark); neutral leans
    // on theme surface tokens so it adapts to either brightness.
    final (Color background, Color border, IconData? icon, Color iconColor) =
        switch (state) {
      QuizOptionState.correct => (
          Colors.green.withValues(alpha: 0.15),
          Colors.green,
          Icons.check_circle,
          Colors.green,
        ),
      QuizOptionState.incorrect => (
          Colors.red.withValues(alpha: 0.15),
          Colors.red,
          Icons.cancel,
          Colors.red,
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
