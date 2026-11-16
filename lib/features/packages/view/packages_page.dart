import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/state_views.dart';
import '../controller/package_controllers.dart';
import 'widgets/package_card.dart';

/// Client "Packages" tab.
class PackagesPage extends GetView<PackagesController> {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: const InputDecoration(
                hintText: 'Search packages',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Obx(() {
            final cats = controller.categories;
            if (cats.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  for (final c in ['', ...cats])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.isEmpty ? 'All' : c),
                        selected: controller.category.value == c,
                        onSelected: (_) => controller.showCategory(c),
                      ),
                    ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              final items = controller.visible;
              return AsyncBody(
                isLoading: controller.isLoading.value,
                error: controller.error.value,
                isEmpty: items.isEmpty,
                onRefresh: controller.load,
                emptyTitle: 'No packages found',
                emptyIcon: Icons.inventory_2_outlined,
                builder: (_) => LayoutBuilder(
                  builder: (context, c) {
                    final columns = c.maxWidth > 900
                        ? 3
                        : (c.maxWidth > 560 ? 2 : 1);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent:
                            (c.maxWidth - 32 - (columns - 1) * 12) /
                                columns *
                                9 /
                                16 +
                            116,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => PackageCard(package: items[i]),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
