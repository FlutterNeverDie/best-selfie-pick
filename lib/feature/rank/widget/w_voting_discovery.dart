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
    final currentUserRegion = ref.watch(authProvider.select((state) => state.user?.region)) ?? '지역 미설정';

    final bool noCandidatesFound = status.candidates.isEmpty &&
        !status.hasMorePages &&
        !status.isLoadingNextPage;

    return Column(
      children: [
        // 1. ✨ 지역명 헤더
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
              Text(
                '$currentUserRegion',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                ' 지역의 후보를 선택해주세요',
                style: TextStyle(fontSize: 16.sp, color: Colors.black87),
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