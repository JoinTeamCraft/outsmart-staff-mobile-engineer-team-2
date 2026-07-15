/// Immutable, null-safe domain model for a single quiz question.
///
/// Parsed from the mock API's `quizzes.json` question objects (fields: `id`,
/// `question`, `options`, `correctIndex`).
class Question {
  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String question;

  /// The selectable answers, in display order.
  final List<String> options;

  /// Zero-based index into [options] of the correct answer.
  ///
  /// Defaults to `-1` when absent/malformed so it can never accidentally match
  /// a real selection; guard with [hasValidAnswer] before trusting it.
  final int correctIndex;

  /// Builds a [Question] from a decoded JSON map, null-safely.
  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const <dynamic>[];
    return Question(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: rawOptions.map((o) => o.toString()).toList(growable: false),
      correctIndex: json['correctIndex'] as int? ?? -1,
    );
  }

  /// Whether [correctIndex] points at a real option — false for malformed data.
  bool get hasValidAnswer => correctIndex >= 0 && correctIndex < options.length;

  /// Convenience used by the quiz flow (OU-12) and results screen (OU-14):
  /// is [selectedIndex] the correct answer for this question?
  bool isCorrect(int selectedIndex) =>
      hasValidAnswer && selectedIndex == correctIndex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          other.id == id &&
          other.question == question &&
          other.correctIndex == correctIndex &&
          _listEquals(other.options, options);

  @override
  int get hashCode =>
      Object.hash(id, question, correctIndex, Object.hashAll(options));

  @override
  String toString() => 'Question(id: $id, options: ${options.length})';
}

/// Order-sensitive list equality (avoids a package dependency for a single use).
bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
