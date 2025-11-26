import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/rank/provider/model/m_voting_status.dart';
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
    // 💡 VoteNotifier의 상태 감시
    final voteStatus = ref.watch(voteProvider);

    return Scaffold(
      // 💡 모든 상태에서 공통된 AppBar 사용
      appBar: const WRankingAppBar(),
      body: _buildBody(voteStatus),
    );
  }

  /// 상태에 따른 Body UI 분기 처리
  Widget _buildBody(VotingState voteStatus) {
    // 1. ⏳ 초기 로딩 처리
    // 후보 목록이 비어있고, 더 불러올 페이지가 있다면 로딩 중으로 간주
    if (voteStatus.candidates.isEmpty && voteStatus.hasMorePages) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    // 2. 📭 데이터 없음 처리 (로딩이 끝났는데도 비어있는 경우)
    // 💡 요청하신 대로 이 경우에도 AppBar가 유지됩니다.
    if (voteStatus.candidates.isEmpty) {
      return const WNoCandidatesMessage();
    }

    // 3. ✅ 투표 여부에 따른 화면 분기
    // 데이터가 있는 경우: 투표 완료 ? 순위 목록 : 투표 진행
    return voteStatus.isVoted
        ? WRankingListView(rankingData: voteStatus.candidates)
        : const WVotingDiscovery();
  }
}