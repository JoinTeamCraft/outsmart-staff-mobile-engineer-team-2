import 'question.dart';

/// Immutable, null-safe domain model for a lesson's quiz.
///
/// Parsed from the mock API's `quizzes.json` (fields: `lessonId`, `questions`).
/// Note the bundled asset omits a quiz-level `id`, while the mock server's
/// `db.json` includes one — so [id] is nullable to stay null-safe across both
/// data sources.
class Quiz {
  const Quiz({
    required this.lessonId,
    required this.questions,
    this.id,
  });

  /// Present only when sourced from the mock server (`db.json`); `null` for the
  /// bundled asset.
  final String? id;

  /// The lesson this quiz belongs to — the key used by
  /// `QuizRepository.getQuizByLessonId` (OU-1) and the "Start Quiz" flow (OU-11).
  final String lessonId;

  final List<Question> questions;

  /// Builds a [Quiz] from a decoded JSON map, null-safely.
  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions =
        json['questions'] as List<dynamic>? ?? const <dynamic>[];
    return Quiz(
      id: json['id'] as String?,
      lessonId: json['lessonId'] as String? ?? '',
      questions: rawQuestions
          .whereType<Map<String, dynamic>>()
          .map(Question.fromJson)
          .toList(growable: false),
    );
  }

  /// Number of questions — drives the "Question X of N" progress (OU-12).
  int get questionCount => questions.length;

  /// True when the quiz has no usable questions (an empty/absent state the
  /// quiz UI should handle rather than treating as an error).
  bool get isEmpty => questions.isEmpty;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'lessonId': lessonId,
        'questions': questions.map((q) => q.toJson()).toList(growable: false),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quiz &&
          other.id == id &&
          other.lessonId == lessonId &&
          _questionsEqual(other.questions, questions);

  @override
  int get hashCode => Object.hash(id, lessonId, Object.hashAll(questions));

  @override
  String toString() =>
      'Quiz(lessonId: $lessonId, questions: ${questions.length})';
}

bool _questionsEqual(List<Question> a, List<Question> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
