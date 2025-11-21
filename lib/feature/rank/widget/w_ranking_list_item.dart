import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../../../shared/service/uri_service.dart';
class WRankingListItem extends StatelessWidget {
  final EntryModel entry;
  final int rank;

  const WRankingListItem({
    super.key,
    required this.entry,
    required this.rank,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.transparent;
    }
  }

  bool get isTopThree => rank <= 3;

  void _copySnsId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '@${entry.snsId}')).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('@${entry.snsId} 복사 완료!', style: TextStyle(fontSize: 14.sp)),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();

    final double verticalPadding = isTopThree ? 16.h : 12.h;
    final double avatarSize = isTopThree ? 56.w : 44.w;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isTopThree ? rankColor.withOpacity(0.15) : Colors.black.withOpacity(0.05),
            blurRadius: isTopThree ? 10 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: isTopThree
            ? Border.all(color: rankColor.withOpacity(0.5), width: 1.5.w)
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.w),
          // 롱프레스 시: ID 복사
          onLongPress: () => _copySnsId(context),
          // 💡 [수정됨] 탭 시: SNS URL로 이동
          onTap: () {
            // snsUrl이 비어있으면 아무 동작 안 하거나 토스트 메시지를 띄울 수도 있습니다.
            // UrlLauncherUtil 내부에서 null 체크를 하므로 바로 호출해도 안전합니다.
            if (entry.snsUrl.isNotEmpty) {
              UrlLauncherUtil.launch(entry.snsUrl);
            } else {
              // (선택 사항) URL이 없을 경우 안내 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('등록된 링크가 없습니다.', style: TextStyle(fontSize: 14.sp)),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: verticalPadding),
            child: Row(
              children: [
                // 1. 순위 표시
                SizedBox(
                  width: 30.w,
                  child: Center(
                    child: isTopThree
                        ? Icon(Icons.emoji_events, color: rankColor, size: 28.w)
                        : Icon(Icons.circle, color: Colors.grey.shade300, size: 6.w),
                  ),
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
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => const Icon(Icons.person),
                    )
                        : Icon(Icons.person, color: Colors.grey.shade400),
                  ),
                ),
                SizedBox(width: 16.w),

                // 3. SNS ID (Shimmer 효과)
                Expanded(
                  child: isTopThree
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
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 4. 우측 화살표
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}