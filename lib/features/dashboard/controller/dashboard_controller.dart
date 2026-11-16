import 'package:get/get.dart';

import '../../../core/error/api_error.dart';
import '../repository/dashboard_repository.dart';

/// Admin "Dashboard" tab.
class DashboardController extends GetxController {
  DashboardController({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository();

  final DashboardRepository _repository;

  final data = Rxn<DashboardData>();
  final year = DateTime.now().year.obs;
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
      data.value = await _repository.load(year.value);
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void changeYear(int delta) {
    year.value += delta;
    load();
  }
}
