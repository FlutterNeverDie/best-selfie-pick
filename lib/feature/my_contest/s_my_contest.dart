// s_my_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_contest/provider/entry_provider.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_approved_view.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_not_entered_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_status_view.dart.dart';

import '../../core/theme/colors/app_color.dart'; // ScreenUtil import

class MyEntryScreen extends ConsumerWidget {
  static const String routeName = '/my_entry';
  const MyEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI는 오직 Notifier의 상태만 감시
    final entryAsync = ref.watch(entryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 참가 현황'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: entryAsync.when(
        // 1. 로딩 상태
        loading: () => Center(child: CircularProgressIndicator(value: 30.w)),

        // 2. 에러 상태
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.0.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40.w),
                SizedBox(height: 10.h),
                Text('데이터 로드 실패: $err', textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => ref.invalidate(entryProvider),
                  child: Text('다시 시도', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          ),
        ),

        // 3. 데이터 로드 완료 상태
        data: (entryModel) {
          // A. 미참가 상태 (EntrySubmissionForm 제거)
          if (entryModel == null) {
            return const WEntryNotEnteredView();
          }

          // B. 참가 완료 상태
          switch (entryModel.status) {
            case 'pending':
              return WEntryStatusView(
                entry: entryModel,
                statusText: '관리자 승인 대기 중',
                color: Colors.orange,
                icon: Icons.access_time,
              );
            case 'rejected':
              return WEntryStatusView(
                entry: entryModel,
                statusText: '사진 반려됨',
                color: Colors.red,
                icon: Icons.cancel,
                message: '죄송합니다. 등록된 사진이 운영 정책에 위배되어 반려되었습니다. 재신청은 챔피언 탭에서 가능합니다.',
                // 재신청 버튼을 CTA 유도로 변경
                showResubmitButton: true,
              );
            case 'approved':
            // TODO: ContestStatusNotifier 감시 로직은 WEntryApprovedView 내부에서 처리하는 것을 권장
              return WEntryApprovedView(entry: entryModel);
            default:
              return Center(child: Text('알 수 없는 참가 상태입니다.', style: TextStyle(fontSize: 16.sp)));
          }
        },
      ),
    );
  }
}