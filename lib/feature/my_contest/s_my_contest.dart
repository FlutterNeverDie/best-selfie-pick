// lib/feature/my_contest/s_my_entry_screen.dart (RefreshIndicator 적용)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_contest/provider/entry_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 💡 분리된 위젯 파일 import
import 'package:selfie_pick/feature/my_contest/widget/w_entry_not_entered_view.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_approved_view.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_pending_view.dart';
import 'package:selfie_pick/feature/my_contest/widget/w_entry_rejected_view.dart';

import '../../core/theme/colors/app_color.dart';

class MyEntryScreen extends ConsumerWidget {
  static const String routeName = '/my_entry';
  const MyEntryScreen({super.key});

  // 새로고침 로직: EntryNotifier를 무효화하고 재빌드합니다.
  Future<void> _onRefresh(WidgetRef ref) async {
    // ref.invalidate는 즉시 완료되므로, Notifier의 build() 완료를 기다립니다.
    // .future를 사용하여 새로운 데이터 로드가 완료될 때까지 기다립니다.
    ref.invalidate(entryProvider);
    await ref.read(entryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider);

    // RefreshIndicator로 body를 감쌉니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 참가 현황'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref), // 💡 새로고침 액션 연결
        color: AppColor.primary,
        child: SingleChildScrollView( // 💡 Pull-to-Refresh를 위한 스크롤 가능 위젯
          physics: const AlwaysScrollableScrollPhysics(), // 콘텐츠가 적어도 새로고침 가능하도록
          child: ConstrainedBox( // 화면 높이만큼 크기를 확장하여 Pull-to-Refresh 공간 확보
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: entryAsync.when(
              loading: () => Center(child: CircularProgressIndicator(value: 30.w)),
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
                        onPressed: () => _onRefresh(ref), // 버튼도 새로고침 로직 사용
                        child: Text('다시 시도', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ],
                  ),
                ),
              ),

              data: (entryModel) {
                if (entryModel == null) {
                  return const WEntryNotEnteredView();
                }

                // 💡 분리된 위젯 사용
                switch (entryModel.status) {
                  case 'pending':
                    return WEntryPendingView(entry: entryModel);
                  case 'rejected':
                    return WEntryRejectedView(entry: entryModel);
                  case 'approved':
                    return WEntryApprovedView(entry: entryModel);
                  default:
                    return Center(child: Text('알 수 없는 참가 상태입니다.', style: TextStyle(fontSize: 16.sp)));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}