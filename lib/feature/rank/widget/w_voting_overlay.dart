import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import '../provider/vote_provider.dart';

class WVotingOverlay extends ConsumerWidget {
  const WVotingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(voteProvider.notifier);
    final selectedPicks = ref.watch(voteProvider.select((state) => state.selectedPicks));
    final isSubmitReady = selectedPicks.length == VoteNotifier.MAX_PICKS;

    return Container(
      // 💡 높이를 고정하지 않고 내부 컨텐츠 + 패딩으로 결정 (유연성 확보)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)), // 라운딩 조금 더 줌
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -2))
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h), // 💡 패딩 넉넉하게 조정
      child: Column(
        mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
        children: [
          // 1. 🥇🥈🥉 슬롯
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(VoteNotifier.MAX_PICKS, (index) {
              final isPicked = index < selectedPicks.length;

              Color slotColor;
              String label;
              // 💡 아이콘 통일
              const IconData icon = Icons.emoji_events;

              if (index == 0) {
                slotColor = const Color(0xFFFFD700);
                label = '1st';
              } else if (index == 1) {
                slotColor = const Color(0xFFC0C0C0);
                label = '2nd';
              } else {
                slotColor = const Color(0xFFCD7F32);
                label = '3rd';
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 44.h, // 슬롯 높이 살짝 키움
                  decoration: BoxDecoration(
                    color: isPicked
                        ? slotColor.withOpacity(0.15)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(
                        color: isPicked ? slotColor : Colors.grey.shade300,
                        width: 1.5.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 18.w,
                          color: isPicked ? slotColor : Colors.grey.shade400),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          isPicked ? selectedPicks[index].snsId : label,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight:
                            isPicked ? FontWeight.bold : FontWeight.w500,
                            color: isPicked
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // 💡 2. 간격 벌리기 (요청하신 부분)
          SizedBox(height: 10.h),

          // 3. 제출 버튼
          ElevatedButton(
            onPressed: isSubmitReady ? () => notifier.submitPicks() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h), // 버튼 높이도 살짝 키움
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.w)),
            ),
            // 💡 텍스트 대신 아이콘+텍스트 조합 위젯 사용
            child: _buildButtonContent(selectedPicks.length, isSubmitReady),
          ),
        ],
      ),
    );
  }

  /// 💡 아이콘을 활용하여 짧고 직관적인 버튼 내용 반환
  Widget _buildButtonContent(int currentLength, bool isReady) {
    if (isReady) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_rounded, size: 20.w),
          SizedBox(width: 6.w),
          Text(
            '투표 완료',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    IconData icon;
    String text;

    switch (currentLength) {
      case 0:
        icon = Icons.looks_one_rounded;
        text = '1위 선택하기';
        break;
      case 1:
        icon = Icons.looks_two_rounded;
        text = '2위 선택하기';
        break;
      case 2:
        icon = Icons.looks_3_rounded;
        text = '3위 선택하기';
        break;
      default:
        icon = Icons.touch_app_rounded;
        text = '투표 진행';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Visibility(
            visible: currentLength > 2,
            child: Icon(icon, size: 20.w)),
        SizedBox(width: 6.w),
        Text(
          text,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}