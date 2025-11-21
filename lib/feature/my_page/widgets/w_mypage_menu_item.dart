import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WMyPageMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showArrow;

  const WMyPageMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1.h),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22.sp, color: Colors.grey.shade500),
              SizedBox(width: 16.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.black87,
                ),
              ),
              const Spacer(),
              if (showArrow)
                Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}