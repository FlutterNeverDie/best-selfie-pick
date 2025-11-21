import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:text_gradiate/text_gradiate.dart';

// 💡 타이머 위젯 Import
import '../provider/dialog/d_ranking_image_detail.dart';
import 'w_ranking_timer.dart';

class WRankingTopPodium extends StatelessWidget {
  final List<EntryModel> topThree;

  const WRankingTopPodium({super.key, required this.topThree});

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) return const SizedBox();

    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      // 💡 내부 패딩 조정 (상단 여백을 줄여 타이틀을 위로 올림)
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
          // 1. 🔥 실시간 핫 픽 타이틀
          Padding(
            // 하단 패딩을 줄여 타이머와 가깝게 배치
            padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
              children: [
                TextGradiate(
                  text: Text(
                    '실시간 핫 픽',
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

          // 2. ⏰ 타이머 (타이틀의 서브 텍스트처럼 배치)
          const WRankingTimer(),

          SizedBox(height: 24.h), // 타이머와 포디움 사이 간격 확보

          // 3. 포디움 스택
          SizedBox(
            height: 260.h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (second != null)
                  Positioned(
                    left: 16.w,
                    bottom: 0,
                    child: _buildPodiumItem(context, second, 2),
                  ),

                if (third != null)
                  Positioned(
                    right: 16.w,
                    bottom: 0,
                    child: _buildPodiumItem(context, third, 3),
                  ),

                if (first != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20.h,
                    child: Center(child: _buildPodiumItem(context, first, 1)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(BuildContext context, EntryModel entry, int rank) {
    final isFirst = rank == 1;

    final double cardWidth = isFirst ? 110.w : 90.w;
    final double cardHeight = isFirst ? 150.h : 120.h;

    Color rankColor;
    List<Color> gradientColors;
    String rankLabel;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
        rankLabel = '1st';
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        gradientColors = [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)];
        rankLabel = '2nd';
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        gradientColors = [const Color(0xFFFFAB91), const Color(0xFF8D6E63)];
        rankLabel = '3rd';
        break;
      default:
        rankColor = Colors.grey;
        gradientColors = [Colors.grey, Colors.black];
        rankLabel = '';
    }

    return GestureDetector(
      onTap: () {
        showDialog(
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
                    BoxShadow(color: rankColor.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))
                  ],
                ),
              )
            else
              SizedBox(height: 42.h),

            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isFirst ? 16.w : 12.w),
                border: Border.all(
                    color: rankColor.withOpacity(0.8),
                    width: isFirst ? 3.w : 2.w
                ),
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
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => const Icon(Icons.person),
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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
                                Shadow(color: Colors.black, blurRadius: 4.w),
                              ]
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8.h),


            Text(
              '@${entry.snsId}',
              style: TextStyle(
                fontSize: isFirst ? 14.sp : 12.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
/*            TextGradiate(
              text: Text(
                '@${entry.snsId}',
                style: TextStyle(
                  fontSize: isFirst ? 14.sp : 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              colors: gradientColors,
              gradientType: GradientType.linear,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),*/
          ],
        ),
      ),
    );
  }
}