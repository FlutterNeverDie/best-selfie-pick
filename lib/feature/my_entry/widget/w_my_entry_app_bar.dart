import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors/app_color.dart';
import '../../../../shared/dialog/w_custom_confirm_dialog.dart';
import '../model/m_entry.dart';
import '../provider/entry_provider.dart';

class WMyEntryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WMyEntryAppBar({super.key});

  // 💡 AppBar의 높이를 설정 (기본보다 조금 더 시원하게)
  @override
  Size get preferredSize => Size.fromHeight(60.h);

  // --- 🔒 비공개/공개 전환 로직 (화면에서 분리됨) ---
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
        requiresAd: true, // 광고 필수
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 여기서 상태를 구독하여, 데이터가 있을 때만 메뉴를 보여줍니다.
    final entryAsync = ref.watch(entryProvider);
    final EntryModel? entryModel = entryAsync.value;

    // 메뉴 표시 조건
    final bool showMenu = entryModel != null &&
        (entryModel.status == 'approved' || entryModel.status == 'private');

    return AppBar(
      // 1. 🎨 배경 디자인 (그라데이션)
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColor.primary,
              AppColor.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // 하단 둥근 모서리 적용
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.w),
          ),
        ),
      ),
      backgroundColor: Colors.transparent, // 배경색 투명 (Container가 대신함)
      elevation: 0, // 그림자 제거 (깔끔하게)
      centerTitle: true, // 타이틀 중앙 정렬

      // 2. 타이틀
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 24.w),
          SizedBox(width: 8.w),
          Text(
            '내 참가 현황',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4.0,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),

      // 3. 둥근 모서리 (AppBar 자체 속성)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24.w),
        ),
      ),

      // 4. 우측 메뉴 (조건부 노출)
      actions: [
        if (showMenu)
          _buildStatusMenu(context, ref, entryModel!),
      ],
    );
  }

  // 💡 메뉴 빌더 (기존 로직 유지 + 디자인 적용)
  Widget _buildStatusMenu(BuildContext context, WidgetRef ref, EntryModel entry) {
    final notifier = ref.read(entryProvider.notifier);
    final isApproved = entry.status == 'approved';

    final isDestructive = isApproved;
    final Color themeColor = isDestructive ? Colors.redAccent : Colors.green;
    final IconData iconData = isDestructive ? Icons.lock_outline_rounded : Icons.public_rounded;
    final String labelText = isDestructive ? '비공개로 전환' : '공개로 전환';
    final String action = isDestructive ? 'private' : 'public';

    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: PopupMenuButton<String>(
        offset: Offset(0, 50.h),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
        color: Colors.white,
        surfaceTintColor: Colors.white,

        // 트리거 아이콘 (흰색 반투명 원형 버튼)
        icon: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24.w),
        ),

        onSelected: (_) async {
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
                  SnackBar(content: Text(isDestructive ? '비공개로 전환되었습니다.' : '공개로 전환되었습니다.')),
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
        },

        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: action,
            height: 60.h,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  child: Icon(iconData, color: themeColor, size: 22.w),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isDestructive ? '목록에서 숨기기' : '다시 공개하기',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
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
}