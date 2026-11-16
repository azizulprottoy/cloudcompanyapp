import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/blog_controllers.dart';

/// Client "Blog" tab.
class BlogListPage extends GetView<BlogListController> {
  const BlogListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: Obx(
        () => AsyncBody(
          isLoading: controller.isLoading.value,
          error: controller.error.value,
          isEmpty: controller.posts.isEmpty,
          onRefresh: controller.load,
          emptyTitle: 'No articles yet',
          emptyIcon: Icons.article_outlined,
          builder: (_) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final p = controller.posts[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.blogDetails, arguments: p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1200 / 630,
                        child: AppNetworkImage(
                          url: p.cover,
                          fallbackIcon: Icons.article_outlined,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.summary,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${p.author} · ${Formatters.date(p.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
