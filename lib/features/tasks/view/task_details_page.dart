import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_chip.dart';
import '../controller/task_controllers.dart';
import '../model/task_model.dart';

class TaskDetailsPage extends GetView<TaskDetailsController> {
  const TaskDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: Obx(() {
        final t = controller.task.value!;
        final s = TaskStatusStyle.of(t.status);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              t.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusChip(label: s.label, color: s.color),
                if (t.moreTimeRequested)
                  const StatusChip(
                    label: 'More time asked',
                    color: AppColors.warning,
                  ),
                if (t.timeRanOut)
                  const StatusChip(
                    label: 'Time ran out',
                    color: AppColors.error,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (t.status == 'Accepted' && t.dueAt != null)
              _Countdown(due: t.dueAt!, now: controller.now.value),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _Row(
                      'Department',
                      [
                        t.department,
                        t.subDepartment,
                      ].where((e) => e.isNotEmpty).join(' › '),
                    ),
                    _Row('Time allowed', '${t.hours} hours'),
                    _Row('Credits', '${t.credit}'),
                    if (!t.isUnassigned)
                      _Row(
                        'Assigned to',
                        t.assigneeName.isEmpty ? '—' : t.assigneeName,
                      ),
                    if (t.acceptedAt != null)
                      _Row('Accepted', Formatters.dateTime(t.acceptedAt)),
                    _Row('Created', Formatters.dateTime(t.createdAt)),
                  ],
                ),
              ),
            ),
            if (t.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Instructions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(
                Formatters.plain(t.description),
                style: const TextStyle(height: 1.5),
              ),
            ],
            if (t.feedback.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Final note',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(t.feedback),
            ],
            if (controller.canGiveFeedback) ...[
              const SizedBox(height: 20),
              const Text(
                'Your work was approved 🎉',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Leave a short note about how it went to close the task.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.feedbackController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'What did you deliver? Anything to note?',
                ),
              ),
            ],
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final busy = controller.isBusy.value;
        final t = controller.task.value!;
        final buttons = <Widget>[
          if (controller.canAccept)
            FilledButton.icon(
              onPressed: busy ? null : controller.accept,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Accept task'),
            ),
          if (controller.isMineInProgress) ...[
            if (!t.moreTimeRequested)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: busy ? null : controller.requestMoreTime,
                child: const Text('Need more time'),
              ),
            FilledButton.icon(
              onPressed: busy ? null : controller.submit,
              icon: const Icon(Icons.upload),
              label: const Text('Submit for review'),
            ),
          ],
          if (controller.canGiveFeedback)
            FilledButton(
              onPressed: busy ? null : controller.sendFeedback,
              child: const Text('Close task'),
            ),
          if (controller.canVerify) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.error,
              ),
              onPressed: busy ? null : () => controller.verify(false),
              child: const Text('Send back'),
            ),
            FilledButton(
              onPressed: busy ? null : () => controller.verify(true),
              child: const Text('Approve'),
            ),
          ],
          if (controller.canChat)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: controller.openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(controller.isAdmin ? 'Chat' : 'Chat with admin'),
            ),
        ];
        if (buttons.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: buttons[i]),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.due, required this.now});
  final DateTime due;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final left = due.difference(now);
    final overdue = left.isNegative;
    final d = left.abs();
    final text = '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    final color = overdue
        ? AppColors.error
        : (left.inHours < 2 ? AppColors.warning : AppColors.primary);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(overdue ? Icons.alarm_off : Icons.alarm, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              overdue
                  ? 'Overdue by $text'
                  : '$text left · due ${Formatters.time(due)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
