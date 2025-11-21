import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_item.dart';
import 'package:text_gradiate/text_gradiate.dart';

import '../../../shared/admob/w_banner_ad.dart';
import 'w_ranking_top_podium.dart';
// import '../../../shared/widget/w_banner_ad.dart'; // 💡 광고 임시 주석 처리
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
            Icon(Icons.emoji_events_outlined, size: 60.w, color: Colors.grey.shade300),
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
             // 💡 [광고] 상단 배너 주석 처리
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Center(
                child: WBannerAd(adSize: AdSize.banner),
              ),
            ),




            // 2. 시상대 위젯 (내부에 타이머 포함됨)
            if (topThree.isNotEmpty)
              WRankingTopPodium(topThree: topThree),

            // 3. 나머지 참가자 섹션
            if (challengers.isNotEmpty) ...[
              SizedBox(height: 20.h),

              /*
              // 💡 [광고] 중간 배너 주석 처리
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: const Center(
                  child: WBannerAd(adSize: AdSize.mediumRectangle),
                ),
              ),
              */

              // SizedBox(height: 20.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.view_agenda_outlined, color: Colors.grey.shade800, size: 20.w),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '위클리 라인업',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: challengers.length,
                itemBuilder: (context, index) {
                  return WRankingListItem(
                    key: ValueKey(challengers[index].entryId),
                    entry: challengers[index],
                    rank: index + 4,
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