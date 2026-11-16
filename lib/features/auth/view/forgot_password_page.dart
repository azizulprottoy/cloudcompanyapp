import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controller/auth_controllers.dart';

class ForgotPasswordPage extends GetView<ForgotPasswordController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is Map && args['employee'] == true) {
      controller.isEmployee.value = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            final step = controller.step.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(switch (step) {
                  ResetStep.email =>
                    'Enter the email you use to log in. We\'ll send you a 6-digit code.',
                  ResetStep.code =>
                    'Enter the code we emailed to ${controller.emailController.text.trim()}. It is valid for 10 minutes.',
                  ResetStep.password => 'Choose a new password.',
                }, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                if (step == ResetStep.email) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I am a team member'),
                    value: controller.isEmployee.value,
                    onChanged: (v) => controller.isEmployee.value = v,
                  ),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                ],
                if (step == ResetStep.code)
                  TextField(
                    controller: controller.otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                if (step == ResetStep.password)
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.next,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(switch (step) {
                          ResetStep.email => 'Send code',
                          ResetStep.code => 'Verify code',
                          ResetStep.password => 'Change password',
                        }),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
