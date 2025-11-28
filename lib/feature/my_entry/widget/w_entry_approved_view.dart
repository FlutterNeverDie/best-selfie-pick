import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/provider/entry_provider.dart';

// 💡 분리된 위젯들 Import
import 'approved/w_entry_live_header.dart';
import 'approved/w_entry_photo_card.dart';
import 'approved/w_entry_vote_stats.dart';

import '../model/m_entry.dart';

class WEntryApprovedView extends ConsumerWidget {
  final EntryModel entry;

  const WEntryApprovedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEntryAsync = ref.watch(entryProvider);
    final EntryModel currentEntry = latestEntryAsync.value ?? entry;

    // 상태 확인 (투표 중인지)
    final bool isApproved = currentEntry.status == 'approved';

    // 💡 SingleChildScrollView 제거 (부모 Screen에서 처리)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        children: [
          // 1. ✨ 라이브 헤더
          WEntryLiveHeader(
            weekKey: currentEntry.weekKey,
            channel: currentEntry.channel,
            isPrivate: !isApproved, // 승인 상태가 아니면(private) 비공개
          ),

          SizedBox(height: 24.h),

          // 2. 🖼️ 포토 카드
          WEntryPhotoCard(
            photoUrl: currentEntry.thumbnailUrl,
            snsId: currentEntry.snsId,
          ),

          SizedBox(height: 36.h),

          // 3. 📊 투표 통계
          WEntryVoteStats(
            goldVotes: currentEntry.goldVotes,
            silverVotes: currentEntry.silverVotes,
            bronzeVotes: currentEntry.bronzeVotes,
          ),

          SizedBox(height: 36.h),

          // 4. ℹ️ 하단 안내 (심플하게)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20.w, color: Colors.grey.shade500),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "최종 순위는 매주 토요일 자정(00:00)\n챔피언 탭에서 발표됩니다.",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13.sp,
                        height: 1.4
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 여백 확보
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}