import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_services.dart';
import '../model/app_notification.dart';
import '../repository/notification_repository.dart';

/// Admin: write an announcement and send it to an audience.
class SendNotificationController extends GetxController {
  SendNotificationController({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository();

  final NotificationRepository _repository;

  static const audiences = {
    'public': 'Everyone (including visitors)',
    'clients': 'All clients',
    'employees': 'All team members',
    'admins': 'All admins',
  };

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final urlController = TextEditingController();
  final audience = 'public'.obs;
  final isSending = false.obs;

  final sent = <AppNotification>[].obs;
  final isLoadingSent = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSent();
  }

  Future<void> loadSent() async {
    isLoadingSent.value = true;
    try {
      sent.assignAll(await _repository.sent());
    } catch (_) {
      // History is secondary; the form still works.
    } finally {
      isLoadingSent.value = false;
    }
  }

  String? validateUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.startsWith('https://') ||
        (v.startsWith('/') && !v.startsWith('//'))) {
      return null;
    }
    return 'Use an https:// link or a site path like /buypackage';
  }

  Future<void> send() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final ok = await AppServices.confirm(
      title: 'Send announcement?',
      message:
          'This goes to ${audiences[audience.value]!.toLowerCase()} right away and can\'t be recalled.',
      confirmText: 'Send',
    );
    if (!ok) return;

    isSending.value = true;
    try {
      await _repository.broadcast(
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        audience: audience.value,
        url: urlController.text.trim(),
      );
      titleController.clear();
      bodyController.clear();
      urlController.clear();
      AppServices.showSuccess('Announcement sent.');
      loadSent();
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not send the announcement.');
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    urlController.dispose();
    super.onClose();
  }
}
