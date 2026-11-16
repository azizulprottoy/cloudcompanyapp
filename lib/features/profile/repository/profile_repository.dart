import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/auth/session_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository({super.dio});

  /// Fresh profile document for clients and team members. Admin accounts have
  /// no profile endpoint, so the login data is used.
  Future<Map<String, dynamic>> load(UserRole role, String id) async {
    final path = switch (role) {
      UserRole.client => ApiEndpoints.clientProfile(id),
      UserRole.employee => ApiEndpoints.employeeProfile(id),
      UserRole.admin => null,
    };
    if (path == null) return {};
    final res = await dio.get(path);
    final profile = asMap(res.data);
    // The server returns the stored password with the profile; never keep it.
    profile.remove('rpass');
    return profile;
  }

  /// Updates name/phone and optionally the photo. Returns the new photo URL, if any.
  Future<String?> update(
    UserRole role,
    String id, {
    required String name,
    required String phone,
    File? photo,
  }) async {
    final path = role == UserRole.client
        ? ApiEndpoints.updateClientProfile(id)
        : ApiEndpoints.updateEmployeeProfile(id);
    final form = FormData.fromMap({
      'rname': name,
      'rphone': phone,
      if (photo != null)
        'dp': await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split(Platform.pathSeparator).last,
        ),
    });
    final res = await dio.put(path, data: form);
    final body = res.data;
    if (body is Map) {
      final url =
          body['dpPath'] ??
          (body['updatedFields'] is Map
              ? body['updatedFields']['rppic']
              : null);
      return url?.toString();
    }
    return null;
  }
}
