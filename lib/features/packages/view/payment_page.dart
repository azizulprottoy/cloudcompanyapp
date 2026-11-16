import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_services.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/package_controllers.dart';

class PaymentPage extends GetView<PaymentController> {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Obx(() {
        if (controller.isLoading.value) return const ShimmerList(count: 3);
        if (controller.error.isNotEmpty) {
          return ErrorView(
            message: controller.error.value,
            onRetry: controller.load,
          );
        }
        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.ink,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.title,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.taka(controller.amount.round()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Amount to pay',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Send the money to one of these accounts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (controller.methods.isEmpty)
                const Text(
                  'No payment methods are set up yet. Contact us to pay.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              RadioGroup<String>(
                groupValue: controller.selected.value?.method,
                onChanged: (v) => controller.selected.value = controller.methods
                    .firstWhereOrNull((m) => m.method == v),
                child: Column(
                  children: [
                    for (final m in controller.methods)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: RadioListTile<String>(
                            value: m.method,
                            title: Text(
                              m.method,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: m.number.isEmpty ? null : Text(m.number),
                            secondary: m.number.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Copy number',
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: m.number),
                                      );
                                      AppServices.showInfo('Number copied');
                                    },
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '2. Enter your payment details',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.senderController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Number you paid from',
                ),
                validator: (v) => (v ?? '').trim().length < 6
                    ? 'Enter the sending number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.trxController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Transaction ID'),
                validator: (v) => (v ?? '').trim().length < 4
                    ? 'Enter the transaction ID'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.submit,
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit payment'),
              ),
              TextButton(
                onPressed: controller.payLater,
                child: const Text('Pay later'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
