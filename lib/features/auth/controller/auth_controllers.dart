import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/session_service.dart';
import '../../../core/utils/app_services.dart';
import '../repository/auth_repository.dart';

class LoginController extends GetxController {
  LoginController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final obscure = true.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] is String) {
      emailController.text = args['email'];
    }
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    try {
      final result = await _repository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await SessionService.to.start(
        role: result.role,
        token: result.token,
        user: result.user,
      );
      Get.offAllNamed(SessionService.to.homeRoute);
    } catch (e) {
      AppServices.showApiError(
        e,
        fallback: 'Login failed. Check your email and password.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class SignupController extends GetxController {
  SignupController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  static const accountTypes = ['Personal', 'Business', 'Agency'];

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final countryController = TextEditingController(text: 'Bangladesh');
  final accountType = 'Personal'.obs;
  final isLoading = false.obs;
  final obscure = true.obs;

  Future<void> signup() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      await _repository.signupClient(
        name: nameController.text.trim(),
        email: email,
        phone: phoneController.text.trim(),
        password: password,
        country: countryController.text.trim(),
        accountType: accountType.value,
      );
      // Sign straight in so the new client lands on their home.
      final result = await _repository.login(email: email, password: password);
      await SessionService.to.start(
        role: UserRole.client,
        token: result.token,
        user: result.user,
      );
      Get.offAllNamed(SessionService.to.homeRoute);
      AppServices.showSuccess('Welcome to Cloud Company!');
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not create your account.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [
      nameController,
      emailController,
      phoneController,
      passwordController,
      countryController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}

enum ResetStep { email, code, password }

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();

  final step = ResetStep.email.obs;
  final isEmployee = false.obs;
  final isLoading = false.obs;
  String _resetToken = '';

  String get _userType => isEmployee.value ? 'employee' : 'client';

  Future<void> next() async {
    isLoading.value = true;
    try {
      switch (step.value) {
        case ResetStep.email:
          if (!GetUtils.isEmail(emailController.text.trim())) {
            throw Exception('Enter a valid email address.');
          }
          await _repository.sendResetOtp(
            email: emailController.text.trim(),
            userType: _userType,
          );
          step.value = ResetStep.code;
          AppServices.showInfo('We sent a 6-digit code to your email.');
        case ResetStep.code:
          _resetToken = await _repository.verifyResetOtp(
            email: emailController.text.trim(),
            userType: _userType,
            otp: otpController.text.trim(),
          );
          step.value = ResetStep.password;
        case ResetStep.password:
          if (passwordController.text.length < 6) {
            throw Exception('Use at least 6 characters.');
          }
          await _repository.resetPassword(
            email: emailController.text.trim(),
            userType: _userType,
            resetToken: _resetToken,
            newPassword: passwordController.text,
          );
          Get.back();
          AppServices.showSuccess('Password changed. You can log in now.');
      }
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
