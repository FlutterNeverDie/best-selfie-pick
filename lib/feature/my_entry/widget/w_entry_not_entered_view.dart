import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget 사용
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/shared/provider/contest_status/model/m_contest_status.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';
import '../s_entry_submission_screen.dart'; // AppColor 사용 가정

// WEntryNotEnteredView는 Notifier의 상태를 읽어야 하므로 ConsumerWidget을 사용합니다.
class WEntryNotEnteredView extends ConsumerWidget {
  const WEntryNotEnteredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ContestStatusNotifier 감시
    final ContestStatusModel contestStatus = ref.watch(contestStatusProvider);

    // 현재 회차 키가 존재하면 (회차가 시작된 상태) 도전 가능
    final bool isContestActive = contestStatus.currentWeekKey != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1, size: 60.w, color: Colors.grey),
            SizedBox(height: 20.h),
            Text(
              // 현재 회차 키가 있으면 도전 유도, 없으면 마감 메시지
              isContestActive
                  ? "이번 주차 베스트 픽에 도전하세요!"
                  : "현재 활성화된 대회가 없습니다. 잠시 후 확인해주세요.",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: AppColor.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),

            // 2. CTA 버튼 (대회 활성화 상태에서만 버튼 노출)
            if (isContestActive)
              ElevatedButton(
                onPressed: () {
                  // 참가 신청 전용 라우트로 이동
                  context.goNamed(EntrySubmissionScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200.w, 50.h),
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
                  elevation: 4.w,
                ),
                child: Text(
                  '참가 신청하기',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}