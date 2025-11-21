import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';

class WRankingAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WRankingAppBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 투표 상태 감시
    final voteState = ref.watch(voteProvider);
    final bool isVoted = voteState.isVoted;

    // 상태에 따른 UI 분기
    final String title = isVoted ? '실시간 랭킹' : '베스트 픽 투표';
    final IconData icon = isVoted ? Icons.bar_chart_rounded : Icons.how_to_vote_rounded;

    return AppBar(
      // 1. 🎨 배경 디자인 (그라데이션)
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColor.primary,
              AppColor.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // 하단 둥근 모서리 적용
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.w),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,

      // 2. 타이틀 (아이콘 + 텍스트)
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24.w,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4.0,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),

      // 3. 둥근 모서리 (AppBar 자체 속성)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24.w),
        ),
      ),

/*      // 4. (선택 사항) 우측 액션 버튼 - 랭킹 모드일 때 새로고침 버튼 등 추가 가능
      actions: [
        if (isVoted)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: '새로고침',
            onPressed: () {
              ref.read(voteProvider.notifier).loadCandidates();
            },
          ),
      ],*/
    );
  }
}