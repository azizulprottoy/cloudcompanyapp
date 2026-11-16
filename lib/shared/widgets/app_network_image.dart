import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/media_url.dart';

/// Cached network image with a neutral placeholder and a fallback icon.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrl.resolve(url);
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.border.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: AppColors.textHint),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: resolved == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: resolved,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
