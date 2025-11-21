import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WMyPageMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showArrow;

  const WMyPageMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 부모 배경 따름
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.grey.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
          child: Row(
            children: [
              // 아이콘 박스 (조금 더 이쁘게)
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.grey.shade600).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Icon(
                    icon,
                    size: 20.sp,
                    color: iconColor ?? Colors.grey.shade700
                ),
              ),

              SizedBox(width: 16.w),

              // 타이틀
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.black87,
                ),
              ),

              const Spacer(),

              // 화살표
              if (showArrow)
                Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}