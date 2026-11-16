import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/error/api_error.dart';
import '../../../core/utils/app_services.dart';
import '../model/package_model.dart';
import '../repository/package_repository.dart';

/// Package catalogue with a category filter and search (client "Packages" tab).
class PackagesController extends GetxController {
  PackagesController({PackageRepository? repository})
    : _repository = repository ?? PackageRepository();

  final PackageRepository _repository;

  final all = <PackageModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final category = ''.obs; // '' = all
  final query = ''.obs;

  List<String> get categories => all.map((p) => p.category).toSet().toList();

  List<PackageModel> get visible {
    final q = query.value.trim().toLowerCase();
    return all.where((p) {
      if (category.value.isNotEmpty && p.category != category.value) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.contents.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      all.assignAll(await _repository.packages());
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void showCategory(String value) => category.value = value;
}

class PackageDetailsController extends GetxController {
  PackageDetailsController({PackageRepository? repository})
    : _repository = repository ?? PackageRepository();

  final PackageRepository _repository;

  final package = Rxn<PackageModel>();
  final isLoading = true.obs;
  final error = ''.obs;
  late final String _key;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is PackageModel) {
      package.value = arg; // show instantly, refresh below
      _key = arg.routeKey;
    } else {
      _key = arg.toString();
    }
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      package.value = await _repository.details(_key);
    } catch (e) {
      if (package.value == null) error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void order() {
    final p = package.value;
    if (p == null) return;
    Get.toNamed(AppRoutes.checkout, arguments: p);
  }
}

class CheckoutController extends GetxController {
  CheckoutController({PackageRepository? repository, ImagePicker? picker})
    : _repository = repository ?? PackageRepository(),
      _picker = picker ?? ImagePicker();

  final PackageRepository _repository;
  final ImagePicker _picker;

  late final PackageModel package;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final briefController = TextEditingController();
  final couponController = TextEditingController();

  final express = false.obs;
  final coupons = <CouponModel>[];
  final appliedCoupon = Rxn<CouponModel>();
  final attachments = <File>[].obs;
  final isSubmitting = false.obs;

  num get basePrice =>
      package.price + (express.value ? package.expressPrice : 0);
  num get discount => appliedCoupon.value == null
      ? 0
      : basePrice * appliedCoupon.value!.discountPercent / 100;
  num get total => (basePrice - discount).clamp(0, double.infinity);
  int get days => express.value ? package.expressDays : package.deliveryDays;

  @override
  void onInit() {
    super.onInit();
    package = Get.arguments as PackageModel;
    _repository.coupons(package.id).then(coupons.addAll).catchError((_) {});
  }

  void applyCoupon() {
    final code = couponController.text.trim().toLowerCase();
    if (code.isEmpty) {
      appliedCoupon.value = null;
      return;
    }
    final match = coupons.firstWhereOrNull((c) => c.code.toLowerCase() == code);
    if (match == null) {
      appliedCoupon.value = null;
      AppServices.showError('That coupon code is not valid.');
    } else {
      appliedCoupon.value = match;
      AppServices.showSuccess('Coupon applied: ${match.discountPercent}% off.');
    }
  }

  Future<void> pickFiles() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, limit: 10);
    attachments.addAll(picked.map((x) => File(x.path)));
  }

  void removeFile(File f) => attachments.remove(f);

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final user = SessionService.to.current;
    isSubmitting.value = true;
    try {
      final orderId = await _repository.placeOrder(
        package: package,
        projectTitle: titleController.text.trim(),
        projectBrief: briefController.text.trim(),
        finalPrice: total,
        coupon: appliedCoupon.value?.code ?? '',
        deliveryDays: days,
        buyerId: user.id,
        buyerName: user.name,
        buyerPhoto: user.photo,
        buyerEmail: user.email,
        country: user.country,
        attachments: attachments.toList(),
      );
      Get.offNamed(
        AppRoutes.payment,
        arguments: {'orderId': orderId, 'amount': total, 'title': package.name},
      );
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not place the order.');
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    briefController.dispose();
    couponController.dispose();
    super.onClose();
  }
}

/// Manual payment (bKash / Nagad / bank): the client pays, then submits the
/// transaction details for the team to verify.
class PaymentController extends GetxController {
  PaymentController({PackageRepository? repository})
    : _repository = repository ?? PackageRepository();

  final PackageRepository _repository;

  late final String orderId;
  late final num amount;
  late final String title;

  final methods = <PaymentMethod>[].obs;
  final selected = Rxn<PaymentMethod>();
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final error = ''.obs;

  final formKey = GlobalKey<FormState>();
  final senderController = TextEditingController();
  final trxController = TextEditingController();
  final referenceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    orderId = args['orderId'].toString();
    amount = args['amount'] as num? ?? 0;
    title = (args['title'] ?? 'Your order').toString();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      methods.assignAll(await _repository.paymentMethods());
      if (methods.isNotEmpty) selected.value = methods.first;
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submit() async {
    if (selected.value == null) {
      AppServices.showError('Choose a payment method.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    isSubmitting.value = true;
    try {
      await _repository.submitPayment(
        orderId: orderId,
        method: selected.value!.method,
        senderNumber: senderController.text.trim(),
        transactionId: trxController.text.trim(),
        reference: referenceController.text.trim(),
      );
      Get.back();
      AppServices.showSuccess('Payment submitted. We will confirm it shortly.');
    } catch (e) {
      AppServices.showApiError(e, fallback: 'Could not submit the payment.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void payLater() {
    Get.back();
    AppServices.showInfo(
      'Order placed. You can pay any time from My Projects.',
    );
  }

  @override
  void onClose() {
    senderController.dispose();
    trxController.dispose();
    referenceController.dispose();
    super.onClose();
  }
}
