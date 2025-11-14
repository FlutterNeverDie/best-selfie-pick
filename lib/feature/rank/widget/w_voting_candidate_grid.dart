// lib/feature/ranking/widget/w_voting_candidate_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/rank/widget/w_candidate_item.dart';
import '../provider/vote_provider.dart';

// 💡 WVotingDiscovery에서 선언된 _overlayHeight와 동일한 값을 사용합니다.
const double _overlayHeight = 100.0; // 100.h

class WVotingCandidateGrid extends ConsumerWidget {
  // 💡 인자 제거 및 기본 생성자 사용
  const WVotingCandidateGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final notifier = ref.read(voteProvider.notifier);

    // 💡 GridView는 스크롤 가능 위젯이므로, 부모의 높이를 채우도록 허용합니다.
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 무한 스크롤 로직 (유지)
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
            status.hasMorePages &&
            !status.isLoadingNextPage) {
          notifier.loadCandidates();
          return true;
        }
        return false;
      },
      child: Padding(
        // 💡 하단 패딩을 오버레이 높이만큼 확보하여 오버레이에 가려지는 것을 방지
        padding: EdgeInsets.only(bottom: _overlayHeight.h),
        child: GridView.builder(
          // primary: false 를 제거하여, GridView가 Expanded 내에서 기본 스크롤 동작을 하도록 합니다.
          padding: EdgeInsets.all(12.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.8,
          ),
          itemCount: status.candidates.length + (status.isLoadingNextPage ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= status.candidates.length) {
              // 로딩 중일 때 로딩 인디케이터 표시
              return Center(child: CircularProgressIndicator(color: AppColor.primary));
            }
            final candidate = status.candidates[index];
            return WCandidateItem(candidate: candidate);
          },
        ),
      ),
    );
  }
}