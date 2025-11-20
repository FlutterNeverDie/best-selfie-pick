// w_ranking_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/widget/w_ranking_list_item.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart'; // AppColor for title color

/// ✨ 최상위 랭킹 리스트 뷰: 제목과 모든 데이터를 개별 행으로 구성하는 StatelessWidget
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 사용자 요청: "실시간 순위 현황 🔥" 텍스트 추가
          Padding(
            padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w, bottom: 12.h),
            child: Text(
              '실시간 순위 현황 🔥',
              style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  // 핑크 악센트 색상 사용
                  color: Colors.pinkAccent.shade700
              ),
            ),
          ),

          // 📜 랭킹 리스트
          ListView.builder(
            shrinkWrap: true, // Column 안에 ListView를 넣기 위해 필수
            physics: const NeverScrollableScrollPhysics(), // SingleChildScrollView에 스크롤 위임
            padding: EdgeInsets.symmetric(horizontal: 16.w), // 좌우 패딩만 유지
            itemCount: rankingData.length,
            itemBuilder: (context, index) {
              final entry = rankingData[index];
              final rank = index + 1;

              return WRankingListItem(
                entry: entry,
                rank: rank,
              );
            },
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}