import 'package:get/get.dart';

import '../controller/blog_controllers.dart';
import '../repository/blog_repository.dart';

class BlogDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlogRepository>(() => BlogRepository(), fenix: true);
    Get.lazyPut(() => BlogDetailsController(repository: Get.find<BlogRepository>()));
  }
}
