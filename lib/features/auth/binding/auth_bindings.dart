import 'package:get/get.dart';

import '../controller/auth_controllers.dart';
import '../repository/auth_repository.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => LoginController(repository: Get.find<AuthRepository>()));
  }
}

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => SignupController(repository: Get.find<AuthRepository>()));
  }
}

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => ForgotPasswordController(repository: Get.find<AuthRepository>()));
  }
}
