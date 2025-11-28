import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/my_entry/s_entry_submission_screen.dart';

import '../provider/vote_provider.dart';

class WNoCandidatesMessage extends ConsumerWidget {
  const WNoCandidatesMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(voteProvider.notifier).loadCandidates();
      },
      color: Colors.pinkAccent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 텅 빈 느낌을 주는 일러스트성 아이콘
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // 아주 연한 회색 배경
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200), // 테두리
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person_search_rounded, // 사람 찾는 아이콘
                    size: 50.w,
                    color: Colors.grey.shade300,
                  ),
                  Positioned(
                    right: 28.w,
                    top: 28.w,
                    child: Icon(
                      Icons.question_mark_rounded,
                      size: 24.w,
                      color: AppColor.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 2. 메인 메시지
            Text(
              '아직 이 채널은 조용해요 🤫',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12.h),

            // 3. 서브 메시지 (참가 유도 멘트)
            Text(
              '등록된 후보가 없습니다.\n가장 먼저 참가해서 랭킹 1위를 선점해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade600,
                height: 1.5, // 줄간격
              ),
            ),
            /*          SizedBox(height: 32.h),

            // 4. 액션 버튼 (바로가기)
            ElevatedButton(
              onPressed: () {
                // 참가 신청 화면으로 이동
                context.pushNamed(EntrySubmissionScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0, // 플랫하게
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.w), // 캡슐 모양
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 18.w),
                  SizedBox(width: 8.w),
                  Text(
                    '첫 번째 주인공 되기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
