import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import 'package:selfie_pick/feature/my_entry/provider/entry_provider.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_approved_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_not_entered_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_pending_view.dart';
import 'package:selfie_pick/feature/my_entry/widget/w_entry_rejected_view.dart';

import '../../core/theme/colors/app_color.dart';
import '../../shared/dialog/w_custom_confirm_dialog.dart';
import 'model/m_entry.dart';

class MyEntryScreen extends ConsumerWidget {
  static const String routeName = '/my_entry';
  const MyEntryScreen({super.key});

  // 새로고침 로직: EntryNotifier를 무효화하고 재빌드합니다.
  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(entryProvider);
    await ref.read(entryProvider.future);
  }

  // 💡 비공개 전환 확인 커스텀 다이얼로그 (alert() 사용 금지)
  // 💡 커스텀 다이얼로그를 사용하는 로직으로 변경 (문구 간결화)
  Future<bool?> _showConfirmationDialog(BuildContext context, String action) async {
    final String title = action == 'private' ? '비공개 전환 확인' : '공개 전환 확인';
    final String content = action == 'private'
        ? '사진을 즉시 투표 대상에서 제외하고 비공개 상태로 전환합니다. 다시 공개로 되돌릴 수 없습니다.'
        : '사진을 다시 투표 목록에 노출하고 공개 상태로 전환합니다.';

    return await showDialog<bool>(
      context: context,
      routeSettings: RouteSettings(name: 'change_entry_status'),
      builder: (context) => WCustomConfirmDialog(
        title: title,
        content: content,
        confirmText: action == 'private' ? '전환하기' : '공개하기',
        cancelText: '취소',
      ),
    );
  }

  // 💡 AppBar 우측 상단 메뉴 빌더
  Widget _buildStatusMenu(BuildContext context, WidgetRef ref, EntryModel entry) {
    final isPrivate = entry.status == 'private';
    final isApproved = entry.status == 'approved';

    // 투표 진행 중(approved) 또는 비공개 상태(private)일 때만 메뉴 노출
    if (!isApproved && !isPrivate) return const SizedBox.shrink();

    final notifier = ref.read(entryProvider.notifier);
    final action = isApproved ? 'private' : 'public';
    final icon = isApproved ? Icons.lock : Icons.public;
    final text = isApproved ? '비공개로 전환' : '공개로 전환';

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == action) {
          final confirm = await _showConfirmationDialog(context, action);
          if (confirm == true) {
            try {
              if (action == 'private') {
                await notifier.setEntryPrivate();
              } else {
                await notifier.setEntryPublic();
              }
            } catch (e) {
              // 오류 발생 시 스낵바 등으로 처리 가능
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('상태 변경 실패: ${e.toString().split(':').last.trim()}')),
              );
            }
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: action,
          child: Row(
            children: [
              Icon(icon, color: isApproved ? AppColor.red : AppColor.primary),
              SizedBox(width: 8.w),
              Text(text, style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_vert, color: Colors.white, size: 24.w),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider);

    // EntryModel을 로드하여 상태에 따라 AppBar 메뉴를 결정합니다.
    final EntryModel? entryModel = entryAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 참가 현황'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (entryModel != null && entryModel.status == 'approved')
            _buildStatusMenu(context, ref, entryModel), // 💡 메뉴 추가
        ]
      ),
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

                // 💡 분리된 위젯 사용
                switch (entryModel.status) {
                  case 'pending':
                    return WEntryPendingView(entry: entryModel);
                  case 'rejected':
                    return WEntryRejectedView(entry: entryModel);
                  case 'approved': // 투표 진행 중
                  case 'private':  // 비공개 상태
                    return WEntryApprovedView(entry: entryModel);
                    // complted
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