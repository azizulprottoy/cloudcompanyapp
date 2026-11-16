import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/error/api_error.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_services.dart';
import '../../chat/model/chat_models.dart';
import '../../tasks/model/task_model.dart';
import '../model/app_notification.dart';
import '../repository/notification_repository.dart';

/// App-wide notification state: the list, the unread badge, and opening a
/// notification (from the list or from a tapped push).
///
/// Signed-in users get their own list from the server (read state kept there).
/// Signed-out users see public announcements; "unread" for them means newer
/// than the last time they opened the list, kept on the device.
class NotificationCenter extends GetxService {
  NotificationCenter({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository();

  static NotificationCenter get to => Get.find();

  static const _keyPublicSeenAt = 'public_notifications_seen_at';

  final NotificationRepository _repository;

  final items = <AppNotification>[].obs;
  final unread = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final error = ''.obs;

  /// Chat room on screen right now; its pushes aren't shown in the foreground.
  String? activeChatRoom;

  bool get _signedIn => SessionService.to.isSignedIn;

  @override
  void onInit() {
    super.onInit();
    // A different account (or none) has a different list.
    ever(SessionService.to.role, (_) {
      items.clear();
      hasMore.value = false;
      unread.value = 0;
      refreshUnread();
    });
    refreshUnread();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final page = _signedIn
          ? await _repository.mine()
          : await _repository.public();
      items.assignAll(page.items);
      hasMore.value = page.hasMore;
      unread.value = _signedIn ? page.unread : _publicUnread(page.items);
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_signedIn || !hasMore.value || isLoadingMore.value || items.isEmpty) {
      return;
    }
    isLoadingMore.value = true;
    try {
      final page = await _repository.mine(before: items.last.createdAt);
      items.addAll(page.items);
      hasMore.value = page.hasMore;
    } catch (_) {
      // Keep what's shown; scrolling again retries.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshUnread() async {
    try {
      if (_signedIn) {
        unread.value = await _repository.unreadCount();
      } else {
        unread.value = _publicUnread((await _repository.public()).items);
      }
    } catch (_) {
      // The badge is best effort.
    }
  }

  /// A push arrived while the app is open.
  void onPush(Map<String, String> data) {
    if (data['type'] == 'chat' && data['roomId'] == activeChatRoom) return;
    unread.value++;
    if (items.isNotEmpty) load();
  }

  /// Signed-out users: opening the list counts as reading everything in it.
  void markPublicSeen() {
    if (_signedIn) return;
    LocalStorageService.to.write(
      _keyPublicSeenAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    unread.value = 0;
  }

  int _publicUnread(List<AppNotification> list) {
    final seen = DateTime.tryParse(
      LocalStorageService.to.read<String>(_keyPublicSeenAt) ?? '',
    );
    return list
        .where((n) => seen == null || (n.createdAt?.isAfter(seen) ?? false))
        .length;
  }

  Future<void> markAllRead() async {
    if (!_signedIn) return markPublicSeen();
    final before = items.toList();
    items.assignAll(items.map((n) => n.copyWith(read: true)));
    unread.value = 0;
    try {
      await _repository.markAllRead();
    } catch (e) {
      items.assignAll(before);
      refreshUnread();
      AppServices.showApiError(e);
    }
  }

  Future<void> remove(AppNotification n) async {
    final index = items.indexWhere((i) => i.id == n.id);
    if (index == -1) return;
    items.removeAt(index);
    if (!n.read && unread.value > 0) unread.value--;
    try {
      await _repository.remove(n.id);
    } catch (e) {
      items.insert(index, n);
      refreshUnread();
      AppServices.showApiError(e);
    }
  }

  /// Tap on a list row: mark it read, then go where it points.
  Future<void> open(AppNotification n) async {
    if (!n.read && _signedIn) {
      final index = items.indexWhere((i) => i.id == n.id);
      if (index != -1) items[index] = n.copyWith(read: true);
      if (unread.value > 0) unread.value--;
      _repository.markRead(n.id).catchError((_) {});
    }
    await openData({...n.data, 'type': n.type}, fromList: true);
  }

  /// Opens the screen a notification points to. [data] is the push payload
  /// or a list row's data plus its type.
  Future<void> openData(
    Map<String, String> data, {
    bool fromList = false,
  }) async {
    final session = SessionService.to;
    final role = session.role.value;
    final type = data['type'];

    if (type == 'chat' && session.isSignedIn) {
      final room = _chatRoom(data);
      if (room != null) {
        Get.toNamed(AppRoutes.chat, arguments: room);
        return;
      }
    }

    final orderId = data['orderId'] ?? '';
    if (type == 'order' && orderId.isNotEmpty) {
      if (role == UserRole.client) {
        Get.toNamed(AppRoutes.clientOrderDetails, arguments: orderId);
        return;
      }
      if (role == UserRole.admin) {
        Get.toNamed(AppRoutes.adminOrderDetails, arguments: orderId);
        return;
      }
    }

    final taskId = data['taskId'] ?? '';
    if (type == 'task' &&
        taskId.isNotEmpty &&
        (role == UserRole.employee || role == UserRole.admin)) {
      try {
        final task = TaskModel.fromJson(await _repository.task(taskId));
        Get.toNamed(
          role == UserRole.admin
              ? AppRoutes.adminTaskDetails
              : AppRoutes.taskDetails,
          arguments: task,
        );
      } catch (e) {
        AppServices.showApiError(
          e,
          fallback: 'This task is no longer available.',
        );
      }
      return;
    }

    final link = _externalLink(data['url']);
    if (link != null) {
      await launchUrl(link, mode: LaunchMode.externalApplication);
      return;
    }

    if (!fromList && Get.currentRoute != AppRoutes.notifications) {
      Get.toNamed(AppRoutes.notifications);
    }
  }

  ChatRoom? _chatRoom(Map<String, String> data) {
    final kind = switch (data['chatKind']) {
      'order' => ChatKind.order,
      'task' => ChatKind.task,
      _ => null,
    };
    final roomId = data['roomId'] ?? '';
    if (kind == null || roomId.isEmpty) return null;

    final me = SessionService.to.current;
    final role = SessionService.to.role.value;
    final isAdmin = role == UserRole.admin;
    // Clients only have order chats and team members only task chats.
    if (role == UserRole.client && kind != ChatKind.order) return null;
    if (role == UserRole.employee && kind != ChatKind.task) return null;

    final participantName = isAdmin ? (data['participantName'] ?? '') : me.name;
    return ChatRoom(
      kind: kind,
      roomId: roomId,
      title: isAdmin && participantName.isNotEmpty
          ? participantName
          : (kind == ChatKind.order ? 'Project chat' : 'Task chat'),
      mySender: isAdmin
          ? 'manager'
          : (kind == ChatKind.order ? 'client' : 'emp'),
      participantId: isAdmin ? (data['participantId'] ?? '') : me.id,
      participantName: participantName,
      myUserId: me.id,
    );
  }

  /// Links meant for the browser. Profile paths ("/clientprofile/...") are the
  /// website's version of screens the app already has, so they're skipped.
  Uri? _externalLink(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('https://') || url.startsWith('http://')) {
      return Uri.tryParse(url);
    }
    final isProfilePath = RegExp(
      r'^/(clientprofile|employeeprofile|marketerprofile)/',
    ).hasMatch(url);
    if (url.startsWith('/') && !url.startsWith('//') && !isProfilePath) {
      return Uri.tryParse('${AppConstants.siteUrl}$url');
    }
    return null;
  }
}
