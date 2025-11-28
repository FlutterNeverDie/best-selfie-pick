import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart'; // AppColor 추가
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/report/provider/report_provider.dart';
import 'package:selfie_pick/shared/dialog/w_custom_confirm_dialog.dart';
import '../provider/dialog/d_ranking_image_detail.dart';

class WRankingListItem extends ConsumerWidget {
  final EntryModel entry;
  final int rank;

  const WRankingListItem({
    super.key,
    required this.entry,
    required this.rank,
  });

  // 🎨 순위별 색상 Getter
  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey.shade400; // 기본 색상
    }
  }

  bool get isTopThree => rank <= 3;

  // 📋 ID 복사
  void _copySnsId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '@${entry.snsId}')).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('@${entry.snsId} 복사 완료!',
                style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(milliseconds: 1000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // 🔍 사진 확대 다이얼로그 호출
  void _showFullScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      routeSettings: const RouteSettings(name: RankingImageDetailDialog.routeName),
      builder: (context) => RankingImageDetailDialog(entry: entry),
    );
  }

  // 🚨 신고 다이얼로그 호출
  void _showReportDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const WCustomConfirmDialog(
        title: '이 게시물을 신고하시겠습니까?',
        content: '신고가 접수되면 해당 게시물은 즉시 차단되며,\n관리자 검토 후 처리됩니다.',
        confirmText: '신고하기',
        cancelText: '취소',
        requiresAd: false,
      ),
    );

    if (result == true) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) return;

      try {
        await ref.read(reportProvider.notifier).reportEntry(
          reporterUid: currentUser.uid,
          targetEntryId: entry.entryId,
          targetUserUid: entry.userId,
          reason: 'reported_in_ranking',
          description: 'User requested report from ranking list',
          snsId: entry.snsId,
          channel: entry.channel,
          weekKey: entry.weekKey,
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
    }
  }

  // 🚫 차단 다이얼로그 호출
  void _showBlockDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
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
          targetUserId: entry.userId,
          snsId: entry.snsId,
          channel: entry.channel,
          weekKey: entry.weekKey,
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
    final rankColor = _getRankColor();
    final double verticalPadding = isTopThree ? 16.h : 12.h;
    final double avatarSize = isTopThree ? 58.w : 46.w;

    // 💡 [New] 본인 확인
    final currentUser = ref.watch(authProvider).user;
    final bool isMe = currentUser?.uid == entry.userId;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? rankColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: isTopThree ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: isTopThree
            ? Border.all(color: rankColor.withOpacity(0.6), width: 1.5.w)
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.w),
          onLongPress: () => _copySnsId(context),
          onTap: () => _showFullScreenDialog(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: verticalPadding),
            child: Row(
              children: [
                // 1. 순위 표시
                SizedBox(
                  width: 32.w,
                  child: Center(
                      child: isTopThree
                          ? Icon(Icons.emoji_events,
                          color: rankColor, size: 30.w)
                          : Icon(Icons.circle, color: rankColor, size: 10.w)),
                ),
                SizedBox(width: 12.w),

                // 2. 프로필 사진
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTopThree ? rankColor : Colors.grey.shade200,
                      width: isTopThree ? 2.w : 1.w,
                    ),
                  ),
                  child: ClipOval(
                    child: entry.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: entry.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.person, color: Colors.grey),
                    )
                        : Icon(Icons.person, color: Colors.grey.shade300),
                  ),
                ),
                SizedBox(width: 16.w),

                // 3. SNS ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isTopThree
                          ? Shimmer.fromColors(
                        baseColor: Colors.black87,
                        highlightColor: rankColor,
                        period: const Duration(seconds: 2),
                        child: Text(
                          '@${entry.snsId}',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                          : Text(
                        '@${entry.snsId}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 4. 우측 액션 버튼 (본인: Me뱃지 / 타인: 더보기 메뉴)
                if (isMe)
                // 💡 [수정] 본인일 경우 'Me' 뱃지 표시
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _copySnsId(context),
                      borderRadius: BorderRadius.circular(20.w),
                      child: Container(
                        margin: EdgeInsets.all(8.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "Me",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                // 타인일 경우: 더보기 메뉴 (복사, 신고, 차단)
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w)),
                        elevation: 4,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 120.w),
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey.shade400, size: 20.w),
                      onSelected: (value) {
                        if (value == 'copy') {
                          _copySnsId(context);
                        } else if (value == 'report') {
                          _showReportDialog(context, ref);
                        } else if (value == 'block') {
                          _showBlockDialog(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy',
                          height: 40.h,
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded,
                                  color: Colors.grey.shade700, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('ID 복사',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'report',
                          height: 40.h,
                          child: Row(
                            children: [
                              Icon(Icons.report_gmailerrorred_rounded,
                                  color: Colors.redAccent, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('신고하기',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          height: 40.h,
                          child: Row(
                            children: [
                              Icon(Icons.block_rounded,
                                  color: Colors.grey.shade700, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('차단하기',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}