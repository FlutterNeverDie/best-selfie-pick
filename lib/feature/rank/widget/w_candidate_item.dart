import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/rank/provider/vote_provider.dart';
import 'package:selfie_pick/feature/report/provider/report_provider.dart';
import 'package:selfie_pick/shared/dialog/d_report.dart'; // 💡 신고 다이얼로그
import 'package:selfie_pick/shared/dialog/w_custom_confirm_dialog.dart'; // 💡 차단 다이얼로그
import '../../../shared/widget/w_cached_image.dart';

class WCandidateItem extends ConsumerWidget {
  final EntryModel candidate;

  const WCandidateItem({super.key, required this.candidate});

  // 🚨 신고 다이얼로그 호출
  void _showReportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: 'ReportDialog'),
      builder: (context) => ReportDialog(
        onReport: (reason, desc) async {
          final currentUser = ref.read(authProvider).user;
          if (currentUser == null) return;

          try {
            await ref.read(reportProvider.notifier).reportEntry(
              reporterUid: currentUser.uid,
              targetEntryId: candidate.entryId,
              targetUserUid: candidate.userId,
              reason: reason,
              description: desc,
              snsId: candidate.snsId,
              channel: candidate.channel,
              weekKey: candidate.weekKey,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('신고가 접수되어 차단되었습니다.')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('신고 처리 중 오류가 발생했습니다.')),
              );
            }
          }
        },
      ),
    );
  }

  // 🚫 차단 다이얼로그 호출
  void _showBlockDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'BlockConfirmDialog'),
      builder: (context) => const WCustomConfirmDialog(
        title: '이 사용자를 차단하시겠습니까?',
        content: '차단하면 앞으로 이 사용자의 게시물이\n보이지 않게 됩니다.',
        confirmText: '차단하기',
        cancelText: '취소',
        requiresAd: false,
      ),
    );

    if (result == true) {
      try {
        await ref.read(reportProvider.notifier).blockUser(
          targetUserId: candidate.userId,
          snsId: candidate.snsId,
          channel: candidate.channel,
          weekKey: candidate.weekKey,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('해당 사용자를 차단했습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('차단 처리 중 오류가 발생했습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPicks = ref.watch(voteProvider.select((s) => s.selectedPicks));
    final int selectedIndex = selectedPicks.indexWhere((e) => e.entryId == candidate.entryId);
    final bool isSelected = selectedIndex != -1;

    // 💡 본인 확인
    final currentUser = ref.watch(authProvider).user;
    final bool isMe = currentUser?.uid == candidate.userId;

    Color borderColor = Colors.transparent;
    const IconData badgeIcon = Icons.emoji_events;

    if (isSelected) {
      if (selectedIndex == 0) borderColor = const Color(0xFFFFD700);
      else if (selectedIndex == 1) borderColor = const Color(0xFFC0C0C0);
      else if (selectedIndex == 2) borderColor = const Color(0xFFCD7F32);
    }

    return GestureDetector(
      onTap: () => ref.read(voteProvider.notifier).togglePick(candidate),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade200,
            width: isSelected ? 3.w : 1.w,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 이미지
              WCachedImage(imageUrl: candidate.thumbnailUrl, fit: BoxFit.cover),

              // 2. 오버레이
              if (isSelected) Container(color: borderColor.withOpacity(0.2)),

              // 3. 그라데이션
              Positioned(
                bottom: 0, left: 0, right: 0, height: 40.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    ),
                  ),
                ),
              ),

              // 4. SNS ID
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  color: Colors.black.withOpacity(0.6),
                  child: Text(
                    '@${candidate.snsId}',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 5. 뱃지 (선택 시)
              if (isSelected)
                Positioned(
                  top: 8.h, right: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.w)],
                    ),
                    child: Icon(badgeIcon, color: borderColor, size: 20.w),
                  ),
                ),

              // 6. 번호 (선택 시)
              if (isSelected)
                Positioned(
                  top: 8.h, left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(12.w),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2.w)]
                    ),
                    child: Text('${selectedIndex + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  ),
                ),

              // 7. 🙋‍♂️ [Me Badge] 본인일 때 우측 상단
              if (!isSelected && isMe)
                Positioned(
                  top: 8.h, right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.w),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2.w)],
                    ),
                    child: Text("Me", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),

              // 8. 더보기 버튼 (신고/차단) - 타인일 때 우측 상단
              if (!isSelected && !isMe)
                Positioned(
                  top: 4.h, right: 4.w,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                        elevation: 4,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      routeSettings: const RouteSettings(name: 'CandidateItemPopupMenu'),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 120.w),
                      icon: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 18.w),
                      ),
                      onSelected: (value) {
                        if (value == 'report') _showReportDialog(context, ref);
                        else if (value == 'block') _showBlockDialog(context, ref);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'report',
                          height: 40.h,
                          child: Row(
                            children: [
                              Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('신고하기', style: TextStyle(fontSize: 13.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          height: 40.h,
                          child: Row(
                            children: [
                              Icon(Icons.block_rounded, color: Colors.grey.shade700, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('차단하기', style: TextStyle(fontSize: 13.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}