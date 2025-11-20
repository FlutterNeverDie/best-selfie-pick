// w_ranking_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // 1~3위 순위 색상 정의 (골드, 실버, 브론즈)
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
    // 4위부터는 'th'
    return '${rank}th';
  }

  // 💡 커스텀 복사 로직: 길게 눌렀을 때 SNS ID를 복사합니다.
  void _copySnsId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '@${entry.snsId}')).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('@${entry.snsId} 복사 완료!'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final isFirst = rank == 1;

    // 💡 1~3위 크기 및 스타일 변수 설정
    final double verticalPadding = isTopThree ? 20.h : 12.h;
    final double elevation = isTopThree ? (isFirst ? 8.w : 4.w) : 1.w; // 그림자 강조
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
        child: GestureDetector( // InkWell 대신 GestureDetector를 사용하여 길게 누르기 이벤트를 처리합니다.
          onLongPress: () => _copySnsId(context), // 길게 눌러 복사 기능
          onTap: () {
            // TODO: 상세 보기 이동 로직
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: verticalPadding),
            decoration: BoxDecoration(
              // 💡 테두리 색상을 순위 색상으로 설정
              border: isTopThree
                  ? Border.all(color: rankColor, width: 2.w)
                  : Border.all(color: AppColor.lightGrey.withOpacity(0.3), width: 0.5.w),
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: Row(
              children: [
                // 1. 🖼️ 프로필 사진 및 메달 오버레이 (가장 좌측에 배치)
                _ProfileThumbnail(
                  entry: entry,
                  rankColor: rankColor,
                  isTopThree: isTopThree,
                  avatarRadius: avatarRadius,
                  medalSize: medalSize,
                ),
                SizedBox(width: 16.w),

                // 2. 👤 SNS ID (일반 Text로 복원)
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

/// 💡 일반 Text를 사용하는 SNS ID 위젯 (복사 로직은 상위 GestureDetector에 위임)
class _SnsIdText extends StatelessWidget {
  final String snsId;
  final double fontSize;
  final bool isTopThree;

  const _SnsIdText({
    super.key,
    required this.snsId,
    required this.fontSize,
    required this.isTopThree,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      "@$snsId",
      maxLines: 1,
      overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

/// 🖼️ 프로필 사진 + 메달 오버레이 위젯 (작게 분리된 StatelessWidget)
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