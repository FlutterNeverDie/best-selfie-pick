// lib/feature/ranking/widget/w_no_candidates_message.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WNoCandidatesMessage extends StatelessWidget {
  const WNoCandidatesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 60.w, color: Colors.grey.shade400),
          SizedBox(height: 15.h),
          Text(
            '아직 이 지역에 참가자가 없습니다.',
            style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5.h),
          Text(
            '첫 번째 베스트 픽에 도전해 보세요!',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}