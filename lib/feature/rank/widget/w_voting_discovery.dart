import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/rank/widget/w_no_candidates_message.dart';
import 'package:selfie_pick/feature/rank/widget/w_voting_candidate_grid.dart';
import 'package:selfie_pick/feature/rank/widget/w_voting_overlay.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import '../provider/vote_provider.dart';

class WVotingDiscovery extends ConsumerWidget {
  const WVotingDiscovery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final currentUserChannel = ref.watch(authProvider.select((state) => state.user?.channel)) ?? '채널 미설정';

    final bool noCandidatesFound = status.candidates.isEmpty &&
        !status.hasMorePages &&
        !status.isLoadingNextPage;

    return Column(
      children: [
        // 1. ✨ 채널명 헤더
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.h)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 20.w, color: AppColor.primary),
              SizedBox(width: 6.w),

              // 💡 채널명 + 안내 문구 (텍스트 오버플로우 방지)
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: currentUserChannel,
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      TextSpan(
                        text: ' 채널의 후보를 선택해주세요',
                        style: TextStyle(fontSize: 16.sp, color: Colors.black87),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(width: 6.w),

              // 💡 [추가] 투표 최소 인원 안내 툴팁 (말풍선)
              Tooltip(
                // 말풍선에 표시될 메시지
                message: '공정한 투표를 위해\n후보가 3명 이상 모여야 투표가 가능해요!',
                // 모바일에서 클릭 시 보이도록 설정
                triggerMode: TooltipTriggerMode.tap,
                // 말풍선 스타일
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                showDuration: const Duration(seconds: 3),
                preferBelow: true,
                verticalOffset: 10.h,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                // 아이콘 버튼
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18.w,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

            ],
          ),
        ),

        // 2. 메인 콘텐츠
        Expanded(
          child: Stack(
            children: [
              // 배경 그리드
              noCandidatesFound
                  ? const WNoCandidatesMessage()
                  : const WVotingCandidateGrid(),

              // 하단 고정 오버레이
              const Align(
                alignment: Alignment.bottomCenter,
                child: WVotingOverlay(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}