// lib/feature/ranking/s_ranking.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';
import 'package:selfie_pick/feature/rank/widget/w_no_candidates_message.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_app_bar.dart';
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

    if( voteStatus.candidates.isEmpty){
      return const WNoCandidatesMessage();
    }

    // 💡 초기 로딩 시 투명한 배경의 로딩 화면을 보여줍니다.
    if ( voteStatus.hasMorePages && !voteStatus.isVoted) {

      debugPrint('RankingScreen: 로딩 중');
      debugPrint('voteStatus.hasMorePages: ${voteStatus.hasMorePages}');

      // 투표 완료 상태가 아니고, 후보 목록이 비어있고, 로딩할 페이지가 남아있을 때 (최초 로딩 중)
      return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    }
    return Scaffold(
      appBar: WRankingAppBar(),
      body: voteStatus.isVoted
          ? WRankingListView(
        // 투표 완료 시: 순위 조회 화면
        rankingData: voteStatus.candidates,
      )
          : const WVotingDiscovery(), // 💡 투표 미완료 시: 투표 진행 화면 (const 추가)
    );
  }
}