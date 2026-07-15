import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/quiz.dart';

/// Data-layer entry point for quizzes.
///
/// Wraps [ApiClient] and exposes a clean, typed async interface consumed by the
/// quiz flow (OU-12) and results screen (OU-14). Failures are re-surfaced as
/// typed [ApiException]s so they never crash the UI.
class QuizRepository {
  const QuizRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Returns the [Quiz] for [lessonId], or `null` if that lesson has no quiz.
  ///
  /// The distinction is deliberate:
  ///  - a `null` return means "no quiz exists for this lesson" — a normal,
  ///    non-error state the UI can show as empty;
  ///  - a thrown [ApiException] means the request or parsing actually failed.
  ///
  /// Throws:
  ///  - [NetworkException] if the underlying request fails.
  ///  - [DataParsingException] if the response cannot be decoded.
  Future<Quiz?> getQuizByLessonId(String lessonId) async {
    final String raw;
    try {
      raw = await _apiClient.getQuizzesRaw();
    } on ApiException {
      rethrow;
    } catch (e, st) {
      throw NetworkException('Failed to fetch quizzes', e, st);
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        // Compare as strings so a numeric `lessonId` in the JSON source
        // still matches, instead of silently missing.
        if (item['lessonId']?.toString() == lessonId) {
          return Quiz.fromJson(item);
        }
      }
      return null; // no quiz for this lesson — not an error
    } catch (e, st) {
      throw DataParsingException(
        'Failed to parse quiz for lesson $lessonId',
        e,
        st,
      );
    }
  }
}
