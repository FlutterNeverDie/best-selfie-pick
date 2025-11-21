import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WLoadingOverlay extends StatelessWidget {
  final String message;

  const WLoadingOverlay({
    super.key,
    this.message = '잠시만 기다려주세요...',
  });

  @override
  Widget build(BuildContext context) {
    // Stack 내부에서 전체를 덮기 위해 Container 사용
    return Container(
      color: Colors.black.withOpacity(0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3.w),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}