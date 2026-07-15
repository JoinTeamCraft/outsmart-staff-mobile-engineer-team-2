/// Immutable, null-safe domain model for a single lesson.
///
/// Parsed from the mock API's `lessons.json` (fields: `id`, `title`, `topic`,
/// `thumbnail`, `content`). Parsing is defensive: missing or malformed fields
/// fall back to empty strings rather than throwing, so a single bad record
/// cannot crash the feed (OU-6) — the repository (OU-1) still guards the
/// decode step as a whole.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.thumbnail,
    required this.content,
  });

  final String id;
  final String title;
  final String topic;

  /// Remote image URL for the lesson card thumbnail (OU-6 / OU-11).
  final String thumbnail;

  /// Body text shown on the Lesson Detail screen (OU-11).
  final String content;

  /// Builds a [Lesson] from a decoded JSON map.
  ///
  /// Every field is read null-safely with a sensible default, keeping the
  /// model total and crash-free even if the source data is incomplete.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  /// Serializes back to JSON. Useful for the in-memory cache (OU-5) and local
  /// persistence (OU-3) that round-trip lessons through storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'thumbnail': thumbnail,
        'content': content,
      };

  /// Value equality so state selectors (OU-22) and tests (OU-23) can compare
  /// lessons by content rather than identity.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          other.id == id &&
          other.title == title &&
          other.topic == topic &&
          other.thumbnail == thumbnail &&
          other.content == content;

  @override
  int get hashCode => Object.hash(id, title, topic, thumbnail, content);

  @override
  String toString() => 'Lesson(id: $id, title: $title, topic: $topic)';
}
