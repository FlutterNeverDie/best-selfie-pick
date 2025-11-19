import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/champion/provider/champion_provider.dart';

class WChampionRanking extends ConsumerWidget {
  const WChampionRanking({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(championProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    if (state.champions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 60.w, color: AppColor.hintText),
            SizedBox(height: 16.h),
            Text(
              '지난 주차 챔피언이 없습니다.',
              style: TextStyle(fontSize: 16.sp, color: AppColor.hintText),
            ),
          ],
        ),
      );
    }

    // 1등, 2등, 3등 순서로 정렬되어 있다고 가정
    final first = state.champions.isNotEmpty ? state.champions[0] : null;
    final second = state.champions.length > 1 ? state.champions[1] : null;
    final third = state.champions.length > 2 ? state.champions[2] : null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 50.h),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Text(
            '지난 주 명예의 전당 🏆',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColor.black,
            ),
          ),
          SizedBox(height: 30.h),

          // Top 3 Podium Display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                if (second != null) _buildPodiumItem(second, 2),
                // 1st Place (Center & Larger)
                if (first != null) _buildPodiumItem(first, 1),
                // 3rd Place
                if (third != null) _buildPodiumItem(third, 3),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // Additional Info or List (Optional)
          if (first != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
                color: Colors.amber.shade50,
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Text(
                        '🥇 1위 우승 소감',
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '"투표해주신 모든 분들께 감사드립니다!"', // 실제 데이터에 소감이 있다면 교체
                        style: TextStyle(
                            fontSize: 16.sp, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(dynamic entry, int rank) {
    final isFirst = rank == 1;
    final double avatarSize = isFirst ? 60.w : 45.w;
    final double height = isFirst ? 20.h : 0; // Height offset
    final Color medalColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey.shade400
            : Colors.brown.shade400;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for 1st place
          if (isFirst)
            Icon(Icons.workspace_premium, color: Colors.amber, size: 40.w),

          SizedBox(height: 8.h),

          // Avatar with Border
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: medalColor, width: 3.w),
            ),
            child: CircleAvatar(
              radius: avatarSize,
              backgroundColor: AppColor.lightGrey,
              backgroundImage:
                  entry.thumbnailUrl != null && entry.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImageProvider(entry.thumbnailUrl!)
                      : null,
              child: entry.thumbnailUrl == null || entry.thumbnailUrl.isEmpty
                  ? Icon(Icons.person,
                      size: avatarSize, color: AppColor.darkGrey)
                  : null,
            ),
          ),
          SizedBox(height: 12.h),

          // Rank Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: medalColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$rank위',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // SNS ID
          Text(
            "@${entry.snsId}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 16.sp : 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Score
          Text(
            "${entry.totalScore}점",
            style: TextStyle(
              color: AppColor.darkGrey,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: height), // Offset for podium effect
        ],
      ),
    );
  }
}
