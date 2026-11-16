import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controller/package_controllers.dart';

class CheckoutPage extends GetView<CheckoutController> {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.package;
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(p.category),
                  trailing: Text(
                    Formatters.taka(p.price),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Project title',
                  hintText: 'e.g. Website for my bakery',
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Give your project a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.briefController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Project brief',
                  alignLabelWithHint: true,
                  hintText: p.requirements.isNotEmpty
                      ? Formatters.plain(p.requirements)
                      : 'Tell us what you need, your goals, colours, examples you like…',
                  hintMaxLines: 4,
                ),
                validator: (v) => (v ?? '').trim().length < 10
                    ? 'Describe your project in a few words'
                    : null,
              ),
              const SizedBox(height: 12),
              if (p.hasExpress)
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: controller.express.value,
                    onChanged: (v) => controller.express.value = v,
                    title: Text('Express delivery (${p.expressDays} days)'),
                    subtitle: Text('+ ${Formatters.taka(p.expressPrice)}'),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Coupon code',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: controller.applyCoupon,
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: controller.pickFiles,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add images'),
                  ),
                ],
              ),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in controller.attachments)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              f,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => controller.removeFile(f),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _Line('Package', Formatters.taka(p.price)),
                        if (controller.express.value)
                          _Line(
                            'Express delivery',
                            Formatters.taka(p.expressPrice),
                          ),
                        if (controller.discount > 0)
                          _Line(
                            'Coupon ${controller.appliedCoupon.value!.code}',
                            '− ${Formatters.taka(controller.discount.round())}',
                          ),
                        const Divider(height: 20),
                        _Line(
                          'Total',
                          Formatters.taka(controller.total.round()),
                          bold: true,
                        ),
                        _Line('Delivery', '${controller.days} days'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submit,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Place order'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be asked for payment details on the next screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
