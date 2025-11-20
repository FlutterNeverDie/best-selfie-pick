// lib/feature/my_entry/s_entry_submission_screen.dart (수정)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_submission_form.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart'; // AppColor import 가정

class EntrySubmissionScreen extends StatelessWidget {
  static const String routeName = 'submit_entry';
  const EntrySubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold의 기본 배경색을 약간 밝게 설정하여 컨텐츠에 깊이감을 줍니다.
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
            '베스트 픽 참가 신청',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold // 제목 폰트 강조
            )
        ),
        backgroundColor: AppColor.primary, // 테마 색상 사용
        foregroundColor: Colors.white,
        elevation: 4.w, // AppBar에 그림자를 주어 입체감 부여
      ),
      body: SingleChildScrollView(
        // 키보드 상태 변화에도 레이아웃이 안정적이도록 설정
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          // 수직 패딩을 상단에만 약간 주고, 컨텐츠는 폼 위젯에서 제어
          padding: EdgeInsets.only(top: 24.h, bottom: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 안내 배너 (선택 사항: 사용자에게 정책을 상기시킵니다)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(color: AppColor.primary.withOpacity(0.5), width: 1.w)
                ),
                child: Text(
                  '💡 참가 전, 마이페이지에서 지역 설정을 확인해 주세요.',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColor.primary,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // 2. 핵심 폼 위젯
              const WEntrySubmissionForm(),
            ],
          ),
        ),
      ),
    );
  }
}