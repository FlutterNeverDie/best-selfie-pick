import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 💡 AdSize 사용
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';

import '../../../../shared/admob/w_banner_ad.dart';
import '../../../../shared/service/uri_service.dart'; // 경로 확인 필요

class RankingImageDetailDialog extends StatelessWidget {
  final EntryModel entry;

  const RankingImageDetailDialog({super.key, required this.entry});

  // 🔗 인스타그램 이동 로직
  void _launchInstagram() {
    final cleanId = entry.snsId.replaceAll('@', '').replaceAll(' ', '').trim();
    if (cleanId.isNotEmpty) {
      final url = 'https://www.instagram.com/$cleanId';
      UrlLauncherUtil.launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 상단 닫기 버튼 (우측 정렬)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 24.w),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // 2. 이미지 영역 (남은 공간 차지)
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: CachedNetworkImage(
                  imageUrl: entry.thumbnailUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),


          // 3. 하단 인스타그램 버튼
          GestureDetector(
            onTap: _launchInstagram,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22.w),
                  SizedBox(width: 8.w),
                  Text(
                    '인스타그램 방문하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // 💡 4. 하단 배너 광고 추가
          // 다이얼로그 하단에 자연스럽게 배치합니다.
          const WBannerAd(adSize: AdSize.banner),

          // 배너 아래 약간의 여백 (안전하게)
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}