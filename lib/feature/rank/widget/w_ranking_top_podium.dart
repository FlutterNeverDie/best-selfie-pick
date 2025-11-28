import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/feature/report/provider/report_provider.dart';
import 'package:selfie_pick/shared/dialog/d_report.dart'; // 💡 신고 다이얼로그
import 'package:selfie_pick/shared/dialog/w_custom_confirm_dialog.dart'; // 💡 차단 다이얼로그
import 'package:text_gradiate/text_gradiate.dart';

import 'w_ranking_timer.dart';
import '../provider/dialog/d_ranking_image_detail.dart';

class WRankingTopPodium extends ConsumerWidget {
  final List<EntryModel> topThree;
  final String channel;

  const WRankingTopPodium(
      {super.key, required this.topThree, required this.channel});

  // 📋 ID 복사 메서드
  void _copySnsId(BuildContext context, String snsId) {
    Clipboard.setData(ClipboardData(text: '@$snsId')).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('@$snsId 복사 완료!', style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(milliseconds: 1000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // 🚨 신고 다이얼로그
  void _showReportDialog(BuildContext context, WidgetRef ref, EntryModel entry) {
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
              targetEntryId: entry.entryId,
              targetUserUid: entry.userId,
              reason: reason,
              description: desc,
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
        },
      ),
    );
  }

  // 🚫 차단 다이얼로그
  void _showBlockDialog(BuildContext context, WidgetRef ref, EntryModel entry) async {
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
    if (topThree.isEmpty) return const SizedBox();

    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextGradiate(
                  text: Text(
                    '실시간 $channel 랭킹',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
                  ),
                  colors: [
                    Colors.pinkAccent.shade700,
                    Colors.purpleAccent,
                    Colors.deepPurpleAccent,
                  ],
                  gradientType: GradientType.linear,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                SizedBox(width: 4.w),
                Text('🔥', style: TextStyle(fontSize: 20.sp)),
              ],
            ),
          ),
          const WRankingTimer(),
          SizedBox(height: 24.h),
          SizedBox(
            height: 260.h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (second != null)
                  Positioned(
                    left: 16.w,
                    bottom: 0,
                    child: _buildPodiumItem(context, ref, second, 2),
                  ),
                if (third != null)
                  Positioned(
                    right: 16.w,
                    bottom: 0,
                    child: _buildPodiumItem(context, ref, third, 3),
                  ),
                if (first != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20.h,
                    child: Center(child: _buildPodiumItem(context, ref, first, 1)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(BuildContext context, WidgetRef ref, EntryModel entry, int rank) {
    final isFirst = rank == 1;
    final double cardWidth = isFirst ? 110.w : 90.w;
    final double cardHeight = isFirst ? 150.h : 120.h;

    final currentUser = ref.watch(authProvider).user;
    final bool isMe = currentUser?.uid == entry.userId;

    Color rankColor;
    String rankLabel;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        rankLabel = '1st';
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankLabel = '2nd';
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankLabel = '3rd';
        break;
      default:
        rankColor = Colors.grey;
        rankLabel = '';
    }

    final baseTextStyle = TextStyle(
      fontSize: isFirst ? 14.sp : 12.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      overflow: TextOverflow.ellipsis,
    );

    return GestureDetector(
      onTap: () {
        showDialog(
          routeSettings: const RouteSettings(name: RankingImageDetailDialog.routeName),
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          builder: (context) => RankingImageDetailDialog(entry: entry),
        );
      },
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFirst)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: rankColor,
                  size: 36.w,
                  shadows: [
                    BoxShadow(
                        color: rankColor.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
                ),
              )
            else
              SizedBox(height: 42.h),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isFirst ? 16.w : 12.w),
                    border: Border.all(
                        color: rankColor.withOpacity(0.8),
                        width: isFirst ? 3.w : 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withOpacity(isFirst ? 0.4 : 0.2),
                        blurRadius: isFirst ? 15 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isFirst ? 13.w : 10.w),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: entry.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[100]),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.person),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8)
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Text(
                              rankLabel,
                              style: TextStyle(
                                  color: rankColor,
                                  fontSize: isFirst ? 24.sp : 18.sp,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black, blurRadius: 4.w),
                                  ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isMe)
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10.w),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 2.w)
                        ],
                      ),
                      child: Text(
                        "Me",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (!isMe)
                  Positioned(
                    top: 2.h,
                    right: 2.w,
                    child: Theme(
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
                        routeSettings: const RouteSettings(name: 'EntryOptionsMenu'),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 120.w),
                        icon: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.more_vert_rounded,
                              color: Colors.white, size: 16.w),
                        ),
                        onSelected: (value) {
                          if (value == 'copy') {
                            _copySnsId(context, entry.snsId);
                          } else if (value == 'report') {
                            _showReportDialog(context, ref, entry);
                          } else if (value == 'block') {
                            _showBlockDialog(context, ref, entry);
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
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Shimmer.fromColors(
              baseColor: Colors.black87,
              highlightColor: rankColor,
              period: const Duration(seconds: 2),
              child: Text(
                '@${entry.snsId}',
                style: baseTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}