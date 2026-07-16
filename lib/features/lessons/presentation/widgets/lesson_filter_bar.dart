import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lesson_cubit.dart';
import '../cubit/lesson_state.dart';

/// Search field + topic filter chips for the Lesson Feed (OU-9).
///
/// Typing is debounced ~300ms before the query reaches [LessonCubit.search],
/// so the list is not re-filtered on every keystroke. Topic chips call
/// [LessonCubit.selectTopic]; tapping the already-selected topic toggles back
/// to "All".
class LessonFilterBar extends StatefulWidget {
  const LessonFilterBar({super.key});

  @override
  State<LessonFilterBar> createState() => _LessonFilterBarState();
}

class _LessonFilterBarState extends State<LessonFilterBar> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  void _onQueryChanged(String value) {
    // Restart the timer on each keystroke; only the last one fires.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) context.read<LessonCubit>().search(value);
    });
  }

  @override
  void dispose() {
    // Cancel a pending timer so it can't fire after this widget is gone.
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search lessons',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Rebuilds when topics load or the selection changes.
          BlocBuilder<LessonCubit, LessonState>(
            builder: (context, state) {
              final cubit = context.read<LessonCubit>();
              final topics = cubit.topics;
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TopicChip(
                      label: 'All',
                      selected: state.selectedTopic == null,
                      onSelected: () => cubit.selectTopic(null),
                    ),
                    for (final topic in topics)
                      _TopicChip(
                        label: topic,
                        selected: state.selectedTopic == topic,
                        // Tapping the active topic clears back to "All".
                        onSelected: () => cubit.selectTopic(
                          state.selectedTopic == topic ? null : topic,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
