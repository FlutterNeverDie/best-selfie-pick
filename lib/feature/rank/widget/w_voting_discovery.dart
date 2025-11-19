// lib/feature/ranking/widget/w_voting_discovery.dart (최종 정리)

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

  // 하단 오버레이의 높이를 상수로 정의

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final currentUserRegion =
        ref.watch(authProvider.select((state) => state.user?.region)) ??
            '지역 미설정';

    final bool noCandidatesFound = status.candidates.isEmpty &&
        !status.hasMorePages &&
        !status.isLoadingNextPage;

    return Column(
      children: [
        // 1. ✨ 지역명 헤더
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1.h)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 20.w, color: AppColor.primary),
              SizedBox(width: 8.w),
              Text(
                '$currentUserRegion 지역 투표 후보',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),

        // 2. 💡 메인 콘텐츠 영역
        Expanded(
          child: Stack(
            children: [
              SizedBox.expand(
                child: noCandidatesFound
                    ? const WNoCandidatesMessage() // 💡 데이터 없음 위젯 사용
                    : WVotingCandidateGrid(), // 💡 Grid 위젯 사용
              ),

              // 3. 💡 하단 고정 투표 오버레이
              Align(
                alignment: Alignment.bottomCenter,
                child: const WVotingOverlay(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
