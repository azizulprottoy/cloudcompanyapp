import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../controller/order_controllers.dart';
import '../model/order_model.dart';

/// Project details for clients and admins. Admins also get status and payment controls.
class OrderDetailsPage extends GetView<OrderDetailsController> {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project')),
      body: Obx(() {
        final o = controller.order.value;
        if (o == null) {
          return controller.error.isNotEmpty
              ? ErrorView(
                  message: controller.error.value,
                  onRetry: controller.load,
                )
              : const ShimmerList(count: 4);
        }
        final status = StatusStyle.order(o.status);
        final payment = StatusStyle.payment(o);
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(
                o.displayTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                o.packageName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusChip(label: status.label, color: status.color),
                  StatusChip(label: payment.label, color: payment.color),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _Row('Price', Formatters.taka(o.price.round())),
                      if (o.deliveryDays.isNotEmpty)
                        _Row('Delivery', '${o.deliveryDays} days'),
                      _Row('Ordered', Formatters.dateTime(o.createdAt)),
                      if (o.raw['transactionId'] != null)
                        _Row(
                          'Transaction',
                          '${o.raw['paymentMethod'] ?? ''} · ${o.raw['transactionId']}',
                        ),
                    ],
                  ),
                ),
              ),
              if (controller.isAdmin) ...[
                const SizedBox(height: 12),
                _ClientCard(order: o),
                const SizedBox(height: 12),
                _AdminControls(controller: controller, order: o),
              ],
              if (o.steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${o.doneSteps} of ${o.steps.length} done',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: o.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in o.steps)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    enabled: !controller.isSaving.value,
                    onTap: controller.isAdmin
                        ? () => controller.toggleStep(s)
                        : null,
                    leading: Icon(
                      s.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: s.isDone ? AppColors.success : AppColors.textHint,
                    ),
                    title: Text(s.name),
                  ),
              ],
              if (o.brief.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Brief',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.plain(o.brief),
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final o = controller.order.value;
        if (o == null) return const SizedBox.shrink();
        final canPay =
            !controller.isAdmin &&
            !o.isPaid &&
            o.paymentReview.isEmpty &&
            !o.isCustom;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                if (canPay) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: controller.pay,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pay now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.openChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      controller.isAdmin
                          ? 'Chat with client'
                          : 'Chat with team',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: AppNetworkImage(
        url: order.buyerPhoto,
        width: 40,
        height: 40,
        radius: 20,
        fallbackIcon: Icons.person,
      ),
      title: Text(order.buyerName.isEmpty ? 'Client' : order.buyerName),
      subtitle: Text(order.buyerEmail),
      trailing: order.buyerEmail.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () =>
                  launchUrl(Uri(scheme: 'mailto', path: order.buyerEmail)),
            ),
    ),
  );
}

class _AdminControls extends StatelessWidget {
  const _AdminControls({required this.controller, required this.order});
  final OrderDetailsController controller;
  final OrderModel order;

  static const _statuses = ['pending', 'started', 'completed', 'rejected'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Obx(() {
          final busy = controller.isSaving.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Project status',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in _statuses)
                    ChoiceChip(
                      label: Text(StatusStyle.order(s).label),
                      selected: order.status == s,
                      onSelected: busy ? null : (_) => controller.setStatus(s),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : controller.togglePaid,
                  icon: Icon(
                    order.isPaid ? Icons.money_off : Icons.verified_outlined,
                  ),
                  label: Text(
                    order.isPaid
                        ? 'Mark as unpaid'
                        : 'Confirm payment (mark paid)',
                  ),
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        }),
      ),
    );
  }
}
