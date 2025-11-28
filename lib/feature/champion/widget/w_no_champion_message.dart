import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class WNoChampionMessage extends StatelessWidget {
  const WNoChampionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 아이콘과 배경
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 50.w,
                color: AppColor.primary.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),

            // 2. 메인 메시지
            Text(
              '아직 지난 주 챔피언이 없습니다',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),

            // 3. 서브 메시지 (참여 유도)
            Text(
              '베스트 픽에 도전하세요!\n투표는 매주 금요일 자정에 마감됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

          ],
        ),
      ),
    );
  }
}