import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';

import '../../../../shared/service/uri_service.dart';

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
      backgroundColor: Colors.transparent, // 배경 투명
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h), // 화면 꽉 차지 않게 여백 줌
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

          // 2. 이미지 영역 (남은 공간 차지, 버튼 안 가림)
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: CachedNetworkImage(
                  imageUrl: entry.thumbnailUrl,
                  fit: BoxFit.contain, // 비율 유지하며 다 보여주기
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 3. 하단 인스타그램 버튼 (그라데이션 & 그림자)
          GestureDetector(
            onTap: _launchInstagram,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                // 인스타그램 브랜드 그라데이션
                gradient: const LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30.w), // 둥근 캡슐 모양
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

          // 하단 여백 (SafeArea 고려)
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}