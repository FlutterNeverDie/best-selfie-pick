// w_ranking_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_item.dart';

/// ✨ 최상위 랭킹 리스트 뷰: 데이터를 상위 3개와 나머지로 분리하여 구성하는 StatelessWidget
class WRankingListView extends StatelessWidget {
  final List<EntryModel> rankingData;

  const WRankingListView({
    super.key,
    required this.rankingData,
  });

  @override
  Widget build(BuildContext context) {
    if (rankingData.isEmpty) {
      return const Center(child: Text("순위 데이터가 없습니다."));
    }

    // 데이터를 상위 3개와 나머지(Challenger)로 분리
    final topThree = rankingData.take(3).toList();
    final challengers = rankingData.skip(3).toList();

    // 💡 참고: challenger 리스트는 이미 Repository/Notifier 단계에서 무작위로 섞여서 넘어왔다고 가정합니다.

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // Section 1: Top 3 (경쟁 섹션)
          // ----------------------------------------------------
          Padding(
            padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w, bottom: 12.h),
            child: Text(
              '명예의 전당 (실시간 순위 🔥)',
              style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent.shade700
              ),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: topThree.length,
            itemBuilder: (context, index) {
              return WRankingListItem(
                key: ValueKey(topThree[index]),
                entry: topThree[index],
                rank: index + 1, // 1, 2, 3등
              );
            },
          ),

          // ----------------------------------------------------
          // Section 2: Challengers (도전자 섹션)
          // ----------------------------------------------------
          if (challengers.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
                  child: Text(
                    '챌린저 (랜덤 순서)',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700
                    ),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: challengers.length,
                  itemBuilder: (context, index) {
                    // 4위 이하 아이템은 isTopThree가 false가 되도록 4 이상의 rank를 전달합니다.
                    final rankForDesign = index + 4;
                    return WRankingListItem(
                      key: ValueKey(challengers[index]),
                      entry: challengers[index],
                      rank: rankForDesign, // 4 이상으로 전달하여 UI 축소
                    );
                  },
                ),
              ],
            ),

          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}