import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 이미지 캐싱
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class WRankingListView extends StatelessWidget {
  final List<EntryModel> rankingData;

  const WRankingListView({
    super.key,
    required this.rankingData,
  });

  Color _getMedalColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.blueGrey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return AppColor.lightGrey; // 4등 이하
  }

  IconData _getMedalIcon(int rank) {
    if (rank <= 3) return Icons.emoji_events;
    return Icons.star_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실시간 순위 현황 🔥',
            style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.primary),
          ),
          SizedBox(height: 12.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rankingData.length,
            itemBuilder: (context, index) {
              final entry = rankingData[index];
              final rank = index + 1;
              final isTopThree = rank <= 3;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 6.h),
                elevation: isTopThree ? 4.w : 1.w,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  side: isTopThree
                      ? BorderSide(color: _getMedalColor(rank), width: 1.5.w)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

                  // 💡 변경된 부분: 번호 대신 사진 썸네일 표시
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24.w, // 아바타 크기 증가
                        backgroundColor: AppColor.lightGrey, // 로딩 중 배경색
                        backgroundImage: entry.thumbnailUrl != null &&
                                entry.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(entry.thumbnailUrl!)
                            : null,
                        child: entry.thumbnailUrl == null ||
                                entry.thumbnailUrl!.isEmpty
                            ? Icon(Icons.person,
                                color: AppColor.darkGrey,
                                size: 30.w) // 이미지가 없을 경우 기본 아이콘
                            : null,
                      ),
                      // 💡 1~3등에게는 메달 아이콘을 오버레이로 표시
                      if (isTopThree)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 10.w, // 메달 아이콘 배경 크기
                            backgroundColor: _getMedalColor(rank),
                            child: Icon(_getMedalIcon(rank),
                                color: Colors.white, size: 14.w),
                          ),
                        ),
                    ],
                  ),

                  // 2. SNS ID 노출
                  title: Text(
                    "@${entry.snsId}",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight:
                          isTopThree ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),

                  // 3. 순위 표시 (Trailing)
                  trailing: Text(
                    '${rank}위',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight:
                          isTopThree ? FontWeight.bold : FontWeight.normal,
                      color:
                          isTopThree ? _getMedalColor(rank) : AppColor.darkGrey,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}
