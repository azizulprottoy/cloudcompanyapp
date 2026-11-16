import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/utils/app_constants.dart';
import '../../../shared/widgets/state_views.dart';
import '../controller/blog_controllers.dart';

class BlogDetailsPage extends StatefulWidget {
  const BlogDetailsPage({super.key});

  @override
  State<BlogDetailsPage> createState() => _BlogDetailsPageState();
}

class _BlogDetailsPageState extends State<BlogDetailsPage> {
  final controller = Get.find<BlogDetailsController>();
  late final WebViewController _web;
  bool _pageReady = false;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _pageReady = true);
          },
          // Article links open in the browser; the article itself stays here.
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                request.isMainFrame) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _worker = ever(controller.html, _render);
    if (controller.html.isNotEmpty) _render(controller.html.value);
  }

  void _render(String html) {
    if (html.isEmpty) return;
    _web.loadHtmlString(html); // about:blank, so only real link taps navigate
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = controller.post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            tooltip: 'Open on website',
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(
              Uri.parse('${AppConstants.siteUrl}/blog/${post.slug}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.error.isNotEmpty) {
          return ErrorView(
            message: controller.error.value,
            onRetry: controller.load,
          );
        }
        return Stack(
          children: [
            WebViewWidget(controller: _web),
            if (controller.isLoading.value || !_pageReady)
              const LinearProgressIndicator(minHeight: 2),
          ],
        );
      }),
    );
  }
}
