import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/app_constants.dart';
import '../model/chat_models.dart';

/// Live events from the chat socket.
sealed class ChatEvent {}

class ChatMessageEvent extends ChatEvent {
  ChatMessageEvent(this.message);
  final ChatMessage message;
}

class ChatReadEvent extends ChatEvent {
  /// Messages from this sender were read by the other side.
  ChatReadEvent(this.sender);
  final String sender;
}

class ChatRepository extends BaseRepository {
  ChatRepository({super.dio});

  Future<List<ChatMessage>> history(ChatRoom room) async {
    final path = room.kind == ChatKind.order
        ? ApiEndpoints.orderChat(room.roomId)
        : ApiEndpoints.taskChat(room.roomId);
    final res = await dio.get(path);
    return asList(res.data).map(ChatMessage.fromJson).toList();
  }

  Map<String, dynamic> _fields(ChatRoom room, String text, String time) =>
      room.kind == ChatKind.order
      ? {
          'orderId': room.roomId,
          'bId': room.participantId,
          'bName': room.participantName,
          'text': text,
          'time': time,
          'sender': room.mySender,
        }
      : {
          'taskId': room.roomId,
          'empId': room.participantId,
          'empName': room.participantName,
          'text': text,
          'time': time,
          'sender': room.mySender,
        };

  /// Saves the message; the server also broadcasts it to everyone in the room.
  Future<ChatMessage> send(ChatRoom room, String text) async {
    final time = DateTime.now().toUtc().toIso8601String();
    final path = room.kind == ChatKind.order
        ? ApiEndpoints.sendOrderChat
        : ApiEndpoints.sendTaskChat;
    final res = await dio.post(path, data: _fields(room, text, time));
    return ChatMessage.fromJson(asMap(res.data));
  }

  Future<ChatMessage> sendFiles(
    ChatRoom room,
    List<File> files, {
    String text = '',
  }) async {
    final time = DateTime.now().toUtc().toIso8601String();
    // The room id must come before the files: the server picks the upload
    // folder from it while the files are still streaming in.
    final form = FormData();
    _fields(
      room,
      text,
      time,
    ).forEach((k, v) => form.fields.add(MapEntry(k, v.toString())));
    for (final f in files) {
      form.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    final path = room.kind == ChatKind.order
        ? ApiEndpoints.sendOrderChatFiles
        : ApiEndpoints.sendTaskChatFiles;
    final res = await dio.post(path, data: form);
    return ChatMessage.fromJson(asMap(res.data));
  }

  /// Marks the other side's messages as read.
  Future<void> markRead(ChatRoom room) async {
    final path = room.kind == ChatKind.order
        ? ApiEndpoints.markOrderChatRead(room.roomId)
        : ApiEndpoints.markTaskChatRead(room.roomId);
    await dio.post(path, data: {'sender': room.otherSender});
  }

  /// Opens the room socket. The server first sends the whole history as an
  /// array (ignored: history comes from REST), then one object per event.
  WebSocketChannel connect(ChatRoom room) {
    final key = room.kind == ChatKind.order ? 'orderId' : 'taskId';
    final base = Uri.parse(AppConstants.wsUrl);
    final uri = base.replace(
      path: base.path.isEmpty ? '/' : base.path,
      queryParameters: {
        key: room.roomId,
        if (room.myUserId.isNotEmpty) 'userId': room.myUserId,
      },
    );
    return WebSocketChannel.connect(uri);
  }

  ChatEvent? parse(dynamic raw) {
    try {
      final data = jsonDecode(
        raw is String ? raw : utf8.decode(raw as List<int>),
      );
      if (data is! Map) return null; // initial history array
      final map = Map<String, dynamic>.from(data);
      if (map['type'] == 'read_update') {
        return ChatReadEvent((map['sender'] ?? '').toString());
      }
      if (map['text'] == null && map['attachments'] == null) return null;
      return ChatMessageEvent(ChatMessage.fromJson(map));
    } catch (_) {
      return null;
    }
  }
}
