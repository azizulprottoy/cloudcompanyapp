import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/notification_center.dart';
import '../model/app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _center = NotificationCenter.to;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _center.load().then((_) => _center.markPublicSeen());
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) _center.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(
            () => session.isSignedIn && _center.unread.value > 0
                ? TextButton(
                    onPressed: _center.markAllRead,
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => session.role.value == UserRole.admin
                ? IconButton(
                    tooltip: 'Send announcement',
                    icon: const Icon(Icons.campaign_outlined),
                    onPressed: () => Get.toNamed(AppRoutes.sendNotification),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(
        () => AsyncBody(
          isLoading: _center.isLoading.value,
          error: _center.error.value,
          isEmpty: _center.items.isEmpty,
          onRefresh: _center.load,
          emptyIcon: Icons.notifications_none,
          emptyTitle: 'No notifications yet',
          emptyMessage: session.isSignedIn
              ? 'Messages, project and task updates and announcements show up here.'
              : 'Announcements from Cloud Company show up here. Sign in for updates on your projects.',
          builder: (_) => ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _center.items.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              if (i == _center.items.length) {
                return Obx(
                  () => _center.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox(height: 24),
                );
              }
              final n = _center.items[i];
              final tile = _NotificationTile(
                notification: n,
                onTap: () => _center.open(n),
              );
              // Broadcasts are shared, so only personal ones can be removed.
              if (!session.isSignedIn || n.isBroadcast) return tile;
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _center.remove(n),
                child: tile,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.read && SessionService.to.isSignedIn;
    return Material(
      color: unread ? AppColors.primaryLight.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Icon(n.icon, size: 20, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (n.count > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${n.count} new',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (n.isBroadcast) 'Announcement',
                        _ago(n.createdAt),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return Formatters.date(at);
  }
}
