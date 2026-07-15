import 'dart:math';

import 'package:flutter/services.dart';

import 'api_exception.dart';

/// Thin wrapper over the mock API. Loads raw JSON from bundled assets and
/// simulates real-world network behaviour (latency + optional failures).
///
/// Failure simulation is **off by default** ([failureRate] = 0.0) so normal
/// runs are deterministic and other tracks are never disrupted. Raise the rate
/// via DI — e.g. in tests (OU-23) or a debug toggle — to exercise the error
/// paths that the repositories (OU-1) and error UX (OU-7) must handle.
class ApiClient {
  ApiClient({
    this.failureRate = 0.0,
    this.latency = const Duration(milliseconds: 500),
    Random? random,
  })  : assert(failureRate >= 0.0 && failureRate <= 1.0,
            'failureRate must be between 0.0 and 1.0'),
        _random = random ?? Random();

  /// Probability in `[0.0, 1.0]` that any given request throws a simulated
  /// [NetworkException] instead of returning data.
  final double failureRate;

  /// Artificial delay applied to every request to mimic network latency.
  final Duration latency;

  final Random _random;

  /// Returns the raw lessons JSON string, after simulated latency/failure.
  Future<String> getLessonsRaw() => _load('assets/mock_data/lessons.json');

  /// Returns the raw quizzes JSON string, after simulated latency/failure.
  Future<String> getQuizzesRaw() => _load('assets/mock_data/quizzes.json');

  /// Shared request pipeline: delay, maybe fail, otherwise load the asset.
  Future<String> _load(String assetPath) async {
    await Future<void>.delayed(latency);
    if (_shouldFail()) {
      throw NetworkException('Simulated network failure loading $assetPath');
    }
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      // A genuinely missing/unreadable asset is also a network-style failure
      // from the caller's perspective — surface it as a typed exception so it
      // never crashes the UI.
      throw NetworkException('Failed to load asset $assetPath', e);
    }
  }

  bool _shouldFail() => failureRate > 0.0 && _random.nextDouble() < failureRate;
}
