import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import '../provider/dialog/d_ranking_image_detail.dart';

class WRankingListItem extends StatelessWidget {
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
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.grey.shade400; // 기본 색상
    }
  }

  bool get isTopThree => rank <= 3;

  // 📋 ID 복사
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

  // 🔍 사진 확대 다이얼로그 호출
  void _showFullScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => RankingImageDetailDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final double verticalPadding = isTopThree ? 16.h : 12.h;
    final double avatarSize = isTopThree ? 58.w : 46.w;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isTopThree ? rankColor.withOpacity(0.15) : Colors.black.withOpacity(0.03),
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
          onTap: () => _showFullScreenDialog(context), // 💡 탭하면 다이얼로그

          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: verticalPadding),
            child: Row(
              children: [
                // 1. 순위 표시 (Top 3: 아이콘, 나머지: 숫자)
                SizedBox(
                  width: 32.w,
                  child: Center(
                    child: isTopThree
                    // 💡 요청하신 대로 emoji_events 아이콘 통일 + 색상 변경
                        ? Icon(Icons.emoji_events, color: rankColor, size: 30.w)
                        : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
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
                      errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
                    )
                        : Icon(Icons.person, color: Colors.grey.shade300),
                  ),
                ),
                SizedBox(width: 16.w),

                // 3. SNS ID (Top 3는 Shimmer)
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

                // 4. 우측 아이콘: 복사 기능 (독립 터치)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copySnsId(context),
                    borderRadius: BorderRadius.circular(20.w),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                          Icons.content_copy_rounded,
                          color: Colors.grey.shade300,
                          size: 20.w
                      ),
                    ),
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