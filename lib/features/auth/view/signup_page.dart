import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_controllers.dart';

class SignupPage extends GetView<SignupController> {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Order packages, track your projects and chat with our team.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => GetUtils.isEmail(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v ?? '').trim().length < 6
                      ? 'Enter your phone number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.public),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter your country' : null,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.accountType.value,
                    decoration: const InputDecoration(
                      labelText: 'Account type',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: SignupController.accountTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        controller.accountType.value = v ?? 'Personal',
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    obscureText: controller.obscure.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscure.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.obscure.toggle,
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'Use at least 6 characters'
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.signup,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
