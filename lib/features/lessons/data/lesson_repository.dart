import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/lesson.dart';

/// Data-layer entry point for lessons.
///
/// Wraps [ApiClient] and exposes a clean, typed async interface that the state
/// layer (OU-2) and in-memory cache (OU-5) build on. Every failure is caught
/// and re-surfaced as a typed [ApiException], so a network or parsing error
/// never propagates as an unhandled crash into the UI.
class LessonRepository {
  const LessonRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches all lessons as typed [Lesson] objects.
  ///
  /// Throws:
  ///  - [NetworkException] if the underlying request fails (e.g. simulated
  ///    network failure).
  ///  - [DataParsingException] if the response cannot be decoded into models.
  ///
  /// Callers (state layer / OU-7 error UX) should catch [ApiException] and
  /// present a retry/error state instead of letting it bubble up.
  Future<List<Lesson>> getLessons() async {
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
