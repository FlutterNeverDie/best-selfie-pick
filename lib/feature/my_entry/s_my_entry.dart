import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:selfie_pick/feature/my_entry/provider/entry_provider.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_approved_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_not_entered_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_pending_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_rejected_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_my_entry_app_bar.dart';

import '../../core/theme/colors/app_color.dart';
import '../../shared/dialog/w_custom_confirm_dialog.dart';
import 'model/m_entry.dart';

class MyEntryScreen extends ConsumerWidget {
  static const String routeName = '/my_entry';
  const MyEntryScreen({super.key});

  // 새로고침 로직
  Future<void> _onRefresh(WidgetRef ref) async {

    // 참가 안했으면 바로 리턴
    final entryAsync = ref.read(entryProvider);
    if (entryAsync.value == null) {
      return;
    }

    ref.invalidate(entryProvider);
    await ref.read(entryProvider.future);
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider);

    return Scaffold(
      appBar: WMyEntryAppBar(),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        color: AppColor.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: entryAsync.when(
              loading: () => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary))),
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
                        onPressed: () => _onRefresh(ref),
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

                debugPrint('[내 참가 상태 : ${entryModel.status}]');

                switch (entryModel.status) {
                  case 'pending':
                    return WEntryPendingView(entry: entryModel);
                  case 'rejected':
                    return WEntryRejectedView(entry: entryModel);
                  case 'approved': // 투표 진행 중
                  case 'private':  // 비공개 상태
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