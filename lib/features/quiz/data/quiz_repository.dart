import 'dart:convert';

import '../../../core/cache/memory_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/quiz.dart';

/// Data-layer entry point for quizzes.
///
/// Wraps [ApiClient] and exposes a clean, typed async interface consumed by the
/// quiz flow (OU-12) and results screen (OU-14). The full quiz set is fetched
/// and cached once (OU-5) as a `Map` keyed by `lessonId`, so looking up any
/// lesson's quiz is O(1) and costs no extra network call. Failures are
/// re-surfaced as typed [ApiException]s so they never crash the UI.
class QuizRepository {
  QuizRepository(
    this._apiClient, {
    MemoryCache<String, Map<String, Quiz>>? cache,
  }) : _cache = cache ?? MemoryCache<String, Map<String, Quiz>>();

  final ApiClient _apiClient;

  /// Cache of `lessonId -> Quiz` (the mock API returns every quiz in one call).
  final MemoryCache<String, Map<String, Quiz>> _cache;

  static const String _quizzesKey = 'quizzes';

  /// Returns the [Quiz] for [lessonId], or `null` if that lesson has no quiz.
  ///
  /// The distinction is deliberate:
  ///  - a `null` return means "no quiz exists for this lesson" — a normal,
  ///    non-error state the UI can show as empty;
  ///  - a thrown [ApiException] means the request or parsing actually failed.
  ///
  /// The quiz set is served from the in-memory cache when available (repeat and
  /// concurrent lookups share one fetch). Pass [forceRefresh] (used by
  /// pull-to-refresh, OU-8) to reload from the API.
  ///
  /// Throws (only on an actual reload):
  ///  - [NetworkException] if the underlying request fails.
  ///  - [DataParsingException] if the response cannot be decoded.
  Future<Quiz?> getQuizByLessonId(
    String lessonId, {
    bool forceRefresh = false,
  }) async {
    final byLessonId = await _cache.getOrFetch(
      _quizzesKey,
      _fetchQuizzes,
      forceRefresh: forceRefresh,
    );
    return byLessonId[lessonId];
  }

  /// Performs the actual network fetch + parse of the whole quiz set, indexed
  /// by `lessonId`. Only called on a cache miss or [forceRefresh]; its result
  /// is what the cache stores. [Quiz.fromJson] parses defensively, so a single
  /// malformed record degrades rather than dropping the set.
  Future<Map<String, Quiz>> _fetchQuizzes() async {
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
      final byLessonId = <String, Quiz>{};
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        final quiz = Quiz.fromJson(item);
        // First quiz for a lesson wins — matches the prior list-scan semantics.
        byLessonId.putIfAbsent(quiz.lessonId, () => quiz);
      }
      return byLessonId;
    } catch (e, st) {
      throw DataParsingException('Failed to parse quizzes response', e, st);
    }
  }
}
