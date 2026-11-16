import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_services.dart';

/// The three kinds of account the app supports. Each gets its own home shell.
enum UserRole {
  client,
  employee,
  admin;

  String get label => switch (this) {
    UserRole.client => 'Client',
    UserRole.employee => 'Team',
    UserRole.admin => 'Admin',
  };

  static UserRole? fromName(String? name) =>
      UserRole.values.firstWhereOrNull((r) => r.name == name);
}

/// Who is signed in. Login responses differ per role, so the useful fields are
/// normalised here: [id], [name], [email], [photo].
class SessionUser {
  SessionUser(this.raw);

  final Map<String, dynamic> raw;

  String get id => (raw['id'] ?? raw['_id'] ?? raw['userId'] ?? '').toString();
  String get name => (raw['rname'] ?? raw['name'] ?? '').toString();
  String get email => (raw['remail'] ?? raw['email'] ?? '').toString();
  String get photo => (raw['rppic'] ?? raw['dp'] ?? '').toString();
  String get country => (raw['country'] ?? '').toString();

  /// Employee role on the server: "emp" or "marketer".
  String get staffRole => (raw['role'] ?? '').toString();
}

class SessionService extends GetxService {
  static SessionService get to => Get.find();

  final role = Rxn<UserRole>();
  final user = Rxn<SessionUser>();

  bool get isSignedIn => role.value != null && user.value != null;
  SessionUser get current => user.value!;

  Future<SessionService> init() async {
    final token = await SecureStorageService.to.getToken();
    final storedRole = UserRole.fromName(
      LocalStorageService.to.read<String>(LocalStorageService.keyRole),
    );
    final storedUser = LocalStorageService.to.read<Map>(
      LocalStorageService.keyUser,
    );
    if (token != null &&
        token.isNotEmpty &&
        storedRole != null &&
        storedUser != null) {
      role.value = storedRole;
      user.value = SessionUser(Map<String, dynamic>.from(storedUser));
    }
    return this;
  }

  Future<void> start({
    required UserRole role,
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await SecureStorageService.to.saveToken(token);
    LocalStorageService.to.write(LocalStorageService.keyRole, role.name);
    LocalStorageService.to.write(LocalStorageService.keyUser, user);
    this.role.value = role;
    this.user.value = SessionUser(user);
  }

  /// Merge fresh profile fields (after an edit) into the stored user.
  void updateUser(Map<String, dynamic> fields) {
    final merged = {...?user.value?.raw, ...fields};
    LocalStorageService.to.write(LocalStorageService.keyUser, merged);
    user.value = SessionUser(merged);
  }

  /// Signed-out users land on the public client shell (home/packages/blog),
  /// same as the website — login is only required to buy a package.
  String get homeRoute => switch (role.value) {
    UserRole.client => AppRoutes.clientShell,
    UserRole.employee => AppRoutes.employeeShell,
    UserRole.admin => AppRoutes.adminShell,
    null => AppRoutes.clientShell,
  };

  Future<void> logout() async {
    await SecureStorageService.to.clearAll();
    LocalStorageService.to.remove(LocalStorageService.keyRole);
    LocalStorageService.to.remove(LocalStorageService.keyUser);
    role.value = null;
    user.value = null;
    Get.offAllNamed(AppRoutes.clientShell);
  }

  bool _expiring = false;

  /// Called by the API client on a 401 for a signed-in request.
  Future<void> expire() async {
    if (_expiring || !isSignedIn) return;
    _expiring = true;
    await logout();
    AppServices.showInfo('Your session has expired. Please log in again.');
    _expiring = false;
  }
}
