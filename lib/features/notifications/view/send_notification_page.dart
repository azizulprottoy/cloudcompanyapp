import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controller/send_notification_controller.dart';

class SendNotificationPage extends GetView<SendNotificationController> {
  const SendNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send announcement')),
      body: RefreshIndicator(
        onRefresh: controller.loadSent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.audience.value,
                      decoration: const InputDecoration(labelText: 'Send to'),
                      items: [
                        for (final e
                            in SendNotificationController.audiences.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) =>
                          controller.audience.value = v ?? 'public',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.titleController,
                    maxLength: 140,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Add a title' : null,
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller.bodyController,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Write a message' : null,
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller.urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Link (optional)',
                      hintText: 'https://… or /buypackage',
                    ),
                    validator: controller.validateUrl,
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isSending.value
                          ? null
                          : controller.send,
                      icon: controller.isSending.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sent announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoadingSent.value && controller.sent.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.sent.isEmpty) {
                return const Text(
                  'Nothing sent yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final n in controller.sent)
                      ListTile(
                        title: Text(n.title),
                        subtitle: Text(
                          '${n.body}\n${SendNotificationController.audiences[n.audience] ?? n.audience ?? ''} · ${Formatters.dateTime(n.createdAt)}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
