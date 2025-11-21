import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 💡 AdSize 사용을 위해 추가
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_item.dart';
import 'package:text_gradiate/text_gradiate.dart';

import '../../../shared/admob/w_banner_ad.dart';
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
  /*          // 💡 1. [상단 광고] 작게 (Standard Banner)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Center(
                child: WBannerAd(adSize: AdSize.banner), // 320x50
              ),
            ),*/

            // ----------------------------------------------------
            // Section 1: Top 3 (실시간 핫 픽)
            // ----------------------------------------------------
            Padding(
              padding: EdgeInsets.only(top: 8.h, left: 20.w, right: 20.w, bottom: 16.h),
              child: Row(
                children: [
                  TextGradiate(
                    text: Text(
                      '실시간 핫 픽 (Top 3)',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
                    ),
                    colors: [
                      Colors.pinkAccent.shade700,
                      Colors.purpleAccent,
                      Colors.deepPurpleAccent,
                    ],
                    gradientType: GradientType.linear,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  SizedBox(width: 8.w),
                  Text('🔥', style: TextStyle(fontSize: 22.sp)),
                ],
              ),
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: topThree.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                return WRankingListItem(
                  key: ValueKey(topThree[index].entryId),
                  entry: topThree[index],
                  rank: index + 1,
                );
              },
            ),

            // ----------------------------------------------------
            // Section 2: 나머지 참가자 (위클리 라인업)
            // ----------------------------------------------------
            if (challengers.isNotEmpty) ...[

              // 💡 2. [중간 광고] 크게 (Medium Rectangle)
              // 섹션 구분선 역할도 하면서 시선을 확 끄는 큰 배너
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(
                  child: WBannerAd(adSize: AdSize.mediumRectangle), // 300x250
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(Icons.view_agenda_outlined, color: Colors.grey.shade800, size: 22.w),
                    SizedBox(width: 8.w),
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

            SizedBox(height: 50.h), // 하단 여백
          ],
        ),
      ),
    );
  }
}