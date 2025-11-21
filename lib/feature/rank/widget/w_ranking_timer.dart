import 'dart:async';
import 'dart:ui'; // FontFeature 사용을 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';

class WRankingTimer extends StatefulWidget {
  const WRankingTimer({super.key});

  @override
  State<WRankingTimer> createState() => _WRankingTimerState();
}

class _WRankingTimerState extends State<WRankingTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    int daysUntilSaturday = DateTime.saturday - now.weekday;
    if (daysUntilSaturday <= 0) {
      daysUntilSaturday += 7;
    }

    DateTime deadline = DateTime(now.year, now.month, now.day + daysUntilSaturday);
    if (deadline.isBefore(now)) {
      deadline = deadline.add(const Duration(days: 7));
    }

    final diff = deadline.difference(now);

    if (mounted) {
      setState(() {
        _timeLeft = diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    // 💡 [디자인 변경]
    // 기존의 붉은 박스를 제거하고, 깔끔한 그레이/프라이머리 톤의 캡슐형 디자인 적용
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // 아주 연한 회색 배경
        borderRadius: BorderRadius.circular(20.w),
        // border: Border.all(color: Colors.grey.shade200), // 테두리는 선택 사항 (깔끔함을 위해 제거 추천)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 움직이는 시계 아이콘 대신 깔끔한 아이콘
          Icon(Icons.access_time_filled_rounded, size: 14.w, color: Colors.grey.shade600),
          SizedBox(width: 6.w),

          Text(
            '마감까지',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),

          // 시간 텍스트 (프라이머리 컬러로 포인트)
          Text(
            '${days}일 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColor.primary, // 브랜드 컬러 사용
              fontWeight: FontWeight.w900, // 두께감 있게
              fontFeatures: const [FontFeature.tabularFigures()], // 숫자 떨림 방지
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}