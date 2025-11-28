import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_item.dart';
import 'package:text_gradiate/text_gradiate.dart';

import '../../../shared/admob/w_banner_ad.dart';
import 'w_ranking_top_podium.dart';
import '../provider/vote_provider.dart';

class WRankingListView extends ConsumerWidget {
  final List<EntryModel> rankingData;

  const WRankingListView({
    super.key,
    required this.rankingData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rankingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 60.w, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              "아직 집계된 랭킹이 없습니다.",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // 데이터 분리
    final topThree = rankingData.take(3).toList();
    final challengers = rankingData.skip(3).toList();

    // 채널
    final channel = ref.read(authProvider).user!.channel ?? '??';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(voteProvider.notifier).loadCandidates();
      },
      color: Colors.pinkAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. [상단 광고] 작게 (320x50)
            // 💡 실시간 핫픽 위에 배치
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Center(
                child: WBannerAd(adSize: AdSize.banner),
              ),
            ),

            // 3. 시상대 위젯 (타이머 포함)
            if (topThree.isNotEmpty) WRankingTopPodium(topThree: topThree,channel : channel ),

            // 4. 나머지 참가자 섹션
            if (challengers.isNotEmpty) ...[
              SizedBox(height: 24.h),

              // 💡 5. [중간 광고] 크게 (300x250)
              // 위클리 라인업 바로 위에 배치하여 시선 집중
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: const Center(
                  child: WBannerAd(adSize: AdSize.mediumRectangle),
                ),
              ),

              SizedBox(height: 24.h),

              // 💡 [디자인 수정] 위클리 라인업 헤더 (매거진 스타일)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // 1. 악센트 라인 (왼쪽 세로줄)
                      Container(
                        width: 4.w,
                        decoration: BoxDecoration(
                          color: Colors.black87, // 혹은 AppColor.primary
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // 2. 타이틀 및 서브 타이틀
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEKLY LINEUP',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 1.0, // 자간을 넓혀서 세련되게
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '순서는 투표율과 무관합니다.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 리스트 아이템
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: challengers.length,
                itemBuilder: (context, index) {
                  return WRankingListItem(
                    key: ValueKey(challengers[index].entryId),
                    entry: challengers[index],
                    rank: index + 4, // 4위부터 시작
                  );
                },
              ),
            ],

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}
