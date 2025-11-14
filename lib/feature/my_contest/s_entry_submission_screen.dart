// s_entry_submission_screen.dart (새로 생성할 파일)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_submission_form.dart';

class EntrySubmissionScreen extends StatelessWidget {
  static const String routeName = 'submit_entry';
  const EntrySubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('베스트 픽 참가 신청', style: TextStyle(fontSize: 18.sp)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          // 기존에 분리된 참가 폼 위젯을 여기에 포함하여 재사용
          child: const WEntrySubmissionForm(),
        ),
      ),
    );
  }
}