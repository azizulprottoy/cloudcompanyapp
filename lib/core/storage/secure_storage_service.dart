import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../network/api_client.dart';

/// Keychain / Keystore storage for the session token. The token is never
/// written to plain storage.
class SecureStorageService extends GetxService {
  static SecureStorageService get to => Get.find();

  late final FlutterSecureStorage _storage;

  static const _keyToken = 'auth_token';

  Future<SecureStorageService> init() async {
    _storage = const FlutterSecureStorage();
    return this;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
    ApiClient.clearCachedToken();
  }

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> clearAll() async {
    await _storage.deleteAll();
    ApiClient.clearCachedToken();
  }
}
