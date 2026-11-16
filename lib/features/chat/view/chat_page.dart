import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/chat_controller.dart';
import '../model/chat_models.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.room.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Obx(
              () => Text(
                controller.connected.value ? 'Live' : 'Connecting…',
                style: TextStyle(
                  fontSize: 12,
                  color: controller.connected.value
                      ? AppColors.success
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.isNotEmpty && controller.messages.isEmpty) {
                return ErrorView(
                  message: controller.error.value,
                  onRetry: controller.load,
                );
              }
              if (controller.messages.isEmpty) {
                return const EmptyView(
                  title: 'No messages yet',
                  message: 'Say hello — the conversation will appear here.',
                  icon: Icons.chat_bubble_outline,
                );
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                itemCount: controller.messages.length,
                itemBuilder: (_, i) {
                  final m = controller.messages[i];
                  return _Bubble(
                    message: m,
                    mine: m.sender == controller.room.mySender,
                  );
                },
              );
            }),
          ),
          _Composer(controller: controller),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bg = mine ? AppColors.primary : AppColors.surface;
    final fg = mine ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: bg,
          border: mine ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final a in message.attachments) ...[
              _Attachment(attachment: a, color: fg),
              const SizedBox(height: 6),
            ],
            if (message.text.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  message.text,
                  style: TextStyle(color: fg, fontSize: 15),
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.dateTime(message.time),
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({required this.attachment, required this.color});

  final ChatAttachment attachment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    void open() => launchUrl(
      Uri.parse(attachment.url),
      mode: LaunchMode.externalApplication,
    );
    if (attachment.isImage) {
      return GestureDetector(
        onTap: open,
        child: AppNetworkImage(
          url: attachment.url,
          width: 220,
          height: 160,
          radius: 10,
        ),
      );
    }
    return InkWell(
      onTap: open,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                color: color,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PopupMenuButton<ImageSource>(
              icon: const Icon(Icons.attach_file),
              tooltip: 'Attach',
              onSelected: controller.attach,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ImageSource.gallery,
                  child: Text('Photos'),
                ),
                PopupMenuItem(value: ImageSource.camera, child: Text('Camera')),
              ],
            ),
            Expanded(
              child: TextField(
                controller: controller.textController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message…',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Obx(
              () => IconButton.filled(
                onPressed: controller.isSending.value ? null : controller.send,
                icon: controller.isSending.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
