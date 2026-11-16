import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/state_views.dart';
import '../controller/order_controllers.dart';
import 'widgets/order_card.dart';

/// Admin "Orders" tab.
class AdminOrdersPage extends GetView<AdminOrdersController> {
  const AdminOrdersPage({super.key});

  static const _labels = {
    'all': 'All',
    'pending': 'Pending',
    'started': 'In progress',
    'completed': 'Completed',
    'unpaid': 'Unpaid',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: const InputDecoration(
                hintText: 'Search client, project or package',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  for (final f in AdminOrdersController.filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${_labels[f]} (${controller.count(f)})'),
                        selected: controller.filter.value == f,
                        onSelected: (_) => controller.filter.value = f,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.visible;
              return AsyncBody(
                isLoading: controller.isLoading.value,
                error: controller.error.value,
                isEmpty: items.isEmpty,
                onRefresh: controller.load,
                emptyTitle: 'No orders',
                emptyIcon: Icons.receipt_long_outlined,
                builder: (_) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => OrderCard(
                    order: items[i],
                    showBuyer: true,
                    onReturn: controller.load,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
