import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../error/api_error.dart';

/// App-wide user feedback, so every screen reports success and errors the same way.
class AppServices {
  AppServices._();

  static void showSuccess(String message) =>
      _snack(message, AppColors.success, Icons.check_circle_outline);

  static void showError(String message) =>
      _snack(message, AppColors.error, Icons.error_outline);

  static void showInfo(String message) =>
      _snack(message, AppColors.ink, Icons.info_outline);

  /// Shows the server's message for a failed request. 401s on signed-in calls
  /// are skipped: the API client already ends the session and says so.
  static void showApiError(Object error, {String? fallback}) {
    if (error is DioException && error.response?.statusCode == 401) {
      final isLogin = error.requestOptions.extra['isAuthCall'] == true;
      if (!isLogin) return;
    }
    showError(
      fallback == null
          ? apiErrorMessage(error)
          : apiErrorMessage(error, fallback: fallback),
    );
  }

  static void _snack(String message, Color color, IconData icon) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.showSnackbar(
      GetSnackBar(
        messageText: Text(message, style: const TextStyle(color: Colors.white)),
        icon: Icon(icon, color: Colors.white),
        backgroundColor: color,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
