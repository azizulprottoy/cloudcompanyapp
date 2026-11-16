import 'package:get/get.dart';

import '../../../core/error/api_error.dart';
import '../repository/home_repository.dart';

/// Client "Home" tab.
class HomeController extends GetxController {
  HomeController({HomeRepository? repository})
    : _repository = repository ?? HomeRepository();

  final HomeRepository _repository;

  final data = Rxn<HomeData>();
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      data.value = await _repository.load();
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
