import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/colors/app_color.dart';

extension FlushBarContextExtension on BuildContext {
  void showFlushBar(
      {required BuildContext context,
      required String msg,
      required Color bgColor,
      String title = '알림',
        Color textColor = Colors.white,
      seconds = 2}) {
    Flushbar(
      title: title,
      titleSize: 15.sp,
      message: msg,
      messageSize: 15.sp,
      messageColor: textColor,
      backgroundColor: bgColor,
      duration: Duration(seconds: seconds),
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 0),
      borderRadius: BorderRadius.circular(12.r),
    ).show(context);
  }

  void showFlushBarLime(
      {required BuildContext context,
        required String msg,
        String title = '알림',
        seconds = 2}) {
    Flushbar(
      title: title,
      titleSize: 15.sp,
      message: msg,
      messageSize: 15.sp,
      backgroundColor: AppColor.black.withOpacity(0.8),
      titleColor: AppColor.white,
      messageColor: AppColor.lime,
      duration: Duration(seconds: seconds),
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 0),
      borderRadius: BorderRadius.circular(12.r),
    ).show(context);
  }


}
