import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';
import '../../../shared/widget/w_cached_image.dart';

class WCandidateItem extends ConsumerWidget {
  final EntryModel candidate;

  const WCandidateItem({super.key, required this.candidate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPicks = ref.watch(voteProvider.select((s) => s.selectedPicks));
    final int selectedIndex = selectedPicks.indexWhere((e) => e.entryId == candidate.entryId);
    final bool isSelected = selectedIndex != -1;

    Color borderColor = Colors.transparent;

    // 💡 아이콘은 모두 'emoji_events'로 통일
    const IconData badgeIcon = Icons.emoji_events;

    if (isSelected) {
      if (selectedIndex == 0) {
        borderColor = const Color(0xFFFFD700); // Gold
      } else if (selectedIndex == 1) {
        borderColor = const Color(0xFFC0C0C0); // Silver
      } else if (selectedIndex == 2) {
        borderColor = const Color(0xFFCD7F32); // Bronze
      }
    }

    return GestureDetector(
      onTap: () {
        ref.read(voteProvider.notifier).togglePick(candidate);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade200,
            width: isSelected ? 3.w : 1.w,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 이미지
              WCachedImage(
                imageUrl:
                candidate.thumbnailUrl,
                fit: BoxFit.cover,
              ),

              // 2. 선택 시 오버레이
              if (isSelected)
                Container(color: borderColor.withOpacity(0.2)),

              // 3. 하단 그라데이션 (배경 박스가 생겼지만 깊이감을 위해 유지)
              Positioned(
                bottom: 0, left: 0, right: 0, height: 40.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    ),
                  ),
                ),
              ),

              // 4. SNS ID (💡 수정: 하단 밀착 및 왼쪽 정렬)
              Positioned(
                bottom: 0, left: 0, right: 0, // 하단 및 좌우 꽉 채움
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  color: Colors.black.withOpacity(0.6), // 반투명 배경 (라운딩 제거)
                  child: Text(
                    '@${candidate.snsId}',
                    textAlign: TextAlign.left, // 왼쪽 정렬
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 5. 🥇 순위 뱃지
              if (isSelected)
                Positioned(
                  top: 8.h, right: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.w)],
                    ),
                    child: Icon(
                      badgeIcon,
                      color: borderColor,
                      size: 20.w,
                    ),
                  ),
                ),

              // 6. 번호 표시
              if (isSelected)
                Positioned(
                  top: 8.h, left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(12.w),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2.w)]
                    ),
                    child: Text(
                      '${selectedIndex + 1}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}