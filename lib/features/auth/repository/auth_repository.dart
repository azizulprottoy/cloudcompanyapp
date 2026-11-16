import 'package:dio/dio.dart';

import '../../../core/auth/session_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';

class LoginResult {
  LoginResult({required this.role, required this.token, required this.user});
  final UserRole role;
  final String token;
  final Map<String, dynamic> user;
}

class AuthRepository extends BaseRepository {
  AuthRepository({super.dio});

  // Marks login/signup calls so a 401 shows "wrong password" instead of
  // ending a session.
  static final _authCall = Options(extra: {'isAuthCall': true});

  /// Single endpoint for all account types — the server checks client, then
  /// employee, then admin and reports which one matched via `accountType`.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post(
      ApiEndpoints.login,
      data: {'remail': email, 'rpass': password},
      options: _authCall,
    );
    final body = asMap(res.data);
    final token = body['token']?.toString() ?? '';
    final user = body['user'] is Map
        ? Map<String, dynamic>.from(body['user'])
        : null;
    final role = UserRole.fromName(body['accountType']?.toString());
    if (token.isEmpty || user == null || role == null) {
      throw Exception(body['message']?.toString() ?? 'Login failed.');
    }
    return LoginResult(role: role, token: token, user: user);
  }

  /// Client sign-up. The server issues no token, so the caller logs in after.
  Future<void> signupClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String country,
    required String accountType,
  }) async {
    final res = await dio.post(
      ApiEndpoints.clientSignup,
      data: {
        'role': 'client',
        'rname': name,
        'remail': email,
        'rphone': phone,
        'rpass': password,
        'country': country,
        'atype': accountType,
      },
      options: _authCall,
    );
    if (!writeOk(res.data)) throw Exception('Could not create the account.');
  }

  /// [userType] is "client" or "employee" (admins reset through the web panel).
  Future<void> sendResetOtp({
    required String email,
    required String userType,
  }) async {
    await dio.post(
      ApiEndpoints.sendResetOtp,
      data: {'remail': email, 'userType': userType},
      options: _authCall,
    );
  }

  Future<String> verifyResetOtp({
    required String email,
    required String userType,
    required String otp,
  }) async {
    final res = await dio.post(
      ApiEndpoints.verifyResetOtp,
      data: {'remail': email, 'userType': userType, 'otp': otp},
      options: _authCall,
    );
    final token = asMap(res.data)['resetToken']?.toString() ?? '';
    if (token.isEmpty) throw Exception('Invalid or expired code.');
    return token;
  }

  Future<void> resetPassword({
    required String email,
    required String userType,
    required String resetToken,
    required String newPassword,
  }) async {
    await dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'remail': email,
        'userType': userType,
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
      options: _authCall,
    );
  }
}
