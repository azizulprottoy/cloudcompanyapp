import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/state_views.dart';
import '../controller/task_controllers.dart';
import '../model/task_model.dart';
import 'widgets/task_card.dart';

/// Admin "Tasks" tab. Opens on work waiting for review.
class AdminTasksPage extends GetView<AdminTasksController> {
  const AdminTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  for (final f in AdminTasksController.filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${f == 'all' ? 'All' : TaskStatusStyle.of(f).label} (${controller.count(f)})',
                        ),
                        selected: controller.filter.value == f,
                        onSelected: (_) => controller.filter.value = f,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.visible;
              return AsyncBody(
                isLoading: controller.isLoading.value,
                error: controller.error.value,
                isEmpty: items.isEmpty,
                onRefresh: controller.load,
                emptyTitle: 'Nothing here',
                emptyIcon: Icons.task_alt,
                builder: (_) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => TaskCard(
                    task: items[i],
                    showAssignee: true,
                    onReturn: controller.load,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
