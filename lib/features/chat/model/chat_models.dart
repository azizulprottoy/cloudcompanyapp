import '../../../core/network/base_repository.dart';
import '../../../core/utils/media_url.dart';

enum ChatKind { order, task }

/// Which conversation to open and who "I" am in it. Passed as the route argument.
///
/// Order chats are client ↔ admin ("client" / "manager" senders); task chats
/// are team member ↔ admin ("emp" / "manager").
class ChatRoom {
  ChatRoom({
    required this.kind,
    required this.roomId,
    required this.title,
    required this.mySender,
    required this.participantId,
    required this.participantName,
    this.myUserId = '',
  });

  final ChatKind kind;

  /// orderId or taskId.
  final String roomId;
  final String title;

  /// "client", "emp" or "manager".
  final String mySender;

  /// The client (order chat) or team member (task chat) the conversation belongs
  /// to. The server files every message under this person, whoever sends it.
  final String participantId;
  final String participantName;

  /// Tags this socket for online detection (skip offline email/push when present).
  final String myUserId;

  String get otherSender => mySender == 'manager'
      ? (kind == ChatKind.order ? 'client' : 'emp')
      : 'manager';
}

class ChatAttachment {
  ChatAttachment({
    required this.url,
    required this.name,
    required this.mimeType,
  });
  final String url;
  final String name;
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
    url: MediaUrl.resolve(json['url']?.toString()) ?? '',
    name: (json['originalName'] ?? json['filename'] ?? 'file').toString(),
    mimeType: (json['mimetype'] ?? '').toString(),
  );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    required this.read,
    required this.attachments,
  });

  final String id;
  final String text;
  final String sender;
  final String time;
  bool read;
  final List<ChatAttachment> attachments;

  /// Server dedupe key, used to recognise our own message coming back over the socket.
  String get key => '$sender|$text|$time';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: idOf(json['_id']),
    text: (json['text'] ?? '').toString(),
    sender: (json['sender'] ?? '').toString(),
    time: (json['time'] ?? json['createdAt'] ?? '').toString(),
    read: json['read'] == true,
    attachments:
        (json['attachments'] is List ? json['attachments'] as List : const [])
            .whereType<Map>()
            .map((a) => ChatAttachment.fromJson(Map<String, dynamic>.from(a)))
            .where((a) => a.url.isNotEmpty)
            .toList(),
  );
}
