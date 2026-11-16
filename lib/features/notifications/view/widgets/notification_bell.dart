import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../controller/notification_center.dart';

/// Bell with the unread count; opens the notification list.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = NotificationCenter.to.unread.value;
      return IconButton(
        tooltip: 'Notifications',
        color: color,
        onPressed: () => Get.toNamed(AppRoutes.notifications),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(
            count > 0 ? Icons.notifications : Icons.notifications_none,
          ),
        ),
      );
    });
  }
}
