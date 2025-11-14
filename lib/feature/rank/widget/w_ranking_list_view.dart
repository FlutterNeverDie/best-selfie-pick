// lib/feature/ranking/widget/w_ranking_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class WRankingListView extends StatelessWidget {
  final List<EntryModel> rankingData; // 투표 완료 후 최종 순위 데이터 (VoteNotifier에서 전달)

  const WRankingListView({
    super.key,
    required this.rankingData,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 실제 순위를 위해 totalScore 기준으로 정렬 로직이 필요하지만, 여기서는 목록만 보여줍니다.

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주차 투표 결과',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: ListView.builder(
              itemCount: rankingData.length,
              itemBuilder: (context, index) {
                final entry = rankingData[index];
                final rank = index + 1;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColor.primary,
                    child: Text('$rank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(entry.snsId),
                  subtitle: Text('점수: ${entry.totalScore ?? '집계 중'}'), // totalScore는 정산 후 업데이트되는 필드 가정
                  trailing: Icon(Icons.star, color: rank == 1 ? Colors.amber : Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}