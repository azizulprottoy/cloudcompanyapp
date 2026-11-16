import '../../../core/network/base_repository.dart';

class PackageFaq {
  PackageFaq({required this.question, required this.answer});
  final String question;
  final String answer;
}

class PackageModel {
  PackageModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.deliveryDays,
    required this.expressDays,
    required this.expressPrice,
    required this.contents,
    required this.detailsHtml,
    required this.requirements,
    required this.cover,
    required this.slug,
    required this.metaDescription,
    required this.faqs,
    required this.status,
  });

  final String id;
  final String name;
  final String category;
  final num price;
  final int deliveryDays;
  final int expressDays;
  final num expressPrice;
  final List<String> contents;
  final String detailsHtml;
  final String requirements;
  final String cover;
  final String slug;
  final String metaDescription;
  final List<PackageFaq> faqs;
  final String status;

  bool get hasExpress => expressDays > 0 && expressPrice > 0;

  /// Slug when available, so links match the website.
  String get routeKey => slug.isNotEmpty ? slug : id;

  static num _num(dynamic v) =>
      num.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    final rawContents = json['packageContents'];
    final contents = rawContents is List
        ? rawContents.map(
            (e) => e is Map ? (e['name'] ?? '').toString() : e.toString(),
          )
        : rawContents.toString().split(',');

    return PackageModel(
      id: idOf(json['_id']),
      name: (json['packageName'] ?? '').toString(),
      category: (json['category'] ?? 'Other').toString(),
      price: _num(json['packagePrice']),
      deliveryDays: _num(json['deliveryTime']).toInt(),
      expressDays: _num(json['expressDeliveryTime']).toInt(),
      expressPrice: _num(json['expressDeliveryPrice']),
      contents: contents
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != 'null')
          .toList(),
      detailsHtml: (json['packageDetails'] ?? '').toString(),
      requirements: (json['packageRequirements'] ?? '').toString(),
      cover: (json['packageCover'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      metaDescription: (json['metaDescription'] ?? '').toString(),
      faqs: (json['faqs'] is List ? json['faqs'] as List : const [])
          .whereType<Map>()
          .map(
            (f) => PackageFaq(
              question: (f['q'] ?? '').toString(),
              answer: (f['a'] ?? '').toString(),
            ),
          )
          .where((f) => f.question.isNotEmpty && f.answer.isNotEmpty)
          .toList(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class CouponModel {
  CouponModel({required this.code, required this.discountPercent});
  final String code;
  final num discountPercent;

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
    code: (json['couponcode'] ?? '').toString(),
    discountPercent: num.tryParse(json['discount']?.toString() ?? '') ?? 0,
  );
}
