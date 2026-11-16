import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Non-sensitive app state (signed-in role, cached profile, preferences).
class LocalStorageService extends GetxService {
  static LocalStorageService get to => Get.find();

  late final GetStorage _box;

  static const keyRole = 'user_role';
  static const keyUser = 'user_json';

  Future<LocalStorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  void write(String key, dynamic value) => _box.write(key, value);
  T? read<T>(String key) => _box.read<T>(key);
  void remove(String key) => _box.remove(key);
  Future<void> clearAll() => _box.erase();
}
