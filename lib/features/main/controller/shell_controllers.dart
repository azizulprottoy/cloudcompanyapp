import 'package:get/get.dart';

import '../../packages/controller/package_controllers.dart';

class ShellController extends GetxController {
  final index = 0.obs;
  void select(int i) => index.value = i;
}

/// Client shell: Home · Packages · Projects · Blog · Account.
class ClientShellController extends ShellController {
  static ClientShellController get to => Get.find();

  static const packagesTab = 1;

  /// Jump to the Packages tab, optionally filtered to a category.
  void openPackages({String category = ''}) {
    Get.find<PackagesController>().showCategory(category);
    select(packagesTab);
  }
}

/// Team shell: Tasks · Account.
class EmployeeShellController extends ShellController {}

/// Admin shell: Dashboard · Orders · Tasks · Account.
class AdminShellController extends ShellController {}
