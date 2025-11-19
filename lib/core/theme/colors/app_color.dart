import 'package:flutter/material.dart';

// 고정 값을 저장해놓고 값의 변동이 없는 것들만 클래스로 만들자
class AppColor {
  AppColor._();
  static const primary = Colors.pinkAccent;
  static const scaffoldBackgroundColor = Color(0xFFF8F9FB);
  static const appBarBackgroundColor = Color(0xFCF8F9FB);
  static const bottomNavigationBackgroundColor = Color(0xFCF8F9FB);
  static const boldHintText = Color.fromARGB(255, 129, 128, 138);
  static const hintText = Color.fromARGB(255, 155, 154, 159);

  // 라임 강조색
  static const lime = Color(0xffA0D700);
  static const lightGrey = Color(0xFFEEEEEE);
  static const darkGrey = Color(0xFF757575);

  // black
  static const black = Color(0xFF000000);

  // white
  static const white = Color(0xFFFFFFFF);
  static const safeBackground = Color(0xFFFFFFFF);
}
