import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/session_service.dart';
import '../../../core/utils/app_services.dart';
import '../repository/profile_repository.dart';

/// "Account" tab for every role.
class ProfileController extends GetxController {
  ProfileController({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  final profile = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  UserRole get role => SessionService.to.role.value!;
  SessionUser get user => SessionService.to.current;

  String field(String key) => (profile[key] ?? user.raw[key] ?? '').toString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (role == UserRole.admin) return;
    isLoading.value = true;
    try {
      final data = await _repository.load(role, user.id);
      profile.assignAll(data);
      SessionService.to.updateUser({
        if (data['rname'] != null) 'rname': data['rname'],
        if (data['rppic'] != null) 'rppic': data['rppic'],
        if (data['country'] != null) 'country': data['country'],
      });
    } catch (_) {
      // The tab still shows the login data.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final ok = await AppServices.confirm(
      title: 'Log out?',
      message: 'You can log back in any time.',
      confirmText: 'Log out',
    );
    if (ok) await SessionService.to.logout();
  }
}

class EditProfileController extends GetxController {
  EditProfileController({ProfileRepository? repository, ImagePicker? picker})
    : _repository = repository ?? ProfileRepository(),
      _picker = picker ?? ImagePicker();

  final ProfileRepository _repository;
  final ImagePicker _picker;

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  final photo = Rxn<File>();
  final isSaving = false.obs;

  SessionUser get user => SessionService.to.current;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments)
        : <String, dynamic>{};
    nameController = TextEditingController(
      text: (args['rname'] ?? user.name).toString(),
    );
    phoneController = TextEditingController(
      text: (args['rphone'] ?? '').toString(),
    );
  }

  Future<void> pickPhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1000,
    );
    if (x != null) photo.value = File(x.path);
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSaving.value = true;
    try {
      final role = SessionService.to.role.value!;
      final url = await _repository.update(
        role,
        user.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        photo: photo.value,
      );
      SessionService.to.updateUser({
        'rname': nameController.text.trim(),
        if (url != null && url.isNotEmpty) 'rppic': url,
      });
      Get.back(result: true);
      AppServices.showSuccess('Profile updated.');
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not save your profile.');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
