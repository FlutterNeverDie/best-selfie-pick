import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';

class WEntryLiveHeader extends StatefulWidget {
  final String weekKey;
  final String regionCity;
  final bool isPrivate;

  const WEntryLiveHeader({
    super.key,
    required this.weekKey,
    required this.regionCity,
    required this.isPrivate,
  });

  @override
  State<WEntryLiveHeader> createState() => _WEntryLiveHeaderState();
}

class _WEntryLiveHeaderState extends State<WEntryLiveHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. 지역 및 회차 정보
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.weekKey}차',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 18.w, color: Colors.black87),
                SizedBox(width: 4.w),
                Text(
                  widget.regionCity,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. 상태 배지 (라이브 or 비공개)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: widget.isPrivate ? Colors.grey.shade100 : AppColor.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20.w),
            border: Border.all(
              color: widget.isPrivate ? Colors.grey.shade300 : AppColor.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              if (!widget.isPrivate)
                FadeTransition(
                  opacity: _controller,
                  child: Container(
                    margin: EdgeInsets.only(right: 6.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent, // 라이브 빨간 점
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: Icon(Icons.lock_outline_rounded, size: 14.w, color: Colors.grey),
                ),

              Text(
                widget.isPrivate ? "비공개 상태" : "실시간 투표 중",
                style: TextStyle(
                  color: widget.isPrivate ? Colors.grey.shade600 : AppColor.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}