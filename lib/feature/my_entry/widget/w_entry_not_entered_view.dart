import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart'; // 💡 AuthProvider Import
import 'package:selfie_pick/shared/provider/contest_status/model/m_contest_status.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';
import '../s_entry_submission_screen.dart';

class WEntryNotEnteredView extends ConsumerWidget {
  const WEntryNotEnteredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 상태 감시
    final ContestStatusModel contestStatus = ref.watch(contestStatusProvider);

    // 💡 2. 사용자 정보 가져오기 (지역 확인용)
    final userState = ref.watch(authProvider);
    final String userRegion = (userState.user?.region == 'NotSet' || userState.user?.region == null)
        ? '지역 미설정'
        : userState.user!.region;

    final bool isContestActive = contestStatus.currentWeekKey != null;

    return Center(
      child: SingleChildScrollView( // 화면이 작을 때를 대비해 스크롤 추가
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. 📍 지역 배지 (내 지역 강조)
            if (isContestActive)
              Padding(
                padding:  EdgeInsets.only(bottom: 30.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: AppColor.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 16.w, color: AppColor.primary),
                      SizedBox(width: 6.w),
                      Text(
                        '$userRegion 챔피언 도전',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. 메인 아이콘 (그래픽 요소)
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_a_photo_rounded, // 카메라+추가 아이콘
                size: 50.w,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 32.h),

            // 3. 텍스트 영역
            if (isContestActive) ...[
              Text(
                "이번 주 주인공은\n바로 당신입니다! ✨",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "가장 자신 있는 사진을 올리고\n$userRegion 지역의 베스트 픽이 되어보세요.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ] else ...[
              Text(
                "지금은 휴식 시간이에요 🌙",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "다음 회차가 곧 시작됩니다.\n잠시만 기다려주세요!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],

            SizedBox(height: 40.h),

            // 4. CTA 버튼 (참가 신청)
            if (isContestActive)
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    // 참가 신청 화면으로 이동
                    context.goNamed(EntrySubmissionScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 4, // 버튼 그림자
                    shadowColor: AppColor.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded), // 번개 아이콘으로 임팩트
                      SizedBox(width: 8.w),
                      Text(
                        '지금 바로 참가하기',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 50.h)
          ],
        ),
      ),
    );
  }
}