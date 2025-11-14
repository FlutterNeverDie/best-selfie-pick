// w_entry_approved_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../model/m_entry.dart';

class WEntryApprovedView extends StatelessWidget {
  final EntryModel entry;
  const WEntryApprovedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // TODO: ContestStatusNotifier를 감시하여 투표 진행 중인지, 마감 후 집계 중인지 판단하는 로직 추가

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 참가 주차 및 지역 정보
          Text(
            '[${entry.weekKey}] ${entry.regionCity} 참가 중',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '사진이 투표 대상에 정상적으로 노출되고 있습니다.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 14.sp),
          ),
          Divider(height: 30.h),

          // 등록된 사진 및 SNS ID
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.w),
                  child: Image.network(
                    entry.photoUrl,
                    height: 300.h,
                    fit: BoxFit.cover,
                    width: 300.w,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'SNS ID: ${entry.snsId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18.sp),
                ),
              ],
            ),
          ),
          Divider(height: 30.h),

          // 상세 득표 수 현황
          Text('실시간 득표 현황', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 15.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVoteStat(context, '금 (5점)', entry.goldVotes, Colors.amber),
              _buildVoteStat(context, '은 (3점)', entry.silverVotes, Colors.blueGrey),
              _buildVoteStat(context, '동 (1점)', entry.bronzeVotes, Colors.brown),
            ],
          ),
          SizedBox(height: 30.h),

          Center(
            child: Text(
              '* 최종 순위는 매주 토요일 00:00에 챔피언 탭에서 발표됩니다.',
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteStat(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30.w,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 24.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}