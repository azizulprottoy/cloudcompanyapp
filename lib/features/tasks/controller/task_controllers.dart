import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/error/api_error.dart';
import '../../../core/utils/app_services.dart';
import '../../chat/model/chat_models.dart';
import '../model/task_model.dart';
import '../repository/task_repository.dart';

/// Team "Tasks" tab.
class EmployeeTasksController extends GetxController {
  EmployeeTasksController({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  final tasks = <TaskModel>[].obs;
  final isReady = false.obs;
  final isLoading = false.obs;
  final isTogglingReady = false.obs;
  final error = ''.obs;

  String get _me => SessionService.to.current.id;

  /// Mine first (in progress, then waiting review, then approved), then open pool.
  List<TaskModel> get mine =>
      tasks.where((t) => t.assigneeId == _me).toList()
        ..sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));
  List<TaskModel> get open =>
      tasks.where((t) => t.isUnassigned && t.status == 'pending').toList();

  int _rank(String s) => switch (s) {
    'Accepted' => 0,
    'pending' => 1,
    'Completed' => 2,
    'VerifyTask' => 3,
    _ => 4,
  };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final result = await _repository.employeeTasks(_me);
      tasks.assignAll(result.tasks);
      isReady.value = result.isReady;
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleReady(bool value) async {
    isTogglingReady.value = true;
    try {
      isReady.value = await _repository.setReady(_me, value);
      await load();
      AppServices.showInfo(
        value
            ? 'You will see open tasks in your department.'
            : 'Open tasks hidden.',
      );
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isTogglingReady.value = false;
    }
  }
}

/// One task, opened by a team member or an admin.
class TaskDetailsController extends GetxController {
  TaskDetailsController({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  final task = Rxn<TaskModel>();
  final isBusy = false.obs;
  final now = DateTime.now().obs;
  final feedbackController = TextEditingController();
  Timer? _ticker;

  bool get isAdmin => SessionService.to.role.value == UserRole.admin;
  String get _me => SessionService.to.current.id;

  bool get canAccept => !isAdmin && task.value?.status == 'pending';
  bool get isMineInProgress =>
      !isAdmin &&
      task.value?.status == 'Accepted' &&
      task.value?.assigneeId == _me;
  bool get canGiveFeedback => !isAdmin && task.value?.status == 'Completed';
  bool get canVerify => isAdmin && task.value?.status == 'VerifyTask';
  bool get canChat =>
      (task.value?.assigneeId.isNotEmpty ?? false) &&
      task.value?.assigneeId != 'NA';

  @override
  void onInit() {
    super.onInit();
    task.value = Get.arguments as TaskModel;
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => now.value = DateTime.now(),
    );
  }

  Future<void> _run(
    Future<void> Function() action,
    String success, {
    String? nextStatus,
  }) async {
    isBusy.value = true;
    try {
      await action();
      if (nextStatus != null) {
        final t = task.value!;
        task.value = TaskModel.fromJson({
          ...t.raw,
          'tstatus': nextStatus,
          if (nextStatus == 'Accepted') ...{
            'taptr': _me,
            'apname': SessionService.to.current.name,
            'tat': DateTime.now().toUtc().toIso8601String(),
          },
        });
      }
      AppServices.showSuccess(success);
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> accept() async {
    final t = task.value!;
    final me = SessionService.to.current;
    final ok = await AppServices.confirm(
      title: 'Accept this task?',
      message: 'The timer starts now: you have ${t.hours} hours to finish it.',
      confirmText: 'Accept',
    );
    if (!ok) return;
    await _run(
      () => _repository.accept(
        t.id,
        employeeId: me.id,
        name: me.name,
        photo: me.photo,
      ),
      'Task accepted. Good luck!',
      nextStatus: 'Accepted',
    );
  }

  Future<void> submit() async {
    final ok = await AppServices.confirm(
      title: 'Submit for review?',
      message: 'An admin will check your work and approve or send it back.',
      confirmText: 'Submit',
    );
    if (!ok) return;
    await _run(
      () => _repository.submit(task.value!.id),
      'Sent for review.',
      nextStatus: 'VerifyTask',
    );
  }

  Future<void> requestMoreTime() async {
    await _run(
      () => _repository.requestMoreTime(task.value!.id),
      'More time requested.',
    );
    final t = task.value!;
    task.value = TaskModel.fromJson({...t.raw, 'tmoretime': true});
  }

  Future<void> sendFeedback() async {
    final text = feedbackController.text.trim();
    if (text.isEmpty) {
      AppServices.showError('Write a short note first.');
      return;
    }
    await _run(
      () => _repository.feedback(task.value!.id, text),
      'Thanks! Task closed.',
      nextStatus: 'Done',
    );
  }

  Future<void> verify(bool approve) async {
    final ok = await AppServices.confirm(
      title: approve ? 'Approve this work?' : 'Send back for changes?',
      message: approve
          ? 'The task is marked approved and the next task in the project starts.'
          : 'The team member gets the task back to keep working on it.',
      confirmText: approve ? 'Approve' : 'Send back',
      destructive: !approve,
    );
    if (!ok) return;
    await _run(
      () => _repository.verify(task.value!.id, approve: approve),
      approve ? 'Approved.' : 'Sent back.',
      nextStatus: approve ? 'Completed' : 'Accepted',
    );
  }

  void openChat() {
    final t = task.value!;
    final me = SessionService.to.current;
    Get.toNamed(
      AppRoutes.chat,
      arguments: ChatRoom(
        kind: ChatKind.task,
        roomId: t.id,
        title: isAdmin ? '${t.assigneeName} · ${t.name}' : t.name,
        mySender: isAdmin ? 'manager' : 'emp',
        participantId: isAdmin ? t.assigneeId : me.id,
        participantName: isAdmin ? t.assigneeName : me.name,
        myUserId: me.id,
      ),
    );
  }

  @override
  void onClose() {
    _ticker?.cancel();
    feedbackController.dispose();
    super.onClose();
  }
}

/// Admin "Tasks" tab.
class AdminTasksController extends GetxController {
  AdminTasksController({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  static const filters = [
    'VerifyTask',
    'Accepted',
    'pending',
    'Completed',
    'Done',
    'all',
  ];

  final tasks = <TaskModel>[].obs;
  final filter = 'VerifyTask'.obs;
  final isLoading = false.obs;
  final error = ''.obs;

  List<TaskModel> get visible => filter.value == 'all'
      ? tasks
      : tasks.where((t) => t.status == filter.value).toList();

  int count(String f) =>
      f == 'all' ? tasks.length : tasks.where((t) => t.status == f).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      tasks.assignAll(await _repository.allTasks());
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
