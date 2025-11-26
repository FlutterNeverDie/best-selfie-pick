import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:text_gradiate/text_gradiate.dart';

import '../provider/champion_provider.dart'; // 그라데이션 타이틀용

class WChampionPodium extends ConsumerWidget {
  final List<EntryModel> champions;

  const WChampionPodium({super.key, required this.champions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (champions.isEmpty) return const SizedBox.shrink();

    final first = champions.isNotEmpty ? champions[0] : null;
    final second = champions.length > 1 ? champions[1] : null;
    final third = champions.length > 2 ? champions[2] : null;




    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(championProvider);
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // 1. 헤더: 명예의 전당 타이틀
            Text(
              '명예의 전당 🏆',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: AppColor.black,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 30.h),

            // 2. 포디움 디스플레이 (Stack 대신 Row + Spacer로 깔끔하게)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Place (왼쪽 하단)
                  if (second != null)
                    Expanded(child: _buildPodiumItem(second, 2)),

                  // 1st Place (중앙)
                  if (first != null)
                    _buildPodiumItem(first, 1),

                  // 3rd Place (오른쪽 하단)
                  if (third != null)
                    Expanded(child: _buildPodiumItem(third, 3)),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // 3. 우승자 소감 카드 (1위에게만)
            if (first != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🥇 1위 (${first.regionCity}) 우승 소감',
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        // 💡 [수정됨] 하드코딩된 기본 문구 사용
                        '"${first.snsId}님! 투표해주신 모든 분들께 감사드립니다! 다음 주에도 도전할게요."',
                        style: TextStyle(
                            fontSize: 16.sp, fontStyle: FontStyle.italic, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(EntryModel entry, int rank) {
    final isFirst = rank == 1;
    // Top 3 포디움 높이 차이를 주기 위한 공간 (1등은 0, 2등은 20, 3등은 30)
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
        // 1. 왕관/아이콘
        if (isFirst)
          Icon(Icons.military_tech_rounded, color: medalColor, size: 40.w)
        else
          SizedBox(height: 40.w), // 1등과 높이 맞추기 위해 공간 확보

        SizedBox(height: 10.h),

        // 2. 아바타 (BorderSize 조정)
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
            backgroundImage: entry.thumbnailUrl.isNotEmpty
                ? CachedNetworkImageProvider(entry.thumbnailUrl)
                : null,
            child: entry.thumbnailUrl.isEmpty
                ? Icon(Icons.person, size: avatarSize * 0.8, color: AppColor.darkGrey)
                : null,
          ),
        ),
        SizedBox(height: 16.h),

        // 3. 랭크 및 점수
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

        // 4. SNS ID (그라데이션 텍스트)
        TextGradiate(
          text: Text(
            "@${entry.snsId}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 16.sp : 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          colors: isFirst ? [const Color(0xFFFFD700), Colors.amber.shade800] : [Colors.black87, Colors.grey.shade700],
        ),

        SizedBox(height: 4.h),

        // 5. Score
        Text(
          "${entry.totalScore}점",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.sp,
          ),
        ),

        // 6. 포디움 높이 (핵심)
        SizedBox(height: heightOffset),
      ],
    );
  }
}