import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/error/api_error.dart';
import '../../../core/utils/formatters.dart';
import '../repository/blog_repository.dart';

/// Client "Blog" tab.
class BlogListController extends GetxController {
  BlogListController({BlogRepository? repository})
    : _repository = repository ?? BlogRepository();

  final BlogRepository _repository;

  final posts = <BlogPost>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      posts.assignAll(await _repository.posts());
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}

class BlogDetailsController extends GetxController {
  BlogDetailsController({BlogRepository? repository})
    : _repository = repository ?? BlogRepository();

  final BlogRepository _repository;

  late final BlogPost post;
  final html = ''.obs;
  final isLoading = true.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    post = Get.arguments as BlogPost;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      _repository.post(post.slug).catchError((_) => post); // count the view
      final jsx = post.hasBody ? await _repository.body(post.slug) : '';
      html.value = _page(jsx);
    } catch (e) {
      error.value = apiErrorMessage(
        e,
        fallback: 'Could not load this article.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Same runtime as the website's blog iframe: React + Babel compile the JSX
  /// component `BlogPost` in the page. Versions pinned.
  String _page(String jsx) {
    final safeJsx = jsx.replaceAll(
      RegExp(r'</script', caseSensitive: false),
      r'<\/script',
    );
    final blogJson = jsonEncode(post.raw).replaceAll('</', r'<\/');
    const esc = HtmlEscape();
    final cover = post.cover.isEmpty
        ? ''
        : '<img src="${esc.convert(post.cover)}" style="width:100%;border-radius:14px;margin:12px 0 4px">';
    final header =
        '$cover<h1 style="font-size:1.6rem;font-weight:700;line-height:1.25;margin:14px 0 6px">'
        '${esc.convert(post.title)}</h1>'
        '<p style="color:#64748b;font-size:.85rem;margin:0 0 18px">${esc.convert(post.author)} · '
        '${esc.convert(Formatters.date(post.createdAt))}</p>';
    final body = jsx.trim().isEmpty
        ? '$header<p style="color:#374151;line-height:1.7">${esc.convert(post.summary)}</p>'
        : '$header<div id="root"></div>';
    return '''
<!DOCTYPE html><html><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://unpkg.com/react@18.3.1/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@babel/standalone@7.26.4/babel.min.js"></script>
<script src="https://cdn.tailwindcss.com/3.4.17"></script>
<style>
  html,body{margin:0;padding:0;background:#fff;overflow-x:hidden}
  body{font-family:-apple-system,Roboto,system-ui,sans-serif;padding:4px 16px 32px}
  img{max-width:100%}
  .prose h1{font-size:1.9rem;font-weight:700;margin-bottom:1rem}
  .prose h2{font-size:1.45rem;font-weight:700;margin:1.8rem 0 .8rem}
  .prose h3{font-size:1.15rem;font-weight:700;margin:1.4rem 0 .6rem}
  .prose p{line-height:1.75;color:#374151;margin-bottom:1rem}
  .prose ul{padding-left:1.3rem;margin-bottom:1rem;list-style:disc}
  .prose li{margin-bottom:.45rem;color:#374151}
  .prose a{color:#2563eb;text-decoration:underline}
  .prose blockquote{border-left:4px solid #3b82f6;background:#eff6ff;padding:1rem 1.2rem;border-radius:.75rem;color:#1e3a8a;margin:1.6rem 0}
</style></head><body>$body
<script type="text/babel">
  const blog = $blogJson;
  const images = blog.blogImages || [];
  try {
    $safeJsx
    if (typeof BlogPost !== "undefined") {
      ReactDOM.createRoot(document.getElementById("root")).render(<BlogPost blog={blog} images={images} />);
    }
  } catch (e) {
    document.getElementById("root").innerHTML = '<p style="color:#dc2626">This article could not be displayed.</p>';
  }
</script></body></html>''';
  }
}
