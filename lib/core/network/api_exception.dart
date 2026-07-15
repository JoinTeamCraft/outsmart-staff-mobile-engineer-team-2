// Typed failures surfaced by the data layer (network client + repositories).
//
// Catching the single base type [ApiException] lets downstream consumers — the
// state layer (OU-2) and the Lesson Feed error UX (OU-7) — handle every
// data-layer failure uniformly, without depending on `dart:io` (which is
// unavailable on web, our primary target).

/// Base class for all data-layer failures.
///
/// Prefer catching this type rather than [Exception] broadly, so genuinely
/// unexpected errors still bubble up during development. [cause] is positional
/// so subclasses can forward it via super parameters.
class ApiException implements Exception {
  const ApiException(this.message, [this.cause, this.stackTrace]);

  /// Human-readable, non-localized description of what failed.
  final String message;

  /// The original error/exception that caused this failure, when wrapping one.
  final Object? cause;

  /// The stack trace captured where [cause] was caught. Preserving it makes
  /// missing/invalid-asset and parse failures far easier to diagnose than the
  /// message alone. Both are positional so subclasses forward them via super
  /// parameters.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'ApiException: $message${cause == null ? '' : ' (cause: $cause)'}';
}

/// Thrown when a (simulated) network request fails before returning any data.
///
/// Maps to a "retry" error state in the UI (OU-7).
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Network request failed',
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when a response was received but could not be parsed into a model.
///
/// Kept distinct from [NetworkException] so consumers can tell a transient
/// connectivity issue (retryable) from malformed data (not retryable).
class DataParsingException extends ApiException {
  const DataParsingException([
    super.message = 'Failed to parse data',
    super.cause,
    super.stackTrace,
  ]);
}
