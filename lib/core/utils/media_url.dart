import 'app_constants.dart';

/// Normalises image/file URLs coming from the API.
class MediaUrl {
  MediaUrl._();

  /// - null/empty → null
  /// - relative "/uploads/..." → prefixed with the API base URL
  /// - old "http://api.cloudcompany.cc/..." → https (Android blocks cleartext)
  /// - data: URIs (placeholder ads) are not network images → null
  static String? resolve(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty || value.startsWith('data:')) return null;
    if (value.startsWith('/')) return '${AppConstants.baseUrl}$value';
    return value.replaceFirst(
      RegExp(r'^http://api\.cloudcompany\.cc', caseSensitive: false),
      'https://api.cloudcompany.cc',
    );
  }
}
