import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/package_controllers.dart';

class PackageDetailsPage extends GetView<PackageDetailsController> {
  const PackageDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.package.value;
      if (p == null) {
        return Scaffold(
          appBar: AppBar(),
          body: controller.error.isNotEmpty
              ? ErrorView(
                  message: controller.error.value,
                  onRetry: controller.load,
                )
              : const ShimmerList(count: 4, itemHeight: 120),
        );
      }
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              flexibleSpace: FlexibleSpaceBar(
                background: AppNetworkImage(
                  url: p.cover,
                  fallbackIcon: Icons.inventory_2_outlined,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList.list(
                children: [
                  Text(
                    p.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.metaDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p.metaDescription,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Fact(
                        icon: Icons.payments_outlined,
                        label: 'Price',
                        value: Formatters.taka(p.price),
                      ),
                      const SizedBox(width: 10),
                      _Fact(
                        icon: Icons.schedule,
                        label: 'Delivery',
                        value: '${p.deliveryDays} days',
                      ),
                      if (p.hasExpress) ...[
                        const SizedBox(width: 10),
                        _Fact(
                          icon: Icons.bolt,
                          label: 'Express',
                          value: '${p.expressDays} days',
                        ),
                      ],
                    ],
                  ),
                  if (p.contents.isNotEmpty) ...[
                    const _Heading("What's included"),
                    for (final c in p.contents)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(c)),
                          ],
                        ),
                      ),
                  ],
                  if (p.detailsHtml.isNotEmpty) ...[
                    const _Heading('Details'),
                    Html(
                      data: p.detailsHtml,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          lineHeight: const LineHeight(1.5),
                        ),
                      },
                      onLinkTap: (url, _, _) {
                        if (url != null) {
                          launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ],
                  if (p.requirements.isNotEmpty) ...[
                    const _Heading('What we need from you'),
                    Text(Formatters.plain(p.requirements)),
                  ],
                  if (p.faqs.isNotEmpty) ...[
                    const _Heading('Questions'),
                    for (final f in p.faqs)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          f.question,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        expandedAlignment: Alignment.topLeft,
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
                ],
              ),
            ),
          ],
        ),
        bottomSheet: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.taka(p.price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.order,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Order now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}
