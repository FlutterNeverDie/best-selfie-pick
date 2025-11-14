// lib/feature/ranking/s_ranking.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_view.dart';
import 'package:selfie_pick/feature/rank/widget/w_voting_discovery.dart';

import '../../core/theme/colors/app_color.dart';

class RankingScreen extends ConsumerWidget {
  static const String routeName = '/ranking';
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 VoteNotifier의 상태를 감시 (isVoted, candidates 목록, 로딩 상태 포함)
    final voteStatus = ref.watch(voteProvider);

    // 💡 초기 로딩 시 투명한 배경의 로딩 화면을 보여줍니다.
    if (voteStatus.candidates.isEmpty && voteStatus.hasMorePages && !voteStatus.isVoted) {
      // 투표 완료 상태가 아니고, 후보 목록이 비어있고, 로딩할 페이지가 남아있을 때 (최초 로딩 중)
      return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    }
    return Scaffold(
      appBar: AppBar(
        title:
        Text( 
          voteStatus.isVoted ? '베스트 픽 랭킹' : '베스트 픽 투표',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: voteStatus.isVoted
          ? WRankingListView(
        // 투표 완료 시: 순위 조회 화면
        rankingData: voteStatus.candidates,
      )
          : const WVotingDiscovery(), // 💡 투표 미완료 시: 투표 진행 화면 (const 추가)
    );
  }
}