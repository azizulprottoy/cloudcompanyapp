// Read-only checks that the app's models parse the real public API.
// Run: flutter test test/live_api_smoke_test.dart  (needs internet)
@Tags(['live'])
library;

import 'package:cloudcompany_app/features/blog/repository/blog_repository.dart';
import 'package:cloudcompany_app/features/home/repository/home_repository.dart';
import 'package:cloudcompany_app/features/packages/repository/package_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.cloudcompany.cc'));

  test('home', () async {
    final d = await HomeRepository(dio: dio).load();
    expect(d.packages, isNotEmpty);
    expect(d.services, isNotEmpty);
    // ignore: avoid_print
    print('home: ${d.packages.length} packages, ${d.services.length} services, ${d.faqs.length} faqs');
  });

  test('packages + details', () async {
    final repo = PackageRepository(dio: dio);
    final list = await repo.packages();
    expect(list, isNotEmpty);
    final p = await repo.details(list.first.routeKey);
    expect(p.name, isNotEmpty);
    expect(p.price, greaterThan(0));
    expect(p.contents, isNotEmpty);
    // ignore: avoid_print
    print('package: ${p.name} ৳${p.price} ${p.deliveryDays}d, ${p.contents.length} items, ${p.faqs.length} faqs, express=${p.hasExpress}');
  });

  test('blog', () async {
    final repo = BlogRepository(dio: dio);
    final posts = await repo.posts();
    expect(posts, isNotEmpty);
    final withBody = posts.firstWhere((p) => p.hasBody && p.slug.contains('website-cost'));
    final body = await repo.body(withBody.slug);
    expect(body, contains('function BlogPost'));
    // ignore: avoid_print
    print('blog: ${posts.length} posts, cover=${withBody.cover.startsWith('https://')}, body ${body.length} chars');
  });
}
