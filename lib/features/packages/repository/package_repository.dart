import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../model/package_model.dart';

class PaymentMethod {
  PaymentMethod({
    required this.method,
    required this.number,
    required this.raw,
  });
  final String method;
  final String number;
  final Map<String, dynamic> raw;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    method: (json['method'] ?? json['name'] ?? 'Payment').toString(),
    number: (json['number'] ?? json['account'] ?? '').toString(),
    raw: json,
  );
}

class PackageRepository extends BaseRepository {
  PackageRepository({super.dio});

  Future<List<PackageModel>> packages() async {
    final res = await dio.get(ApiEndpoints.packages);
    return asList(res.data)
        .map(PackageModel.fromJson)
        .where((p) => p.status.isEmpty || p.status == 'approved')
        .toList();
  }

  /// [key] is a slug or id.
  Future<PackageModel> details(String key) async {
    final res = await dio.get(ApiEndpoints.packageDetails(key));
    return PackageModel.fromJson(asMap(res.data, key: 'package'));
  }

  Future<List<CouponModel>> coupons(String packageId) async {
    final res = await dio.get(ApiEndpoints.packageWithCoupons(packageId));
    return asList(res.data, key: 'coupons').map(CouponModel.fromJson).toList();
  }

  /// Creates the order and returns its id. Mirrors the website checkout.
  Future<String> placeOrder({
    required PackageModel package,
    required String projectTitle,
    required String projectBrief,
    required num finalPrice,
    required String coupon,
    required int deliveryDays,
    required String buyerId,
    required String buyerName,
    required String buyerPhoto,
    required String buyerEmail,
    required String country,
    required List<File> attachments,
  }) async {
    final contents = [
      for (var i = 0; i < package.contents.length; i++)
        {'id': i + 1, 'name': package.contents[i], 'isDone': false},
    ];
    final form = FormData();
    // packageName must come before the files: the server builds the upload
    // folder from it while the files stream in.
    form.fields.addAll([
      MapEntry('packageName', package.name),
      MapEntry('packageId', package.id),
      MapEntry('projectTitle', projectTitle),
      MapEntry('projectBrief', projectBrief),
      MapEntry('packageContents', jsonEncode(contents)),
      MapEntry('packageRequirements', package.requirements),
      MapEntry('sellPrice', finalPrice.toStringAsFixed(2)),
      MapEntry('coupon', coupon),
      MapEntry('time', deliveryDays.toString()),
      MapEntry('buyerid', buyerId),
      MapEntry('buyername', buyerName),
      MapEntry('bdp', buyerPhoto),
      MapEntry('email', buyerEmail),
      MapEntry('country', country),
      MapEntry('currency', 'BDT'),
      MapEntry('quotedPrice', finalPrice.toStringAsFixed(2)),
    ]);
    for (final f in attachments) {
      form.files.add(
        MapEntry(
          'mainPics',
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    final res = await dio.post(ApiEndpoints.buyPackage, data: form);
    final result = asMap(res.data, key: 'result');
    final id = idOf(result['insertedId']);
    if (id.isEmpty) {
      throw Exception('The order was not created. Please try again.');
    }
    return id;
  }

  Future<List<PaymentMethod>> paymentMethods() async {
    final res = await dio.get(ApiEndpoints.paymentMethods);
    return asList(res.data).map(PaymentMethod.fromJson).toList();
  }

  Future<void> submitPayment({
    required String orderId,
    required String method,
    required String senderNumber,
    required String transactionId,
    String reference = '',
  }) async {
    await dio.put(
      ApiEndpoints.updateOrderPayment(orderId),
      data: {
        'paymentMethod': method,
        'paymentNumber': senderNumber,
        'referenceCode': reference,
        'transactionId': transactionId,
        'paymentStatus': 'Pending Verification',
      },
    );
  }
}
