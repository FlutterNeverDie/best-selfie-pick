import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/auth/provider/repository/auth_repo.dart';
import 'package:selfie_pick/feature/report/provider/report_provider.dart';
import 'package:selfie_pick/model/m_user.dart';
import 'package:selfie_pick/shared/dialog/w_custom_confirm_dialog.dart';

// 💡 차단된 유저들의 상세 정보를 비동기로 가져오는 Provider
final blockedUsersInfoProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  // 1. 현재 내 차단 목록 ID들 가져오기
  final blockedIds = ref.watch(authProvider.select((s) => s.user?.blockedUserIds ?? []));

  if (blockedIds.isEmpty) return [];

  // 2. ID들을 이용해 실제 유저 정보(닉네임 등) 조회
  final authRepo = ref.read(authRepoProvider);
  return await authRepo.fetchUsersBasicInfo(blockedIds);
}, name: 'blockedUsersInfoProvider');

class BlockedUsersScreen extends ConsumerWidget {
  static const String routeName = '/blocked_users_screen';

  const BlockedUsersScreen({super.key});

  // 차단 해제 핸들러
  void _handleUnblock(BuildContext context, WidgetRef ref, UserModel targetUser) async {
    final confirm = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'unblock_user_dialog'),
      builder: (context) => WCustomConfirmDialog(
        title: '차단 해제',
        content: '${targetUser.email} 님을 차단 해제하시겠습니까?\n이제 랭킹에서 이 분의 사진이 다시 보입니다.',
        confirmText: '해제하기',
        cancelText: '취소',
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(reportProvider.notifier).unblockUser(targetUser.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('차단이 해제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
          );
        }
      }
    }
  } 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersInfoProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('차단 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: blockedUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('정보를 불러오는데 실패했습니다.')),
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            itemCount: blockedUsers.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return _buildBlockedUserItem(context, ref, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 60.w, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            '차단한 사용자가 없습니다.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserItem(BuildContext context, WidgetRef ref, UserModel user) {
    // 식별용 텍스트 (이메일 앞부분 or SNS ID가 있다면 SNS ID)
    final displayName = user.email.split('@').first;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 프로필 아바타 (회색조 처리 - 차단됨을 암시)
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: Icon(Icons.person_off_rounded, color: Colors.grey.shade400, size: 24.w),
          ),
          SizedBox(width: 16.w),

          // 2. 유저 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName, // 닉네임
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12.w, color: Colors.grey.shade500),
                    SizedBox(width: 2.w),
                    Text(
                      user.channel, // 채널명
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. 차단 해제 버튼
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () => _handleUnblock(context, ref, user),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.w),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
              ),
            ),
            child: Text(
              '차단 해제',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}