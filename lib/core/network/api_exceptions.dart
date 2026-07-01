/// Base class for all Aplano network-layer errors.
///
/// Catch [ApiException] to handle any HTTP / connectivity failure uniformly.
/// Catch specific subclasses when you need fine-grained handling.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  /// User-facing message. Kept identical to [message] so snackbars/dialogs that
  /// print `e.toString()` show a clean, friendly message rather than
  /// "UnauthorizedException: ..." (which the common `.replaceFirst('Exception: ',
  /// '')` cleanup would further mangle).
  @override
  String toString() => message;
}

// ── Connectivity ─────────────────────────────────────────────────────────────

/// No internet connection, DNS failure, or host unreachable.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// The request timed out before the server responded.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([
     super.message = 'The request timed out. Please try again.',
   ]);
}
// ── Server / HTTP ─────────────────────────────────────────────────────────────

/// The server returned a 4xx or 5xx status code.
class ServerException extends ApiException {
  const ServerException(super.message, {required this.statusCode});

  final int statusCode;
}

/// 401 — missing or invalid JWT; triggers a token refresh attempt.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please log in again.',
  ]);
}

/// 403 — authenticated but lacking the required permission.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

/// 404 — the requested resource does not exist.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'The requested resource was not found.']);
}

/// 422 — the server rejected the request body (validation errors).
class ValidationException extends ApiException {
  const ValidationException(super.message, {this.fieldErrors = const {}});

  /// Map of field name → list of error messages returned by the server.
  final Map<String, List<String>> fieldErrors;
}

// ── Client ────────────────────────────────────────────────────────────────────

/// The response body could not be decoded (malformed JSON, wrong shape, etc.).
class ParseException extends ApiException {
  const ParseException([super.message = 'Failed to parse server response.']);
}

/// A catch-all for unexpected errors not covered by the classes above.
class UnknownException extends ApiException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}