import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../controller/profile_controllers.dart';

/// "Account" tab for every role.
class AccountPage extends GetView<ProfileController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Obx(() {
              final u = SessionService.to.user.value;
              if (u == null) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AppNetworkImage(
                        url: u.photo,
                        width: 64,
                        height: 64,
                        radius: 32,
                        fallbackIcon: Icons.person,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name.isEmpty ? 'Your account' : u.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              u.email,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roleLabel(controller.role, u),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final role = controller.role;
              final rows = <(String, String)>[
                if (controller.field('rphone').isNotEmpty)
                  ('Phone', controller.field('rphone')),
                if (controller.field('country').isNotEmpty)
                  ('Country', controller.field('country')),
                if (role == UserRole.client &&
                    controller.field('atype').isNotEmpty)
                  ('Account type', controller.field('atype')),
                if (role == UserRole.employee &&
                    controller.field('rdep').isNotEmpty)
                  (
                    'Department',
                    [
                      controller.field('rdep'),
                      controller.field('rsubdep'),
                    ].where((e) => e.isNotEmpty).join(' › '),
                  ),
                if (role == UserRole.employee &&
                    controller.field('esprts').isNotEmpty)
                  ('Skills', controller.field('esprts')),
              ];
              if (rows.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Column(
                  children: [
                    for (final r in rows)
                      ListTile(
                        dense: true,
                        title: Text(r.$1),
                        trailing: Text(r.$2),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  if (controller.role != UserRole.admin)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final changed = await Get.toNamed(
                          AppRoutes.editProfile,
                          arguments: Map<String, dynamic>.from(
                            controller.profile,
                          ),
                        );
                        if (changed == true) controller.load();
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.chat_outlined),
                    title: const Text('WhatsApp support'),
                    onTap: () => launchUrl(
                      Uri.parse('https://wa.me/${AppConstants.whatsappNumber}'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Email support'),
                    subtitle: const Text(AppConstants.supportEmail),
                    onTap: () => launchUrl(
                      Uri(scheme: 'mailto', path: AppConstants.supportEmail),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Visit website'),
                    onTap: () => launchUrl(
                      Uri.parse(AppConstants.siteUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy policy'),
                    onTap: () => launchUrl(
                      Uri.parse('${AppConstants.siteUrl}/privacypolicy'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: controller.logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role, SessionUser u) => switch (role) {
    UserRole.client => 'Client',
    UserRole.admin => 'Admin',
    UserRole.employee =>
      u.staffRole == 'marketer' ? 'Marketing team' : 'Team member',
  };
}
