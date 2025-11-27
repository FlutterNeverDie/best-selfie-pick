import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:text_gradiate/text_gradiate.dart';

import '../model/m_champion.dart';
import '../provider/champion_provider.dart';

class WChampionPodium extends ConsumerWidget {
  final List<ChampionModel> champions;

  const WChampionPodium({super.key, required this.champions});

  // 💡 [수정] 구체적인 정보가 담긴 타이틀 생성
  String _getDetailTitle(ChampionModel firstEntry) {
    String year = '';
    String week = '';

    print('weekKey: ${firstEntry.weekKey}');

    try {
      // "2025-W12" -> ["2025", "12"]
      final parts = firstEntry.weekKey.split('-W');
      if (parts.length == 2) {
        year = '${parts[0]}년 ';
        week = '${int.parse(parts[1])}주차 '; // "01" -> "1"
      }
    } catch (_) {}

    // 예: "2025년 12주차 서울 강남구 베스트 픽"
    return '$year$week${firstEntry.regionCity} 베스트 픽';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (champions.isEmpty) return const SizedBox.shrink();

    final first = champions.isNotEmpty ? champions[0] : null;
    final second = champions.length > 1 ? champions[1] : null;
    final third = champions.length > 2 ? champions[2] : null;

    // 💡 동적 타이틀
    final String title = first != null ? _getDetailTitle(first) : '이번 주 베스트 픽';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(championProvider);
      },
      color: AppColor.primary,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // 1. 헤더: 구체적인 타이틀 (년도/주차/지역)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp, // 너무 길어질 수 있어 사이즈 약간 조정
                  fontWeight: FontWeight.w800,
                  color: AppColor.black,
                  height: 1.3,
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // 2. 포디움 디스플레이
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Place
                  if (second != null)
                    Expanded(child: _buildPodiumItem(second, 2)),

                  // 1st Place
                  if (first != null) _buildPodiumItem(first, 1),

                  // 3rd Place
                  if (third != null)
                    Expanded(child: _buildPodiumItem(third, 3)),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // 3. 🎁 [수정] 뱃지 시스템 안내 반영
            if (first != null) _buildRewardInfoCard(),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // 💡 [수정] 골드/실버/브론즈 뱃지 시스템을 반영한 보상 안내 카드
  Widget _buildRewardInfoCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppColor.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 💡 [수정] 빛나는 아이콘(auto_awesome)으로 변경
                Icon(Icons.auto_awesome, color: Colors.amber, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  'Champion Rewards',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.black,
                  ),
                ),
                SizedBox(width: 8.w),
                // 💡 [수정] 빛나는 아이콘(auto_awesome)으로 변경
                Icon(Icons.auto_awesome, color: Colors.amber, size: 24.w),
              ],
            ),
            SizedBox(height: 16.h),

            // 혜택 내용 수정
            Text(
              '각 지역 상위 3명의 유저에게는\n순위에 맞는 스페셜 뱃지가 수여됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),

            // 보상 아이콘 (골드, 실버, 브론즈 뱃지)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardItem(
                    Icons.emoji_events, '골드 뱃지', const Color(0xFFFFD700)),
                SizedBox(width: 24.w),
                _buildRewardItem(
                    Icons.emoji_events, '실버 뱃지', const Color(0xFFC0C0C0)),
                SizedBox(width: 24.w),
                _buildRewardItem(
                    Icons.emoji_events, '브론즈 뱃지', const Color(0xFFCD7F32)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 💡 [수정] 색상을 받을 수 있도록 파라미터 추가
  Widget _buildRewardItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.w),
          ),
          child: Icon(icon, color: color, size: 24.w),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(ChampionModel entry, int rank) {
    final isFirst = rank == 1;
    final double heightOffset = isFirst ? 0 : (rank == 2 ? 20.h : 30.h);
    final double avatarSize = isFirst ? 60.w : 50.w;

    final Color medalColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 💡 [수정] 아이콘 변경: military_tech_rounded -> emoji_events_rounded (왕관/트로피)
        if (isFirst)
          Icon(Icons.emoji_events_rounded, color: medalColor, size: 40.w)
        else
          SizedBox(height: 40.w),

        SizedBox(height: 10.h),

        Container(
          padding: EdgeInsets.all(isFirst ? 5.w : 3.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarSize,
            backgroundColor: AppColor.lightGrey,
            backgroundImage: entry.imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(entry.imageUrl)
                : null,
            child: entry.imageUrl.isEmpty
                ? Icon(Icons.person,
                    size: avatarSize * 0.8, color: AppColor.darkGrey)
                : null,
          ),
        ),
        SizedBox(height: 16.h),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '$rank위',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),

        TextGradiate(
          text: Text(
            "@${entry.snsId}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 16.sp : 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          colors: isFirst
              ? [const Color(0xFFFFD700), Colors.amber.shade800]
              : [Colors.black87, Colors.grey.shade700],
        ),

        SizedBox(height: 4.h),

        Text(
          "${entry.totalScore}점",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.sp,
          ),
        ),

        SizedBox(height: heightOffset),
      ],
    );
  }
}
