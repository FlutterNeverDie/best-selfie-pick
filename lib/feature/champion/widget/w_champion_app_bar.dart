import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class WChampionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WChampionAppBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      // 1. 🎨 배경 디자인 (그라데이션 + 둥근 모서리) - MyEntryAppBar와 통일
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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.w),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,

      // 2. 타이틀 (아이콘 + 텍스트 + 그림자)
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 챔피언에 맞는 트로피 아이콘
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24.w),
          SizedBox(width: 8.w),
          Text(
            '명예의 전당',
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

      // 3. 둥근 모서리 적용 (Scaffold 배경과 자연스럽게 연결)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24.w),
        ),
      ),
    );
  }
}
