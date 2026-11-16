import 'package:dio/dio.dart';

/// Turns any error from a repository call into a message fit to show a user.
///
/// Prefers the backend's `message` (or `error`) field, then a readable
/// description of network failures, then the text of a plain `Exception`.
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      for (final key in ['message', 'error']) {
        final value = data[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      default:
        if (error.response?.statusCode == 401) {
          return 'Your session has expired. Please log in again.';
        }
        return fallback;
    }
  }

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? fallback : text;
}
