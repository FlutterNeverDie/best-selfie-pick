import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // 📦 Shimmer 패키지
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/shared/provider/contest_status/model/m_contest_status.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';
import '../s_entry_submission_screen.dart';

// 💡 애니메이션을 위해 StatefulWidget으로 변경
class WEntryNotEnteredView extends ConsumerStatefulWidget {
  const WEntryNotEnteredView({super.key});

  @override
  ConsumerState<WEntryNotEnteredView> createState() => _WEntryNotEnteredViewState();
}

class _WEntryNotEnteredViewState extends ConsumerState<WEntryNotEnteredView> with TickerProviderStateMixin {
  // 🔄 로고 회전 애니메이션
  late final AnimationController _rotationController;

  // 💓 버튼 두근두근(Pulse) 애니메이션
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. 로고 회전: 10초에 한 바퀴 (천천히)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(); // 무한 반복

    // 2. 버튼 두근두근: 1.5초 주기
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true); // 커졌다 작아졌다 반복

    // 크기 변화: 1.0 -> 1.05 (5% 정도만 살짝 커짐)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContestStatusModel contestStatus = ref.watch(contestStatusProvider);
    final userState = ref.watch(authProvider);

    final String userRegion = (userState.user?.channel == 'NotSet' || userState.user?.channel == null)
        ? '채널 미설정'
        : userState.user!.channel;

    final bool isContestActive = contestStatus.currentWeekKey != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 80.h),

          // 1. 📍 채널 배지
          if (isContestActive)
            Container(
              margin: EdgeInsets.only(bottom: 24.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: AppColor.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 14.w, color: AppColor.primary),
                  SizedBox(width: 4.w),
                  Text(
                    '$userRegion 챔피언 도전',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),

          // 2. ✨ 메인 아이콘 (회전 애니메이션 적용 🔄)
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColor.primary, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              // 💡 RotationTransition으로 감싸서 360도 회전
              child: RotationTransition(
                turns: _rotationController,
                child: Icon(
                  Icons.camera,
                  size: 60.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // 3. 텍스트 영역
          if (isContestActive) ...[
            Text(
              "이번 주 주인공은\n바로 당신입니다! ✨",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "가장 자신 있는 사진을 올리고\n$userRegion 채널의 베스트 픽이 되어보세요.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade500,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Text(
              "지금은 휴식 시간이에요 🌙",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),
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

          // 4. CTA 버튼 (두근두근 💓 + 시머 ✨)
          if (isContestActive) ...[
            // 💡 ScaleTransition으로 두근거리는 효과 적용
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColor.primary, Colors.purpleAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    context.goNamed(EntrySubmissionScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 아이콘도 살짝 반짝이게
                      Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: Colors.white.withOpacity(0.5),
                        period: const Duration(seconds: 2),
                        child: const Icon(Icons.auto_awesome_rounded),
                      ),
                      SizedBox(width: 8.w),
                      // 💡 텍스트에 Shimmer 적용 (은은하게 빛 지나감)
                      Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: Colors.grey.shade300, // 살짝 어두운 흰색으로 빛 효과
                        period: const Duration(milliseconds: 2000),
                        child: Text(
                          '지금 바로 참가하기',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 💡 [추가된 부분] 안심 문구 추가
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14.sp, color: Colors.grey.shade400),
                SizedBox(width: 4.w),
                Text(
                  "참가 후에도 언제든 비공개로 전환할 수 있어요",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}