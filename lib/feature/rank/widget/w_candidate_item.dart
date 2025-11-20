// lib/feature/ranking/widget/w_candidate_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../provider/vote_provider.dart';

class WCandidateItem extends ConsumerWidget {
  final EntryModel candidate;

  const WCandidateItem({
    super.key,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 선택 상태 감지
    final isSelected = ref.watch(voteProvider.select(
          (state) => state.selectedPicks.contains(candidate),
    ));
    final notifier = ref.read(voteProvider.notifier);

    // 💡 선택 시 배경 색상 및 테두리 효과
    final itemColor = isSelected ? AppColor.primary.withOpacity(0.8) : Colors.white;

    return GestureDetector(
      onTap: () {
        notifier.toggleCandidatePick(candidate);
      },
      child: Container(
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(8.w),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColor.primary.withOpacity(0.4), blurRadius: 4.w)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 💡 후보 이미지 (Placeholder 사용)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
                child: Image.network(
                  candidate.thumbnailUrl, // EntryModel의 썸네일 URL 사용
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: Icon(Icons.person, size: 40.w)),
                ),
              ),
            ),

            // 💡 SNS ID
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Text(
                '@${candidate.snsId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}