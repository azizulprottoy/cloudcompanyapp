import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../packages/model/package_model.dart';

class ServiceItem {
  ServiceItem({
    required this.title,
    required this.description,
    required this.image,
  });
  final String title;
  final String description;
  final String image;
}

class FaqItem {
  FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class HomeData {
  HomeData({
    required this.services,
    required this.packages,
    required this.faqs,
  });
  final List<ServiceItem> services;
  final List<PackageModel> packages;
  final List<FaqItem> faqs;
}

class HomeRepository extends BaseRepository {
  HomeRepository({super.dio});

  Future<HomeData> load() async {
    final res = await dio.get(ApiEndpoints.homeSecondary);
    final body = res.data;
    return HomeData(
      services: asList(body, key: 'services')
          .map(
            (s) => ServiceItem(
              title: (s['serviceTitle'] ?? '').toString(),
              description: Formatters.plain(
                s['serviceDescription']?.toString(),
              ),
              image: (s['serviceBgImage'] ?? '').toString(),
            ),
          )
          .where((s) => s.title.isNotEmpty)
          .toList(),
      packages: asList(body, key: 'packages')
          .map(PackageModel.fromJson)
          .where((p) => p.status.isEmpty || p.status == 'approved')
          .toList(),
      faqs: asList(body, key: 'faqs')
          .map(
            (f) => FaqItem(
              question: Formatters.plain(f['faqquestion']?.toString()),
              answer: Formatters.plain(f['faqanswer']?.toString()),
            ),
          )
          .where((f) => f.question.isNotEmpty)
          .toList(),
    );
  }
}
