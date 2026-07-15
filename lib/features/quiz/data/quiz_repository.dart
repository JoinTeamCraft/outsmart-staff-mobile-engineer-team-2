import 'dart:convert';

import '../../../core/cache/memory_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/quiz.dart';

/// Data-layer entry point for quizzes.
///
/// Wraps [ApiClient] and exposes a clean, typed async interface consumed by the
/// quiz flow (OU-12) and results screen (OU-14). The full quiz list is fetched
/// and cached once (OU-5), so looking up a second lesson's quiz costs no extra
/// network call. Failures are re-surfaced as typed [ApiException]s so they
/// never crash the UI.
class QuizRepository {
  QuizRepository(this._apiClient, {MemoryCache<String, List<Quiz>>? cache})
      : _cache = cache ?? MemoryCache<String, List<Quiz>>();

  final ApiClient _apiClient;
  final MemoryCache<String, List<Quiz>> _cache;

  /// The whole quiz list is a single cache entry under this key — the mock API
  /// returns every quiz in one call, so caching the list lets any lesson be
  /// resolved from memory.
  static const String _quizzesKey = 'quizzes';

  /// Returns the [Quiz] for [lessonId], or `null` if that lesson has no quiz.
  ///
  /// The distinction is deliberate:
  ///  - a `null` return means "no quiz exists for this lesson" — a normal,
  ///    non-error state the UI can show as empty;
  ///  - a thrown [ApiException] means the request or parsing actually failed.
  ///
  /// The quiz list is served from the in-memory cache when available (repeat
  /// and concurrent lookups share one fetch). Pass [forceRefresh] (used by
  /// pull-to-refresh, OU-8) to reload the list from the API.
  ///
  /// Throws (only on an actual reload):
  ///  - [NetworkException] if the underlying request fails.
  ///  - [DataParsingException] if the response cannot be decoded.
  Future<Quiz?> getQuizByLessonId(
    String lessonId, {
    bool forceRefresh = false,
  }) async {
    final quizzes = await _cache.getOrFetch(
      _quizzesKey,
      _fetchQuizzes,
      forceRefresh: forceRefresh,
    );
    for (final quiz in quizzes) {
      if (quiz.lessonId == lessonId) return quiz;
    }
    return null; // no quiz for this lesson — not an error
  }

  /// Performs the actual network fetch + parse of the whole quiz list. Only
  /// called on a cache miss or [forceRefresh]; its result is what the cache
  /// stores. [Quiz.fromJson] parses defensively, so a single malformed record
  /// degrades rather than dropping the list.
  Future<List<Quiz>> _fetchQuizzes() async {
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
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Quiz.fromJson)
          .toList(growable: false);
    } catch (e, st) {
      throw DataParsingException('Failed to parse quizzes response', e, st);
    }
  }
}
