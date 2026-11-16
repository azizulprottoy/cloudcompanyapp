import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/formatters.dart';

/// A unit of work assigned to a team member (server `tasks` collection).
class TaskModel {
  TaskModel({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.subDepartment,
    required this.hours,
    required this.credit,
    required this.status,
    required this.assigneeId,
    required this.assigneeName,
    required this.acceptedAt,
    required this.createdAt,
    required this.timeRanOut,
    required this.moreTimeRequested,
    required this.feedback,
    required this.orderId,
    required this.raw,
  });

  final String id;
  final String name;
  final String description;
  final String department;
  final String subDepartment;
  final num hours;
  final num credit;

  /// draft | not activated | pending | Accepted | VerifyTask | Completed | Done
  final String status;
  final String assigneeId;
  final String assigneeName;
  final dynamic acceptedAt;
  final dynamic createdAt;
  final bool timeRanOut;
  final bool moreTimeRequested;
  final String feedback;
  final String orderId;
  final Map<String, dynamic> raw;

  bool get isUnassigned => assigneeId.isEmpty || assigneeId == 'NA';

  /// When an accepted task is due (accepted time + estimated hours).
  DateTime? get dueAt {
    final start = Formatters.parseDate(acceptedAt);
    if (start == null || hours <= 0) return null;
    return start.add(Duration(minutes: (hours * 60).round()));
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: idOf(json['_id']),
    name: (json['tname'] ?? 'Task').toString(),
    description: (json['tdesc'] ?? '').toString(),
    department: (json['rdep'] ?? '').toString(),
    subDepartment: (json['rsubdep'] ?? '').toString(),
    hours: num.tryParse(json['ttime']?.toString() ?? '') ?? 0,
    credit: num.tryParse(json['tcc']?.toString() ?? '') ?? 0,
    status: (json['tstatus'] ?? 'pending').toString(),
    assigneeId: (json['taptr'] ?? '').toString(),
    assigneeName: (json['apname'] ?? '').toString(),
    acceptedAt: json['tat'],
    createdAt: json['tmt'],
    timeRanOut: json['timeranout'] == true,
    moreTimeRequested: json['tmoretime'] == true,
    feedback: (json['tfeedback'] ?? '').toString(),
    orderId: idOf(json['orderId']),
    raw: json,
  );
}

class TaskStatusStyle {
  const TaskStatusStyle(this.label, this.color);
  final String label;
  final Color color;

  static TaskStatusStyle of(String status) => switch (status) {
    'pending' => const TaskStatusStyle('Open', AppColors.warning),
    'Accepted' => const TaskStatusStyle('In progress', AppColors.primary),
    'VerifyTask' => const TaskStatusStyle('Waiting review', AppColors.info),
    'Completed' => const TaskStatusStyle('Approved', AppColors.success),
    'Done' => const TaskStatusStyle('Done', AppColors.success),
    'not activated' => const TaskStatusStyle('Not started', AppColors.textHint),
    'draft' => const TaskStatusStyle('Draft', AppColors.textHint),
    _ => TaskStatusStyle(status, AppColors.textSecondary),
  };
}
