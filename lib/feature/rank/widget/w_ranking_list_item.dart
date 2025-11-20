// w_ranking_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

/// 🎨 각 랭킹 아이템을 나타내는 재사용 가능한 StatelessWidget
class WRankingListItem extends StatelessWidget {
  final EntryModel entry;
  final int rank;

  const WRankingListItem({
    super.key,
    required this.entry,
    required this.rank,
  });

  Color _getRankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColor.lightGrey;
  }

  bool get isTopThree => rank <= 3;

  String _getRankOrdinal(int rank) {
    if (rank == 1) return '1st';
    if (rank == 2) return '2nd';
    if (rank == 3) return '3rd';
    return '${rank}th';
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final isFirst = rank == 1;

    // 💡 1~3위 크기 및 스타일 변수 설정
    final double verticalPadding = isTopThree ? 20.h : 12.h;
    final double elevation = isTopThree ? (isFirst ? 8.w : 4.w) : 1.w;
    final double avatarRadius = isTopThree ? (isFirst ? 32.w : 28.w) : 24.w;
    final double medalSize = isTopThree ? (isFirst ? 22.w : 18.w) : 0;
    final double fontSizeSns = isTopThree ? 18.sp : 16.sp;


    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        elevation: elevation,
        shadowColor: isTopThree ? rankColor.withOpacity(isFirst ? 0.6 : 0.3) : Colors.black12,
        child: InkWell(
          onTap: () {
            // TODO: 상세 보기 이동 로직
          },
          borderRadius: BorderRadius.circular(16.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: verticalPadding),
            decoration: BoxDecoration(
              border: isTopThree
                  ? Border.all(color: rankColor, width: 2.w)
                  : Border.all(color: AppColor.lightGrey.withOpacity(0.3), width: 0.5.w),
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: Row(
              children: [
                // 1. 🖼️ 프로필 사진 및 메달 오버레이
                _ProfileThumbnail(
                  entry: entry,
                  rankColor: rankColor,
                  isTopThree: isTopThree,
                  avatarRadius: avatarRadius,
                  medalSize: medalSize,
                ),
                SizedBox(width: 16.w),

                // 2. 👤 SNS ID (SelectableText 적용을 위해 별도 위젯으로 분리)
                Expanded(
                  child: _SnsIdText(
                    snsId: entry.snsId,
                    fontSize: fontSizeSns,
                    isTopThree: isTopThree,
                  ),
                ),

                // 3. 🥇 우측 끝에 순위 나열
                SizedBox(width: 16.w),
                Text(
                  _getRankOrdinal(rank),
                  style: TextStyle(
                    fontSize: isTopThree ? 20.sp : 16.sp,
                    fontWeight: isTopThree ? FontWeight.w900 : FontWeight.bold,
                    color: isTopThree ? rankColor : AppColor.darkGrey,
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

/// 💡 SelectableText를 적용한 SNS ID 위젯 (StatelessWidget으로 분리)
class _SnsIdText extends StatelessWidget {
  final String snsId;
  final double fontSize;
  final bool isTopThree;

  const _SnsIdText({
    required this.snsId,
    required this.fontSize,
    required this.isTopThree,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText( // 🚨 SelectableText 적용
      "@$snsId",
      maxLines: 1,
      // SelectableText는 overflow 대신 showCursor/toolbarOptions를 사용합니다.
      // overflow를 직접 설정할 수는 없으나, maxLines로 텍스트 잘림을 유도할 수 있습니다.
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
        color: Colors.black87,
      ),
      // 복사 기능을 위한 설정 (선택 사항)
      toolbarOptions: const ToolbarOptions(
        copy: true,
        selectAll: true,
        cut: false,
        paste: false,
      ),
    );
  }
}


/// 🖼️ 프로필 사진 + 메달 오버레이 위젯 (변경 없음)
class _ProfileThumbnail extends StatelessWidget {
  final EntryModel entry;
  final Color rankColor;
  final bool isTopThree;
  final double avatarRadius;
  final double medalSize;

  const _ProfileThumbnail({
    required this.entry,
    required this.rankColor,
    required this.isTopThree,
    required this.avatarRadius,
    required this.medalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 링 스타일 (1~3위만)
        Container(
          padding: isTopThree ? EdgeInsets.all(2.w) : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isTopThree
                ? Border.all(color: rankColor.withOpacity(0.8), width: 2.w)
                : null,
            boxShadow: isTopThree
                ? [BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 8.w)]
                : null,
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppColor.lightGrey,
            backgroundImage: entry.thumbnailUrl.isNotEmpty
                ? CachedNetworkImageProvider(entry.thumbnailUrl)
                : null,
            child: entry.thumbnailUrl.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: avatarRadius)
                : null,
          ),
        ),

        // 💡 트로피 메달 오버레이 (1~3위만)
        if (isTopThree)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.w,
                        offset: Offset(0, 1.w)
                    ),
                  ]
              ),
              child: Icon(
                Icons.emoji_events,
                color: rankColor,
                size: medalSize,
              ),
            ),
          ),
      ],
    );
  }
}