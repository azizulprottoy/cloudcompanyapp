import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/error/api_error.dart';
import '../../../core/utils/app_services.dart';
import '../../notifications/controller/notification_center.dart';
import '../model/chat_models.dart';
import '../repository/chat_repository.dart';

class ChatController extends GetxController {
  ChatController({ChatRepository? repository, ImagePicker? picker})
    : _repository = repository ?? ChatRepository(),
      _picker = picker ?? ImagePicker();

  final ChatRepository _repository;
  final ImagePicker _picker;

  late final ChatRoom room;

  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final error = ''.obs;
  final connected = false.obs;

  final textController = TextEditingController();
  final scrollController = ScrollController();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  Timer? _reconnectTimer;
  int _retries = 0;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    room = Get.arguments as ChatRoom;
    // No pop-up pushes for the conversation already on screen.
    NotificationCenter.to.activeChatRoom = room.roomId;
    load();
    _connect();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      messages.assignAll(await _repository.history(room));
      _scrollToBottom(jump: true);
      _repository.markRead(room).catchError((_) {});
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _connect() {
    if (_closed) return;
    try {
      _channel = _repository.connect(room);
      _socketSub = _channel!.stream.listen(
        (raw) {
          connected.value = true;
          _retries = 0;
          final event = _repository.parse(raw);
          if (event is ChatMessageEvent) _addIncoming(event.message);
          if (event is ChatReadEvent) _markReadLocally(event.sender);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    connected.value = false;
    _socketSub?.cancel();
    if (_closed) return;
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 << _retries.clamp(0, 4))); // 2s … 32s
    _retries++;
    _reconnectTimer = Timer(delay, () {
      load(); // catch anything missed while offline
      _connect();
    });
  }

  void _addIncoming(ChatMessage message) {
    final exists = messages.any(
      (m) =>
          (message.id.isNotEmpty && m.id == message.id) || m.key == message.key,
    );
    if (exists) return;
    messages.add(message);
    _scrollToBottom();
    if (message.sender != room.mySender) {
      _repository.markRead(room).catchError((_) {});
    }
  }

  void _markReadLocally(String sender) {
    // "sender" = whose messages were read. Ours were read by the other side.
    for (final m in messages) {
      if (m.sender == sender) m.read = true;
    }
    messages.refresh();
  }

  Future<void> send() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;
    isSending.value = true;
    try {
      final saved = await _repository.send(room, text);
      textController.clear();
      _addIncoming(saved);
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Message not sent.');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> attach(ImageSource source) async {
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: source, imageQuality: 85);
        picked = [?photo];
      } else {
        picked = await _picker.pickMultiImage(imageQuality: 85, limit: 10);
      }
      if (picked.isEmpty) return;
      isSending.value = true;
      final saved = await _repository.sendFiles(
        room,
        picked.map((x) => File(x.path)).toList(),
        text: textController.text.trim(),
      );
      textController.clear();
      _addIncoming(saved);
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not send the file.');
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final target = scrollController.position.maxScrollExtent;
      jump
          ? scrollController.jumpTo(target)
          : scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
    });
  }

  @override
  void onClose() {
    if (NotificationCenter.to.activeChatRoom == room.roomId) {
      NotificationCenter.to.activeChatRoom = null;
    }
    _closed = true;
    _reconnectTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
