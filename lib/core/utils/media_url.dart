import '../config/env.dart';

/// Resolves relative upload paths from the API to a full image URL.
String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}
