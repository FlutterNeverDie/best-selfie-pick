import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_page/widgets/w_my_page_app_bar.dart';
import 'package:selfie_pick/feature/my_page/widgets/w_mypage_menu_item.dart';
import 'package:selfie_pick/feature/my_page/widgets/w_mypage_profile_card.dart';
import 'package:url_launcher/url_launcher.dart';

// 화면 이동 Import
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/inquiry/s_inquiry.dart';
import 'package:selfie_pick/feature/notice/s_notice.dart';
import 'package:selfie_pick/feature/notification/s_notification_settings.dart';


import '../../core/data/const.dart';
import '../../shared/dialog/w_custom_confirm_dialog.dart';
import '../auth/provider/auth_notifier.dart';
import '../../model/m_user.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  // --- 🔗 URL 실행 ---
  Future<void> _launchUrl() async {
    final Uri uri = Uri.parse(POLICY_URL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- 🚪 로그아웃 ---
  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'sign_out_dialog'),
      builder: (context) => const WCustomConfirmDialog(
        title: '로그아웃',
        content: '정말로 로그아웃 하시겠습니까?',
        confirmText: '로그아웃',
        cancelText: '취소',
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go(AuthGateScreen.routeName);
    }
  }

  // --- 💔 회원 탈퇴 ---
  void _handleWithdrawal(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'withdrawal_dialog'),
      builder: (context) => const WCustomConfirmDialog(
        title: '회원 탈퇴',
        content: '탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?',
        confirmText: '탈퇴하기',
        cancelText: '취소',
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).withdraw();
      if (context.mounted) context.go(AuthGateScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final UserModel? user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 전체 배경 연회색

      // 💡 분리된 AppBar 사용
      appBar: const WMyPageAppBar(),

      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),

            // 1. 프로필 카드
            WMyPageProfileCard(user: user),

            SizedBox(height: 32.h),

            // 2. 고객 지원 섹션
            _buildSectionContainer(
              title: '고객 지원',
              children: [
                WMyPageMenuItem(
                  title: '공지사항',
                  icon: Icons.campaign_rounded,
                  iconColor: Colors.orange,
                  onTap: () => context.goNamed(NoticeScreen.routeName),
                ),
                _buildDivider(),
                WMyPageMenuItem(
                  title: '1:1 문의하기',
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.blue,
                  onTap: () => context.goNamed(InquiryScreen.routeName),
                ),
                _buildDivider(),
                WMyPageMenuItem(
                  title: '운영 정책 및 약관',
                  icon: Icons.policy_rounded,
                  iconColor: Colors.green,
                  onTap: _launchUrl,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 3. 설정 및 관리 섹션
            _buildSectionContainer(
              title: '설정 및 관리',
              children: [
                WMyPageMenuItem(
                  title: '알림 설정',
                  icon: Icons.notifications_rounded,
                  iconColor: Colors.purple,
                  onTap: () => context.goNamed(NotificationSettingsScreen.routeName),
                ),
                _buildDivider(),
                WMyPageMenuItem(
                  title: '로그아웃',
                  icon: Icons.logout_rounded,
                  iconColor: Colors.grey,
                  titleColor: Colors.black87,
                  showArrow: false,
                  onTap: () => _handleSignOut(context, ref),
                ),
                _buildDivider(),
                WMyPageMenuItem(
                  title: '회원 탈퇴',
                  icon: Icons.person_remove_rounded,
                  iconColor: Colors.red,
                  titleColor: Colors.redAccent,
                  showArrow: false,
                  onTap: () => _handleWithdrawal(context, ref),
                ),
              ],
            ),

            SizedBox(height: 40.h),

            // 4. 앱 버전 정보
            Center(
              child: Text(
                '현재 버전 1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // 섹션을 흰색 박스로 감싸는 빌더 (iOS 스타일)
  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // 메뉴 사이 구분선
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
    );
  }
}