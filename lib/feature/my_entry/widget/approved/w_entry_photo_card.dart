import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widget/w_cached_image.dart';

class WEntryPhotoCard extends StatelessWidget {
  final String photoUrl;
  final String snsId;

  const WEntryPhotoCard({
    super.key,
    required this.photoUrl,
    required this.snsId,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 400.h, // 시원하게 큼직한 사이즈
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 이미지
              WCachedImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
              ),

              // 2. 하단 그라데이션 (Align 사용)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. SNS ID (Align 사용)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Text(
                    '@$snsId',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}