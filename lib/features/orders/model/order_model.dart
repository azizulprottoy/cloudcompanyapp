import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/network/base_repository.dart';

class OrderStep {
  OrderStep({required this.id, required this.name, required this.isDone});
  final dynamic id;
  final String name;
  final bool isDone;
}

/// A project: either a package order or a custom request (`orderType`).
class OrderModel {
  OrderModel({
    required this.id,
    required this.title,
    required this.packageName,
    required this.brief,
    required this.price,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paymentReview,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhoto,
    required this.deliveryDays,
    required this.steps,
    required this.createdAt,
    required this.isCustom,
    required this.raw,
  });

  final String id;
  final String title;
  final String packageName;
  final String brief;
  final num price;
  final String currency;
  final String status; // pending | started | completed | rejected
  final String paymentStatus; // paid | notpaid
  final String
  paymentReview; // e.g. "Pending Verification" after the client submits a payment
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhoto;
  final String deliveryDays;
  final List<OrderStep> steps;
  final dynamic createdAt;
  final bool isCustom;
  final Map<String, dynamic> raw;

  bool get isPaid => paymentStatus == 'paid';
  int get doneSteps => steps.where((s) => s.isDone).length;
  double get progress => steps.isEmpty ? 0 : doneSteps / steps.length;
  String get displayTitle => title.isNotEmpty ? title : packageName;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['packageContents'];
    final steps = <OrderStep>[];
    if (rawSteps is List) {
      for (final s in rawSteps) {
        if (s is Map) {
          steps.add(
            OrderStep(
              id: s['id'],
              name: (s['name'] ?? '').toString(),
              isDone: s['isDone'] == true,
            ),
          );
        } else if (s != null) {
          steps.add(OrderStep(id: s, name: s.toString(), isDone: false));
        }
      }
    }
    return OrderModel(
      id: idOf(json['_id']),
      title: (json['projectTitle'] ?? '').toString(),
      packageName: (json['packageName'] ?? 'Custom project').toString(),
      brief: (json['projectBrief'] ?? json['description'] ?? '').toString(),
      price: num.tryParse(json['sellPrice']?.toString() ?? '') ?? 0,
      currency: (json['currency'] ?? 'BDT').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      paymentStatus: (json['pstatus'] ?? 'notpaid').toString().toLowerCase(),
      paymentReview: (json['paymentStatus'] ?? '').toString(),
      buyerId: (json['buyerid'] ?? '').toString(),
      buyerName: (json['buyername'] ?? '').toString(),
      buyerEmail: (json['email'] ?? '').toString(),
      buyerPhoto: (json['bdp'] ?? '').toString(),
      deliveryDays: (json['time'] ?? json['deliveryDeadline'] ?? '').toString(),
      steps: steps,
      createdAt: json['createdAt'],
      isCustom: json['orderType'] == 'custom',
      raw: json,
    );
  }
}

/// Colour + label for an order/project status chip.
class StatusStyle {
  const StatusStyle(this.label, this.color);
  final String label;
  final Color color;

  static StatusStyle order(String status) => switch (status) {
    'started' => const StatusStyle('In progress', AppColors.primary),
    'completed' => const StatusStyle('Completed', AppColors.success),
    'rejected' ||
    'cancelled' => const StatusStyle('Cancelled', AppColors.error),
    _ => const StatusStyle('Pending', AppColors.warning),
  };

  static StatusStyle payment(OrderModel o) {
    if (o.isPaid) return const StatusStyle('Paid', AppColors.success);
    if (o.paymentReview.isNotEmpty) {
      return const StatusStyle('Payment in review', AppColors.primary);
    }
    return const StatusStyle('Unpaid', AppColors.textSecondary);
  }
}
