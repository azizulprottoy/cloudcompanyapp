import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../model/order_model.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.showBuyer = false,
    this.onReturn,
  });

  final OrderModel order;
  final bool showBuyer;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final status = StatusStyle.order(order.status);
    final payment = StatusStyle.payment(order);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Get.toNamed(
            showBuyer
                ? AppRoutes.adminOrderDetails
                : AppRoutes.clientOrderDetails,
            arguments: order,
          );
          onReturn?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showBuyer) ...[
                    AppNetworkImage(
                      url: order.buyerPhoto,
                      width: 32,
                      height: 32,
                      radius: 16,
                      fallbackIcon: Icons.person,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          showBuyer
                              ? '${order.buyerName} · ${order.packageName}'
                              : order.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.taka(order.price.round()),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (order.steps.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: order.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusChip(label: status.label, color: status.color),
                  const SizedBox(width: 6),
                  StatusChip(label: payment.label, color: payment.color),
                  if (order.isCustom) ...[
                    const SizedBox(width: 6),
                    const StatusChip(label: 'Custom', color: AppColors.inkSoft),
                  ],
                  const Spacer(),
                  Text(
                    Formatters.date(order.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
