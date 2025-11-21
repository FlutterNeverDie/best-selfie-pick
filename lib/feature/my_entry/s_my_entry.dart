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

  // 새로고침 로직
  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(entryProvider);
    await ref.read(entryProvider.future);
  }

  // 비공개/공개 전환 시 광고(requiresAd: true) 적용
  Future<bool?> _showConfirmationDialog(BuildContext context, String action) async {
    final String title = action == 'private' ? '비공개 전환 확인' : '공개 전환 확인';
    final String content = action == 'private'
        ? '사진을 즉시 투표 대상에서 제외하고 비공개 상태로 전환합니다.\n(전환 시 5초 광고 시청)'
        : '사진을 다시 투표 목록에 노출하고 공개 상태로 전환합니다.\n(전환 시 5초 광고 시청)';

    return await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'change_entry_status'),
      builder: (context) => WCustomConfirmDialog(
        title: title,
        content: content,
        confirmText: action == 'private' ? '전환하기' : '공개하기',
        cancelText: '취소',
        requiresAd: true, // 광고 기능 활성화
      ),
    );
  }

  // 💡 [디자인 업그레이드] AppBar 우측 상단 메뉴
  Widget _buildStatusMenu(BuildContext context, WidgetRef ref, EntryModel entry) {
    final isPrivate = entry.status == 'private';
    final isApproved = entry.status == 'approved';

    // 투표 진행 중(approved) 또는 비공개 상태(private)일 때만 메뉴 노출
    if (!isApproved && !isPrivate) return const SizedBox.shrink();

    final notifier = ref.read(entryProvider.notifier);
    final action = isApproved ? 'private' : 'public';

    // 상태에 따른 디자인 테마 설정
    final isDestructive = isApproved; // 비공개 전환은 약간 파괴적(경고) 느낌
    final Color themeColor = isDestructive ? Colors.redAccent : Colors.green;
    final IconData iconData = isDestructive ? Icons.lock_outline_rounded : Icons.public_rounded;
    final String labelText = isDestructive ? '비공개로 전환' : '공개로 전환';

    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: PopupMenuButton<String>(
        routeSettings: const RouteSettings(name: 'entry_status_menu'),
        // 🎨 메뉴 팝업 스타일링
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
        offset: Offset(0, 50.h), // 버튼 바로 아래가 아니라 약간 띄워서 표시
        color: Colors.white,
        surfaceTintColor: Colors.white, // 머티리얼 3 틴트 제거

        // 🎨 트리거 아이콘 스타일링
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // 반투명 배경
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_horiz_rounded, // 세로 점보다 가로 점이 더 안정적
            color: Colors.white,
            size: 24.w,
          ),
        ),

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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(action == 'private' ? '비공개로 전환되었습니다.' : '공개로 전환되었습니다.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('상태 변경 실패: ${e.toString().split(':').last.trim()}')),
                  );
                }
              }
            }
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: action,
            height: 60.h, // 아이템 높이 확보
            child: Row(
              children: [
                // 아이콘 박스
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Icon(iconData, color: themeColor, size: 20.w),
                ),
                SizedBox(width: 12.w),

                // 텍스트
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isDestructive ? '투표 목록에서 숨깁니다' : '투표 목록에 노출합니다',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider);
    final EntryModel? entryModel = entryAsync.value;

    return Scaffold(
      appBar: AppBar(
          title: const Text('내 참가 현황'),
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (entryModel != null && (entryModel.status == 'approved' || entryModel.status == 'private'))
              _buildStatusMenu(context, ref, entryModel),
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