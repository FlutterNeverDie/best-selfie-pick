// lib/shared/widget/w_cached_image.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? overlayColor;
  final BlendMode? overlayBlendMode;

  const WCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover, // 기본값은 cover
    this.overlayColor,
    this.overlayBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 Stack이 부모 영역을 채우도록 Positioned.fill 사용
    return CachedNetworkImage(
      imageUrl: imageUrl,
      // 💡 width, height 인자를 Positioned.fill이 제어하므로 제거
      // width: width?.w,
      // height: height?.h,
      fit: fit,
      color: overlayColor,
      colorBlendMode: overlayBlendMode,

      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 30.w,
            height: 30.w,
            child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.grey),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 50.w, color: Colors.grey.shade600),
      ),
    );
  }
}