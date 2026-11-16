import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../model/app_notification.dart';

class NotificationPage {
  NotificationPage(this.items, {this.hasMore = false, this.unread = 0});
  final List<AppNotification> items;
  final bool hasMore;
  final int unread;
}

class NotificationRepository extends BaseRepository {
  NotificationRepository({super.dio});

  /// The signed-in user's list, newest first. [before] pages back.
  Future<NotificationPage> mine({DateTime? before, int limit = 20}) async {
    final res = await dio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before.toUtc().toIso8601String(),
      },
    );
    final body = res.data is Map ? res.data as Map : const {};
    return NotificationPage(
      asList(body, key: 'items').map(AppNotification.fromJson).toList(),
      hasMore: body['hasMore'] == true,
      unread: int.tryParse('${body['unread'] ?? 0}') ?? 0,
    );
  }

  /// Public announcements, for signed-out users.
  Future<NotificationPage> public() async {
    final res = await dio.get(ApiEndpoints.publicNotifications);
    return NotificationPage(
      asList(res.data, key: 'items').map(AppNotification.fromJson).toList(),
    );
  }

  Future<int> unreadCount() async {
    final res = await dio.get(ApiEndpoints.unreadNotifications);
    return int.tryParse('${(res.data as Map?)?['unread'] ?? 0}') ?? 0;
  }

  Future<void> markRead(String id) =>
      dio.patch(ApiEndpoints.readNotification(id));

  Future<void> markAllRead() => dio.patch(ApiEndpoints.readAllNotifications);

  Future<void> remove(String id) => dio.delete(ApiEndpoints.notification(id));

  /// Admin: announcement to an audience ('public', 'clients', 'employees',
  /// 'admins').
  Future<void> broadcast({
    required String title,
    required String body,
    required String audience,
    String? url,
  }) => dio.post(
    ApiEndpoints.adminNotifications,
    data: {
      'title': title,
      'body': body,
      'audience': audience,
      if (url != null && url.isNotEmpty) 'url': url,
    },
  );

  /// Admin: announcements sent so far.
  Future<List<AppNotification>> sent() async {
    final res = await dio.get(ApiEndpoints.adminNotifications);
    return asList(
      res.data,
      key: 'items',
    ).map(AppNotification.fromJson).toList();
  }

  Future<void> registerDevice({
    required String token,
    required String platform,
  }) => dio.post(
    ApiEndpoints.deviceToken,
    data: {'token': token, 'platform': platform},
  );

  Future<void> unregisterDevice({
    required String token,
    required String platform,
  }) => dio.delete(
    ApiEndpoints.deviceToken,
    data: {'token': token, 'platform': platform},
  );

  Future<Map<String, dynamic>> task(String id) async =>
      asMap((await dio.get(ApiEndpoints.task(id))).data);
}
