import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 ConsumerWidget 사용을 위해 추가
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart'; // 💡 유저 정보 가져오기 위해 추가
import 'package:selfie_pick/feature/my_entry/widget/w_entry_submission_form.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class EntrySubmissionScreen extends ConsumerWidget {
  static const String routeName = 'submit_entry';
  const EntrySubmissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 현재 로그인된 유저의 채 정보를 가져옵니다.
    final user = ref.watch(authProvider).user;
    final userChannel = user?.channel ?? '채널 미설정';

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 배경을 아주 연한 회색으로 주어 폼과 구분감 형성
      appBar: AppBar(
        title: Text(
            '베스트 픽 참가 신청',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold
            )
        ),
        centerTitle: true, // 타이틀 중앙 정렬
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0, // 깔끔한 플랫 디자인
      ),
      body: SingleChildScrollView(
        // 사용자가 스크롤을 내리면 키보드가 자연스럽게 닫히도록 설정
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(top: 24.h, bottom: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 📍 현재 참가 채 확인 배지
              // 경고 문구 대신, "내가 어디에 내는지"를 깔끔하게 보여줍니다.
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.w), // 둥근 캡슐 모양
                      border: Border.all(color: AppColor.primary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 차지
                    children: [
                      Icon(Icons.location_on_rounded, size: 16.w, color: AppColor.primary),
                      SizedBox(width: 6.w),
                      Text(
                        '현재 참가 채널 : ',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userChannel,
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColor.primary,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // 2. 핵심 폼 위젯
              const WEntrySubmissionForm(),
            ],
          ),
        ),
      ),
    );
  }
}