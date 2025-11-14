// lib/feature/my_contest/widget/w_entry_pending_view.dart (수정)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
// import 'package:selfie_pick/feature/my_contest/widget/w_entry_status_card.dart'; // 기존 카드 위젯은 사용하지 않음
import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../../../shared/widget/w_cached_image.dart'; // AppColor 사용 가정

class WEntryPendingView extends ConsumerWidget {
  final EntryModel entry;

  const WEntryPendingView({super.key, required this.entry});

  // 복사 기능을 위한 임시 함수 (실제 구현 시 Clipboard API 사용)
  void _copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ID '${text}'가 클립보드에 복사되었습니다.", style: TextStyle(fontSize: 14.sp)),
        duration: const Duration(seconds: 1),
      ),
    );
    // 실제 복사 로직: Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scaffold를 포함하는 Screen이 아니므로 Padding과 Center를 사용
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // 1. 상태 배지 (Status Badge - 세련된 알림 스타일)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1), // 은은한 배경색
                borderRadius: BorderRadius.circular(10.w),
                border: Border.all(color: Colors.orange.shade300, width: 1.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_filled, color: Colors.orange.shade600, size: 24.w),
                  SizedBox(width: 10.w),
                  Text(
                    '승인 검토 대기 중',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),

            // 2. 등록된 사진 (Aspect Ratio를 사용하여 레이아웃 안정화)
            AspectRatio(
              aspectRatio: 1 / 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: WCachedImage( // 💡 WCachedImage 사용
                  imageUrl: entry.photoUrl,
                  // width, height는 AspectRatio가 제어하므로 명시 불필요
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // 3. 등록 정보 카드 (SNS ID 강조)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColor.white, // 흰색 배경
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
                  // 등록 지역 및 회차 정보
                  Text(
                    '${entry.regionCity} | ${entry.weekKey} 참가',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 15.h),

                  // SNS ID (인스타/무신사 스타일 강조)
                  Text(
                    '홍보 계정 ID',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.snsId,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 최종 메시지 및 안내
                  Text(
                    '안내 사항',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '등록된 사진은 관리자의 검토(일반적으로 24시간 이내)를 거칩니다. 승인되면 자동으로 현재 진행 중인 ${entry.weekKey} 투표 대상에 추가됩니다.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}