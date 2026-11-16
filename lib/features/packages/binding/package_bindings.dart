import 'package:get/get.dart';

import '../controller/package_controllers.dart';
import '../repository/package_repository.dart';

class PackageDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackageRepository>(() => PackageRepository(), fenix: true);
    Get.lazyPut(() => PackageDetailsController(repository: Get.find<PackageRepository>()));
  }
}

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackageRepository>(() => PackageRepository(), fenix: true);
    Get.lazyPut(() => CheckoutController(repository: Get.find<PackageRepository>()));
  }
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackageRepository>(() => PackageRepository(), fenix: true);
    Get.lazyPut(() => PaymentController(repository: Get.find<PackageRepository>()));
  }
}
