// lib/feature/my_entry/widget/w_entry_rejected_view.dart (수정)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../../../shared/widget/w_cached_image.dart';

class WEntryRejectedView extends ConsumerWidget {
  final EntryModel entry;

  const WEntryRejectedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 반려 사유는 rejectionReason 필드를 사용하며, 없을 경우 기본 메시지 사용
    final String reason = '반려 사유: 운영 정책 위반 및 사진 규격 미달';
    final Color rejectColor = Colors.red.shade600;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // 1. 상태 배지 (Rejection Badge - 경고 강조)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: rejectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(color: rejectColor, width: 1.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: rejectColor, size: 24.w),
                      SizedBox(width: 10.w),
                      Text(
                        '등록 반려됨',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: rejectColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),

                // 2. 반려된 사진 표시 (WEntryPendingView와 동일한 세련된 카드 형태 유지)
                AspectRatio(
                  aspectRatio: 1 / 1.2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.w),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        WCachedImage(
                          imageUrl: entry.photoUrl,
                          fit: BoxFit.cover,
                          overlayColor: Colors.black.withOpacity(0.3),
                          overlayBlendMode: BlendMode.darken,
                        ),
                        Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 80.w,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),

                // 3. 반려 사유 및 안내 카드
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '반려 안내',
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: rejectColor),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        reason,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800, height: 1.4),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        '재신청은 새로운 사진을 등록하여 진행할 수 있습니다. 운영 정책을 다시 한 번 확인해 주세요.',
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // 하단 버튼 공간 확보를 위한 Padding
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),

        // 4. 하단 고정 CTA 버튼 (Fixed CTA)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, MediaQuery.of(context).padding.bottom + 15.h),
            decoration: BoxDecoration(
              color: AppColor.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                // 재신청 경로로 이동
                context.go('/home/submit_entry');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 55.h),
                backgroundColor: rejectColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
              ),
              child: Text('새로운 사진으로 재신청하기', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}