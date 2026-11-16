import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../../main/controller/shell_controllers.dart';
import '../../packages/view/widgets/package_card.dart';
import '../controller/home_controller.dart';

/// Client "Home" tab.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = SessionService.to.user.value?.name.split(' ').first ?? '';
    return Scaffold(
      body: Obx(() {
        final d = controller.data.value;
        if (d == null) {
          return SafeArea(
            child: controller.error.isNotEmpty
                ? ErrorView(
                    message: controller.error.value,
                    onRetry: controller.load,
                  )
                : const ShimmerList(count: 5, itemHeight: 120),
          );
        }
        final categories = d.packages.map((p) => p.category).toSet().toList();
        return RefreshIndicator(
          onRefresh: controller.load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Hero(name: name)),
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Browse by category',
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final c in categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(c),
                                onPressed: () => ClientShellController.to
                                    .openPackages(category: c),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (d.packages.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Popular packages',
                    action: TextButton(
                      onPressed: () => ClientShellController.to.openPackages(),
                      child: const Text('See all'),
                    ),
                    child: SizedBox(
                      height: 272,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: d.packages.length.clamp(0, 8),
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) =>
                            PackageCard(package: d.packages[i], width: 260),
                      ),
                    ),
                  ),
                ),
              if (d.services.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'What we do',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (final s in d.services)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      url: s.image,
                                      width: 96,
                                      height: 96,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              s.description,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (d.faqs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Questions',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Column(
                          children: [
                            for (final f in d.faqs)
                              ExpansionTile(
                                title: Text(
                                  f.question,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                expandedAlignment: Alignment.topLeft,
                                shape: const Border(),
                                children: [
                                  Text(
                                    f.answer,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: _Contact()),
            ],
          ),
        );
      }),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050D1F), Color(0xFF0D1B3E), Color(0xFF091528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo_white.png', height: 36),
              const Spacer(),
              Obx(
                () => SessionService.to.isSignedIn
                    ? const SizedBox.shrink()
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.login),
                        child: const Text('Sign in'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name.isEmpty ? 'Welcome' : 'Hi $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Websites, apps, design and marketing — fixed prices, clear timelines.',
            style: TextStyle(color: Color(0xFFBFDBFE)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => ClientShellController.to.openPackages(),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Browse packages'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ?action,
            ],
          ),
        ),
        child,
      ],
    ),
  );
}

class _Contact extends StatelessWidget {
  const _Contact();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
    child: Card(
      color: AppColors.primaryLight.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need something custom?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('Talk to us and we will put together the right plan.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://wa.me/${AppConstants.whatsappNumber}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => launchUrl(
                    Uri(scheme: 'mailto', path: AppConstants.supportEmail),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
