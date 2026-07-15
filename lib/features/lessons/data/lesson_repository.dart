import 'dart:convert';

import '../../../core/cache/memory_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/lesson.dart';

/// Data-layer entry point for lessons.
///
/// Wraps [ApiClient] and exposes a clean, typed async interface that the state
/// layer (OU-2) and UI (OU-6) build on. Results are served through an in-memory
/// [MemoryCache] (OU-5) so repeat reads are instant and concurrent reads share
/// a single fetch. Every failure is caught and re-surfaced as a typed
/// [ApiException], so a network or parsing error never crashes the UI.
class LessonRepository {
  LessonRepository(this._apiClient, {MemoryCache<String, List<Lesson>>? cache})
      : _cache = cache ?? MemoryCache<String, List<Lesson>>();

  final ApiClient _apiClient;
  final MemoryCache<String, List<Lesson>> _cache;

  /// The whole lesson list is a single cache entry under this key.
  static const String _lessonsKey = 'lessons';

  /// Fetches all lessons as typed [Lesson] objects.
  ///
  /// Served from the in-memory cache when available: repeat calls return the
  /// cached list with no network call, and concurrent calls share one fetch.
  /// Pass [forceRefresh] (used by pull-to-refresh, OU-8) to bypass the cache
  /// and reload from the API.
  ///
  /// Throws (only on an actual reload, never from the cache path):
  ///  - [NetworkException] if the underlying request fails.
  ///  - [DataParsingException] if the response cannot be decoded into models.
  ///
  /// Callers (state layer / OU-7 error UX) should catch [ApiException] and
  /// present a retry/error state instead of letting it bubble up.
  Future<List<Lesson>> getLessons({bool forceRefresh = false}) {
    return _cache.getOrFetch(
      _lessonsKey,
      _fetchLessons,
      forceRefresh: forceRefresh,
    );
  }

  /// Performs the actual network fetch + parse. Only called on a cache miss or
  /// [forceRefresh]; its result is what the cache stores.
  Future<List<Lesson>> _fetchLessons() async {
    final String raw;
    try {
      raw = await _apiClient.getLessonsRaw();
    } on ApiException {
      rethrow; // already typed by ApiClient
    } catch (e, st) {
      throw NetworkException('Failed to fetch lessons', e, st);
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Lesson.fromJson)
          .toList(growable: false);
    } catch (e, st) {
      throw DataParsingException('Failed to parse lessons response', e, st);
    }
  }
}
