import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import '../../../shared/widget/w_cached_image.dart';

class WEntryRejectedView extends ConsumerWidget {
  final EntryModel entry;

  const WEntryRejectedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 🖼️ 반려된 사진 카드 (흑백 + 도장)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.w),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: 배경 이미지 (흑백 처리)
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation, // 채도 0
                      ),
                      child: WCachedImage(
                        imageUrl: entry.thumbnailUrl,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Layer 2: 어두운 오버레이 (도장이 더 잘 보이게)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                    ),

                    // Layer 3: 💡 요청하신 "REJECTED" 도장 유지
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 4.w),
                          borderRadius: BorderRadius.circular(12.w),
                          color: Colors.white.withOpacity(0.1), // 살짝 반투명
                        ),
                        // 도장처럼 살짝 기울이기 (-12도)
                        transform: Matrix4.rotationZ(-0.2),
                        child: Text(
                          'REJECTED',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent.withOpacity(0.9),
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 32.h),

          // 2. 📝 반려 사유 박스
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50, // 붉은 배경
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20.w, color: Colors.red.shade700),
                    SizedBox(width: 8.w),
                    Text(
                      '승인이 거절되었어요 😢',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // 사유 하드코딩 및 안내
                Text(
                  '사유: 운영 정책 위반 및 사진 규격 미달\n\n아쉽지만 이번 사진은 함께할 수 없게 되었어요. 위 사유를 확인하고 다시 도전해주세요!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // 3. 재신청 버튼
          ElevatedButton(
            onPressed: () {
              context.go('/home/submit_entry');
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 54.h),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  '새로운 사진으로 재신청하기',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h), // 하단 여백
        ],
      ),
    );
  }
}