import 'package:get/get.dart';

import '../controller/order_controllers.dart';
import '../repository/order_repository.dart';

class OrderDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    Get.lazyPut(() => OrderDetailsController(repository: Get.find<OrderRepository>()));
  }
}
