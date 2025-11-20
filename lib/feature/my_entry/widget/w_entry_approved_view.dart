import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget 사용
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/provider/entry_provider.dart';
import '../../../core/theme/colors/app_color.dart';
import '../../../shared/widget/w_cached_image.dart';
import '../model/m_entry.dart';

// 투표 진행 중 상태를 표시하며, EntryNotifier의 상태 변화에 따라 리빌드됩니다.
// 실시간 득표는 EntryNotifier의 stream을 직접 watch하여 처리됩니다.
class WEntryApprovedView extends ConsumerWidget {
  final EntryModel entry; // 초기 데이터

  const WEntryApprovedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. EntryNotifier의 최신 상태를 감시합니다.
    final latestEntryAsync = ref.watch(entryProvider);

    // 2. Notifier의 최신 데이터를 사용하거나, 초기 데이터를 사용합니다.
    final EntryModel currentEntry = latestEntryAsync.value ?? entry;

    // 3. 상태 분기
    final isVotingActive = currentEntry.status == 'approved';

    // 💡 Padding으로 감싸서 상위 SingleChildScrollView의 여백을 확보합니다.
    return Padding(
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 헤더 및 상태 ---
          Text(
            isVotingActive ? "투표 진행 중" : "비공개",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isVotingActive ? AppColor.primary : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '[${currentEntry.weekKey}] ${currentEntry.regionCity} 참가 중',
            style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 16.sp),
          ),
          Divider(height: 30.h),

          // --- 등록된 사진 및 SNS ID ---
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 300.h,
                  width: 300.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.w),
                    child: WCachedImage(
                      imageUrl: currentEntry.photoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '@${currentEntry.snsId}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 18.sp),
                ),
              ],
            ),
          ),
          Divider(height: 30.h),

          // --- 상세 득표 수 현황 ---
          Text('실시간 득표 현황',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 15.h),

          // 득표 수 현황 (currentEntry의 최신 goldVotes 등을 반영)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVoteStat(context, '금 (5점)', currentEntry.goldVotes, Colors.amber),
              _buildVoteStat(context, '은 (3점)', currentEntry.silverVotes, Colors.blueGrey),
              _buildVoteStat(context, '동 (1점)', currentEntry.bronzeVotes, Colors.brown),
            ],
          ),
          SizedBox(height: 30.h),

          Center(
            child: Text(
              "최종 순위는 매주 토요일 00:00 (자정)\n챔피언 탭에서 발표됩니다.",
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteStat(
      BuildContext context, String label, int count, Color color) {
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
        Text(label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}