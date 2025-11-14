// lib/feature/ranking/widget/w_voting_overlay.dart (수정)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../provider/vote_provider.dart';

class WVotingOverlay extends ConsumerWidget {
  // 💡 final VoteNotifier notifier; 필드 제거됨

  const WVotingOverlay({super.key}); // 💡 생성자에서 notifier 제거

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 build 내부에서 VoteNotifier에 직접 접근
    final notifier = ref.read(voteProvider.notifier);

    // 💡 투표 상태 감시
    final selectedPicks = ref.watch(voteProvider.select((state) => state.selectedPicks));
    final isSubmitReady = selectedPicks.length == VoteNotifier.MAX_PICKS;

    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.w)],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // 1. 금/은/동 선택 현황 (유지)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(VoteNotifier.MAX_PICKS, (index) {
              final isPicked = index < selectedPicks.length;
              final label = index == 0 ? 'GOLD' : (index == 1 ? 'SILVER' : 'BRONZE');

              return Container(
                width: 70.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: isPicked ? AppColor.primary.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4.w),
                  border: Border.all(
                      color: isPicked ? AppColor.primary : Colors.grey.shade300,
                      width: 1.w
                  ),
                ),
                child: Center(
                  child: Text(
                    isPicked ? selectedPicks[index].snsId : label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isPicked ? AppColor.primary : Colors.grey.shade500,
                      fontWeight: isPicked ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.h),

          // 2. 투표 제출 버튼
          ElevatedButton(
            onPressed: isSubmitReady ? () => notifier.submitPicks() : null, // 💡 notifier 사용
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubmitReady ? AppColor.primary : Colors.grey,
              minimumSize: Size(double.infinity, 36.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.w)),
            ),
            child: Text(
              '베스프 픽 제출 (${selectedPicks.length}/${VoteNotifier.MAX_PICKS})',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}