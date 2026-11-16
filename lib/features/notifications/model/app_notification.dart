import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

/// One row of the notification list (personal or broadcast).
///
/// [type] is 'chat', 'order', 'task', 'broadcast', 'campaign', 'personal' or
/// 'general'. [data] carries what tapping it should open (orderId, taskId,
/// roomId, url...), the same keys the push message has.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.count,
    required this.createdAt,
    this.audience,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool read;

  /// How many messages were merged into this row (busy chats).
  final int count;
  final DateTime? createdAt;
  final String? audience;

  bool get isBroadcast => type == 'broadcast';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? 'general').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: rawData is Map
          ? rawData.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : const {},
      read: json['read'] == true,
      count: int.tryParse('${json['count'] ?? 1}') ?? 1,
      createdAt: Formatters.parseDate(json['createdAt']),
      audience: json['audience']?.toString(),
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    read: read ?? this.read,
    count: count,
    createdAt: createdAt,
    audience: audience,
  );

  IconData get icon => switch (type) {
    'chat' => Icons.chat_bubble_outline,
    'order' => Icons.receipt_long_outlined,
    'task' => Icons.task_alt_outlined,
    'broadcast' => Icons.campaign_outlined,
    'campaign' || 'personal' => Icons.mark_email_unread_outlined,
    _ => Icons.notifications_none,
  };
}
