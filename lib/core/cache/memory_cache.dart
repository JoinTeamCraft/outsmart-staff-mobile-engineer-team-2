/// A generic in-memory cache with cache-aside loading and single-flight
/// de-duplication of concurrent fetches.
///
/// It does two things a responsive consumer app needs:
///  1. **Serve completed values instantly** on repeat reads — back-and-forth
///     navigation returns cached data with no network call.
///  2. **De-duplicate in-flight loads** — if a fetch for a key is already
///     running, concurrent callers share that same [Future] instead of firing
///     a second network call. This is what actually prevents duplicate fetches
///     when a screen builds and requests the same data more than once at once.
///
/// [ttl] is optional. When `null` (the default) entries never expire on their
/// own — the right policy for the app's static lesson/quiz content, whose
/// freshness is controlled explicitly via `forceRefresh` (pull-to-refresh,
/// OU-8). Pass a [ttl] for endpoints whose data goes stale with time.
///
/// [clock] is injectable so tests (OU-23) can drive [ttl] expiry
/// deterministically.
///
/// The cache is intentionally unbounded (no size cap / LRU eviction): it is
/// used here with a small, fixed set of keys (one per endpoint), so growth is
/// naturally bounded. A size-bounded eviction policy can be added if a future
/// caller keys by many distinct, unbounded values.
class MemoryCache<K, V> {
  MemoryCache({this.ttl, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Duration? ttl;
  final DateTime Function() _clock;

  final Map<K, _CacheEntry<V>> _entries = {};
  final Map<K, Future<V>> _inFlight = {};

  /// Monotonic per-key generation. Bumped whenever a new fetch starts, or on
  /// [invalidate]/[clear]. A completing fetch only commits its result if the
  /// key's generation still matches the one captured when it started — so a
  /// superseded (e.g. slower) fetch can never overwrite fresher data.
  final Map<K, int> _generation = {};

  /// Returns the cached value for [key] if present and fresh; otherwise loads
  /// it via [fetch], stores the result, and returns it.
  ///
  /// - [forceRefresh] skips any cached value and forces a fresh [fetch] (the
  ///   result still updates the cache).
  /// - Concurrent calls for the same [key] share a single in-flight [fetch].
  /// - A failing [fetch] is never cached; the error propagates to the caller.
  /// - If a newer fetch or an [invalidate]/[clear] supersedes this one while it
  ///   is in flight, this fetch's result is returned to its own callers but is
  ///   NOT written to the cache (prevents a stale-write race under
  ///   forceRefresh / pull-to-refresh).
  Future<V> getOrFetch(
    K key,
    Future<V> Function() fetch, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final entry = _entries[key];
      if (entry != null && !_isExpired(entry)) {
        return Future<V>.value(entry.value);
      }
      final pending = _inFlight[key];
      if (pending != null) return pending;
    }

    // Tag this fetch with the key's next generation; a later fetch or
    // invalidate() will bump it and invalidate this fetch's commit.
    final generation = (_generation[key] ?? 0) + 1;
    _generation[key] = generation;

    late final Future<V> future;
    future = fetch().then((value) {
      if (_generation[key] == generation) {
        _entries[key] = _CacheEntry(value, _clock());
      }
      return value;
    }).whenComplete(() {
      // Only clear if this is still the current in-flight fetch — a later
      // forceRefresh may have replaced it.
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    });
    _inFlight[key] = future;
    return future;
  }

  /// Removes any cached (and in-flight) value for [key], and supersedes any
  /// in-flight fetch so its result will not be written after this call.
  void invalidate(K key) {
    _entries.remove(key);
    _inFlight.remove(key);
    _generation[key] = (_generation[key] ?? 0) + 1;
  }

  /// Clears the entire cache and supersedes all in-flight fetches.
  void clear() {
    _entries.clear();
    _inFlight.clear();
    for (final key in _generation.keys.toList()) {
      _generation[key] = _generation[key]! + 1;
    }
  }

  bool _isExpired(_CacheEntry<V> entry) {
    final ttl = this.ttl;
    if (ttl == null) return false;
    // Expired once the full TTL has elapsed (>=), the conventional boundary.
    return _clock().difference(entry.storedAt) >= ttl;
  }
}

class _CacheEntry<V> {
  _CacheEntry(this.value, this.storedAt);

  final V value;
  final DateTime storedAt;
}
