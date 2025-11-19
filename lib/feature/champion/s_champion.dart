import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';
import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';
import '../champion/widget/w_champion_ranking.dart';


class ChampionScreen extends ConsumerWidget {
  static const String routeName = '/ChampionScreen';
  const ChampionScreen({super.key});

  // 새로고침 로직
  Future<void> _onRefresh(WidgetRef ref) async {
    // VoteNotifier를 재빌드하여 투표 완료 여부 및 후보 목록을 새로 로드합니다.
    ref.invalidate(voteProvider);
    await ref.read(voteProvider.notifier).loadCandidates();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 1. 상태 참조 오류 수정: voteState로 통일
    final voteState = ref.watch(voteProvider);

    // 로딩 상태를 확인합니다. (최초 로딩 또는 투표 제출 중)
    final isLoading = voteState.candidates.isEmpty &&
        voteState.hasMorePages &&
        !voteState.isVoted;
    final isSubmitting = voteState.isSubmitting;


    // 💡 2. 로딩 중일 때 전체 로딩 화면 표시
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }


    return Scaffold(
      backgroundColor: AppColor.safeBackground,
      appBar: AppBar(
        // 💡 2. AppBar 구조 오류 수정: title 속성에 Text 위젯 할당
        title: Text(
          voteState.isVoted ? '베스트 픽 랭킹' : '베스트 픽 투표',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Stack(
        children: [
          // 1. 메인 콘텐츠 (RefreshIndicator 적용)
          RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
            color: AppColor.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                ),
                child: Builder(
                  builder: (context) {
                    // 2. 투표 완료 여부에 따른 분기
                    if (voteState.isVoted) {
                      // 투표 완료 시: 랭킹 결과 화면
                      return WChampionRanking(
                      );
                    } else {
                      // 투표 미완료 시: 투표 진행 화면 (스와이프 UX)
                      // 💡 WRankingVotingView는 아직 구현되지 않았으므로 임시 Container로 대체
                      return const Center(child: Text("투표 진행 화면 (W_VOTING_VIEW)"));
                    }
                  },
                ),
              ),
            ),
          ),

          // 3. 투표 제출 중 로딩 오버레이
          if (isSubmitting)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColor.white),
                  SizedBox(height: 20.h),
                  Text('투표 제출 중...', style: TextStyle(color: AppColor.white, fontSize: 18.sp)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}