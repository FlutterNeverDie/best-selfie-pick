import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/rank/widget/w_candidate_item.dart';
import '../provider/vote_provider.dart';

// 💡 하단 오버레이 높이보다 약간 더 여유를 둡니다 (120 + 20 여유)
const double _bottomPadding = 140.0;

class WVotingCandidateGrid extends ConsumerWidget {
  const WVotingCandidateGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final notifier = ref.read(voteProvider.notifier);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 스크롤이 90% 이상 내려가고, 더 불러올 페이지가 있고, 로딩중이 아닐 때
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
            status.hasMorePages &&
            !status.isLoadingNextPage) {
          notifier.loadCandidates();
          return true;
        }
        return false;
      },
      child: GridView.builder(
        // 💡 하단 오버레이에 가려지지 않도록 패딩 설정
        padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.h,
            bottom: _bottomPadding.h // 하단 여백 확보
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.75, // 세로로 약간 긴 비율 (사진 중심)
        ),
        // 로딩 중이면 아이템 하나 더(인디케이터용) 보여줌
        itemCount: status.candidates.length + (status.isLoadingNextPage ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= status.candidates.length) {
            // 하단 로딩 인디케이터
            return Center(
                child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(strokeWidth: 2)
                )
            );
          }

          final candidate = status.candidates[index];
          return WCandidateItem(candidate: candidate);
        },
      ),
    );
  }
}