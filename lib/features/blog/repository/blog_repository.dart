import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/media_url.dart';

class BlogPost {
  BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.author,
    required this.tags,
    required this.cover,
    required this.hasBody,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String slug;
  final String summary;
  final String author;
  final List<String> tags;
  final String cover;
  final bool hasBody;
  final dynamic createdAt;
  final Map<String, dynamic> raw;

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
    id: idOf(json['_id']),
    title: (json['title'] ?? '').toString(),
    slug: (json['slug'] ?? '').toString(),
    summary: (json['shortDescription'] ?? '').toString(),
    author: (json['author'] ?? 'Cloud Company').toString(),
    tags: (json['tags'] is List ? json['tags'] as List : const [])
        .map((e) => e.toString())
        .toList(),
    cover: MediaUrl.resolve(json['coverImage']?.toString()) ?? '',
    hasBody: (json['jsxFile'] ?? '').toString().isNotEmpty,
    createdAt: json['createdAt'],
    raw: json,
  );
}

class BlogRepository extends BaseRepository {
  BlogRepository({super.dio});

  Future<List<BlogPost>> posts() async {
    final res = await dio.get(ApiEndpoints.publicBlogs);
    return asList(
      res.data,
    ).map(BlogPost.fromJson).where((b) => b.slug.isNotEmpty).toList();
  }

  /// Also counts a view on the server.
  Future<BlogPost> post(String slug) async {
    final res = await dio.get(ApiEndpoints.blogDetails(slug));
    return BlogPost.fromJson(asMap(res.data, key: 'blog'));
  }

  /// The article body is a JSX component, rendered in a WebView like the website does.
  Future<String> body(String slug) async {
    final res = await dio.get<String>(ApiEndpoints.blogJsx(slug));
    return res.data ?? '';
  }
}
