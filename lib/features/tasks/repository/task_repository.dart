import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../model/task_model.dart';

class EmployeeTasksResult {
  EmployeeTasksResult({required this.tasks, required this.isReady});
  final List<TaskModel> tasks;
  final bool isReady;
}

class TaskRepository extends BaseRepository {
  TaskRepository({super.dio});

  /// The member's own tasks plus, when they are "ready", open tasks in their department.
  Future<EmployeeTasksResult> employeeTasks(String employeeId) async {
    final res = await dio.get(ApiEndpoints.employeeTasks(employeeId));
    final body = res.data is Map
        ? Map<String, dynamic>.from(res.data)
        : <String, dynamic>{};
    final employee = body['employee'] is Map
        ? body['employee'] as Map
        : const {};
    return EmployeeTasksResult(
      tasks: asList(body, key: 'tasks').map(TaskModel.fromJson).toList(),
      isReady: employee['isReady'] == true,
    );
  }

  Future<bool> setReady(String employeeId, bool ready) async {
    final res = await dio.patch(
      ApiEndpoints.employeeReady(employeeId),
      data: {'isReady': ready},
    );
    final body = res.data;
    return body is Map && body['isReady'] is bool
        ? body['isReady'] as bool
        : ready;
  }

  Future<void> accept(
    String taskId, {
    required String employeeId,
    String name = '',
    String photo = '',
  }) async {
    await dio.put(
      ApiEndpoints.acceptTask(taskId),
      data: {'taptr': employeeId, 'apname': name, 'apdp': photo},
    );
  }

  /// Sends an accepted task for admin review.
  Future<void> submit(String taskId) async =>
      dio.put(ApiEndpoints.submitTask(taskId));

  Future<void> requestMoreTime(String taskId) async =>
      dio.put(ApiEndpoints.requestMoreTime(taskId), data: {'tmoretime': true});

  /// Final note after the admin approved the work; moves the task to Done.
  Future<void> feedback(String taskId, String text) async =>
      dio.put(ApiEndpoints.taskFeedback(taskId), data: {'tfeedback': text});

  // ── Admin ───────────────────────────────────────────────────────────────────

  Future<List<TaskModel>> allTasks() async {
    final res = await dio.get(ApiEndpoints.allTasks);
    return asList(res.data).map(TaskModel.fromJson).toList();
  }

  Future<void> verify(String taskId, {required bool approve}) async {
    await dio.put(
      ApiEndpoints.verifyTask(taskId),
      data: {'action': approve ? 'approve' : 'reject'},
    );
  }
}
