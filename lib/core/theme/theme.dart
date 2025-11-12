
import 'package:flutter/material.dart';

import 'colors/app_color.dart';

ThemeData buildThemeData(BuildContext context) {
  return ThemeData(
    scaffoldBackgroundColor: AppColor.scaffoldBackgroundColor,
    hintColor: AppColor.hintText,
    fontFamily: "Pretendard",


    //텍스트의 색상을 정의
    textTheme: Theme.of(context).textTheme.apply(
          //일반 텍스트 색상
          bodyColor: AppColor.black,
          //제목 및 헤더
          displayColor: AppColor.black,
          // 앱에서 사용할 글꼴
          fontFamily: "Pretendard",
          // 모든 텍스트의 크기를 증가시키는 추가 픽셀 -> 여기서 screenUtil을 사용할 수 없다!
          fontSizeDelta: 1.0,
        ),

    appBarTheme:  AppBarTheme(

      shadowColor: AppColor.black.withOpacity(0.2),
      backgroundColor: AppColor.appBarBackgroundColor,
      surfaceTintColor: AppColor.appBarBackgroundColor,
    ),

    //앱의 주요 색상을 정의
    primaryColor: AppColor.primary,
    //앱의 밝기 테마
    brightness: Brightness.light,
  );
}
