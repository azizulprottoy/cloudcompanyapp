import 'package:get/get.dart';

import '../controller/profile_controllers.dart';
import '../repository/profile_repository.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);
    Get.lazyPut(() => EditProfileController(repository: Get.find<ProfileRepository>()));
  }
}
