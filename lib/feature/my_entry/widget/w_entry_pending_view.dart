import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import '../../../shared/widget/w_cached_image.dart';

// 💡 애니메이션을 사용하기 위해 ConsumerStatefulWidget으로 변경
class WEntryPendingView extends ConsumerStatefulWidget {
  final EntryModel entry;

  const WEntryPendingView({super.key, required this.entry});

  @override
  ConsumerState<WEntryPendingView> createState() => _WEntryPendingViewState();
}

// 💡 SingleTickerProviderStateMixin 추가 (애니메이션 필수)
class _WEntryPendingViewState extends ConsumerState<WEntryPendingView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 1. 컨트롤러 설정 (2.5초 동안 1바퀴)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(); // 무한 반복

    // 2. 곡선 애니메이션 설정 (자연스러운 가속/감속)
    // Curves.easeInOutCubic: 천천히 시작 -> 중간에 빠름 -> 천천히 끝남 (쓱~ 도는 느낌)
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 메모리 누수 방지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 🖼️ 사진 위에 텍스트가 올라간 카드
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.w),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: 배경 이미지
                    WCachedImage(
                      imageUrl: widget.entry.thumbnailUrl, // widget.entry로 접근
                      fit: BoxFit.cover,
                    ),

                    // Layer 2: 어두운 오버레이
                    Container(
                      color: Colors.black.withOpacity(0.5),
                    ),

                    // Layer 3: 상태 아이콘 및 안내 텍스트
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 💡 아이콘 배경 (핑크색)
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.2), // 배경 핑크
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 1.w),
                              ),
                              // 💡 아이콘 회전 애니메이션 적용
                              child: RotationTransition(
                                turns: _animation, // 위에서 정의한 곡선 애니메이션 연결
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 40.w,
                                  color: Colors.white, // 아이콘 흰색
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // 제목 텍스트
                            Text(
                              '꼼꼼히 확인하고 있어요! 🧐',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),

                            // 설명 텍스트
                            Text(
                              '관리자 승인이 완료되면 투표 리스트에 공개됩니다.\n(보통 24시간 이내에 완료돼요)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
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
          ),

          SizedBox(height: 32.h),

          // 2. 📝 제출 정보 요약 박스
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today_rounded, '참가 회차', '${widget.entry.weekKey}차'),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(color: Colors.grey[300], height: 1),
                ),
                _buildInfoRow(Icons.location_on_rounded, '참가 지역', widget.entry.regionCity),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(color: Colors.grey[300], height: 1),
                ),
                _buildInfoRow(Icons.alternate_email_rounded, '홍보 ID', '@${widget.entry.snsId}', isHighlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 정보 행 빌더
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? AppColor.primary : Colors.black87,
          ),
        ),
      ],
    );
  }
}