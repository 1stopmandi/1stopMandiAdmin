/// API exception with optional status code and message from backend.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Extracts a clean, user-facing message from API errors.
String friendlyError(Object e) {
  if (e is ApiException) return e.message;
  return e.toString();
}
