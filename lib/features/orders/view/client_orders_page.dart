import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/state_views.dart';
import '../controller/order_controllers.dart';
import 'widgets/order_card.dart';

/// Client "My Projects" tab.
class ClientOrdersPage extends GetView<ClientOrdersController> {
  const ClientOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My projects')),
      body: Obx(
        () => AsyncBody(
          isLoading: controller.isLoading.value,
          error: controller.error.value,
          isEmpty: controller.orders.isEmpty,
          onRefresh: controller.load,
          emptyTitle: 'No projects yet',
          emptyMessage: 'Order a package and track its progress here.',
          emptyIcon: Icons.work_outline,
          builder: (_) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => OrderCard(
              order: controller.orders[i],
              onReturn: controller.load,
            ),
          ),
        ),
      ),
    );
  }
}
