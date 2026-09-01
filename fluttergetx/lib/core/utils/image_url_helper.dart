import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized helper for constructing full image URLs from relative paths.
///
/// Handles various edge cases:
/// - Empty/null paths
/// - Paths with/without leading slash
/// - Trailing slash in base URL
/// - Different environments via .env
class ImageUrlHelper {
  static String? _baseUrl;

  static String get _resolvedBaseUrl {
    if (_baseUrl != null) return _baseUrl!;
    String url = dotenv.env['API_URL'] ?? '';
    // Remove trailing slash for consistency
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return _baseUrl!;
  }

  /// Resolves a relative image path to a full URL.
  /// Returns null if [relativePath] is null or empty.
  static String? resolve(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;

    final baseUrl = _resolvedBaseUrl;
    if (baseUrl.isEmpty) return relativePath; // fallback to relative if no base URL

    // Remove leading slash from relative path to avoid double slash
    final cleanPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$baseUrl/$cleanPath';
  }

  /// Resolves but throws if base URL is not configured (for debugging).
  static String resolveOrThrow(String? relativePath) {
    final result = resolve(relativePath);
    if (result == null) {
      throw ArgumentError('Image path is null or empty');
    }
    return result;
  }

  /// Clears cached base URL (useful for testing or env changes).
  static void clearCache() {
    _baseUrl = null;
  }
}