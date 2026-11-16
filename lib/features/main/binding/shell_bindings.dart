import 'package:get/get.dart';

import '../../../core/auth/session_service.dart';
import '../../blog/controller/blog_controllers.dart';
import '../../blog/repository/blog_repository.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../home/controller/home_controller.dart';
import '../../orders/controller/order_controllers.dart';
import '../../orders/repository/order_repository.dart';
import '../../packages/controller/package_controllers.dart';
import '../../packages/repository/package_repository.dart';
import '../../profile/controller/profile_controllers.dart';
import '../../tasks/controller/task_controllers.dart';
import '../../tasks/repository/task_repository.dart';
import '../controller/shell_controllers.dart';

/// Each shell registers the controllers of its tabs up front, like Kaj Ache's MainBinding.
class ClientShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackageRepository>(() => PackageRepository(), fenix: true);
    Get.lazyPut<BlogRepository>(() => BlogRepository(), fenix: true);
    Get.put(ClientShellController());
    Get.put(HomeController());
    Get.put(PackagesController(repository: Get.find<PackageRepository>()));
    Get.put(BlogListController(repository: Get.find<BlogRepository>()));
    // Orders/Account need a signed-in user — guests only see Home/Packages/Blog
    // (the shell swaps their tabs for a sign-in prompt instead of building these).
    if (SessionService.to.isSignedIn) {
      Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
      Get.put(ClientOrdersController(repository: Get.find<OrderRepository>()));
      Get.put(ProfileController());
    }
  }
}

class EmployeeShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskRepository>(() => TaskRepository(), fenix: true);
    Get.put(EmployeeShellController());
    Get.put(EmployeeTasksController(repository: Get.find<TaskRepository>()));
    Get.put(ProfileController());
  }
}

class AdminShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    Get.lazyPut<TaskRepository>(() => TaskRepository(), fenix: true);
    Get.put(AdminShellController());
    Get.put(DashboardController());
    Get.put(AdminOrdersController(repository: Get.find<OrderRepository>()));
    Get.put(AdminTasksController(repository: Get.find<TaskRepository>()));
    Get.put(ProfileController());
  }
}
