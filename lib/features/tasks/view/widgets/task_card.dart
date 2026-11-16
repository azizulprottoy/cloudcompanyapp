import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../model/task_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.showAssignee = false,
    this.onReturn,
  });

  final TaskModel task;
  final bool showAssignee;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final s = TaskStatusStyle.of(task.status);
    final due = task.status == 'Accepted' ? task.dueAt : null;
    final overdue = due != null && DateTime.now().isAfter(due);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Get.toNamed(
            showAssignee ? AppRoutes.adminTaskDetails : AppRoutes.taskDetails,
            arguments: task,
          );
          onReturn?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: s.label, color: s.color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (showAssignee)
                    task.isUnassigned ? 'Unassigned' : task.assigneeName,
                  [
                    task.department,
                    task.subDepartment,
                  ].where((e) => e.isNotEmpty).join(' › '),
                ].where((e) => e.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.hours} h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.stars_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.credit} credits',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (overdue || task.timeRanOut)
                    const StatusChip(label: 'Overdue', color: AppColors.error)
                  else if (task.moreTimeRequested)
                    const StatusChip(
                      label: 'More time asked',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
