import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/task_controllers.dart';
import 'widgets/task_card.dart';
import '../../notifications/view/widgets/notification_bell.dart';

/// Team "Tasks" tab.
class EmployeeTasksPage extends GetView<EmployeeTasksController> {
  const EmployeeTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        actions: const [NotificationBell()],
      ),
      body: Column(
        children: [
          Obx(
            () => SwitchListTile(
              tileColor: AppColors.surface,
              title: const Text('Ready for new work'),
              subtitle: const Text('Show open tasks in your department'),
              value: controller.isReady.value,
              onChanged: controller.isTogglingReady.value
                  ? null
                  : controller.toggleReady,
            ),
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              final mine = controller.mine;
              final open = controller.open;
              return AsyncBody(
                isLoading: controller.isLoading.value,
                error: controller.error.value,
                isEmpty: mine.isEmpty && open.isEmpty,
                onRefresh: controller.load,
                emptyTitle: 'No tasks right now',
                emptyMessage: controller.isReady.value
                    ? 'New tasks in your department will show up here.'
                    : 'Turn on "Ready for new work" to see open tasks.',
                emptyIcon: Icons.task_alt,
                builder: (_) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (mine.isNotEmpty) ...[
                      const _Section('Assigned to me'),
                      for (final t in mine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TaskCard(task: t, onReturn: controller.load),
                        ),
                    ],
                    if (open.isNotEmpty) ...[
                      const _Section('Open in your department'),
                      for (final t in open)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TaskCard(task: t, onReturn: controller.load),
                        ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
