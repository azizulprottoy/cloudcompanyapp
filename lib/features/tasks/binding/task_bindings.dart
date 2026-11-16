import 'package:get/get.dart';

import '../controller/task_controllers.dart';
import '../repository/task_repository.dart';

class TaskDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskRepository>(() => TaskRepository(), fenix: true);
    Get.lazyPut(() => TaskDetailsController(repository: Get.find<TaskRepository>()));
  }
}
