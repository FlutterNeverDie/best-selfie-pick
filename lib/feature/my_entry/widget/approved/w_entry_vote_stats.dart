import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WEntryVoteStats extends StatelessWidget {
  final int goldVotes;
  final int silverVotes;
  final int bronzeVotes;

  const WEntryVoteStats({
    super.key,
    required this.goldVotes,
    required this.silverVotes,
    required this.bronzeVotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            '실시간 득표 현황',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            _buildStatCard('Gold', '5점', goldVotes, const Color(0xFFFFD700), Icons.emoji_events_rounded),
            SizedBox(width: 10.w),
            _buildStatCard('Silver', '3점', silverVotes, const Color(0xFFC0C0C0), Icons.emoji_events_rounded),
            SizedBox(width: 10.w),
            _buildStatCard('Bronze', '1점', bronzeVotes, const Color(0xFFCD7F32), Icons.emoji_events_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String scoreLabel, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: color.withOpacity(0.3), width: 1.w), // 테두리에 메달 색상
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1), // 그림자에도 살짝 색상
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.w),
            SizedBox(height: 8.h),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900, // 숫자 매우 강조
                color: Colors.black87,
                letterSpacing: -1.0,
              ),
            ),
            SizedBox(height: 4.h),
            Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: color)),
            Text('($scoreLabel)', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}