import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/inquiry/s_inquiry.dart';
import 'package:selfie_pick/feature/my_page/widgets/w_mypage_menu_item.dart';
import 'package:selfie_pick/feature/my_page/widgets/w_mypage_profile_card.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../core/data/const.dart';
import '../../shared/dialog/w_custom_confirm_dialog.dart';
import '../auth/provider/auth_notifier.dart';
import '../../model/m_user.dart';
import '../notice/s_notice.dart';
import '../notification/s_notification_settings.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  // --- 🔗 URL 실행 로직 ---
  Future<void> _launchUrl() async {
    final Uri uri = Uri.parse(POLICY_URL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- 🚪 로그아웃 로직 ---
  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
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

  // --- 💔 회원 탈퇴 로직 ---
  void _handleWithdrawal(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
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
      backgroundColor: Colors.grey.shade50, // 전체 배경을 연한 회색으로
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 카드
            WMyPageProfileCard(user: user),

            SizedBox(height: 12.h), // 섹션 간격

            // 2. 고객 지원 섹션
            _buildSectionHeader('고객 지원'),
            WMyPageMenuItem(
              title: '공지사항',
              icon: Icons.campaign_outlined,
              onTap: () => context.goNamed(NoticeScreen.routeName),
            ),
            WMyPageMenuItem(
              title: '1:1 문의하기',
              icon: Icons.support_agent_outlined,
              onTap: () => context.goNamed(InquiryScreen.routeName),
            ),
            WMyPageMenuItem(
              title: '운영 정책 및 약관',
              icon: Icons.policy_outlined,
              onTap: _launchUrl,
            ),

            SizedBox(height: 12.h),

            // 3. 설정 및 관리 섹션
            _buildSectionHeader('설정 및 관리'),
            WMyPageMenuItem(
              title: '알림 설정',
              icon: Icons.notifications_outlined,
              onTap: () => context.goNamed(NotificationSettingsScreen.routeName),
            ),
            WMyPageMenuItem(
              title: '로그아웃',
              icon: Icons.logout_rounded,
              titleColor: Colors.blueAccent,
              showArrow: false, // 로그아웃은 화살표 뺌 (취향차이)
              onTap: () => _handleSignOut(context, ref),
            ),
            WMyPageMenuItem(
              title: '회원 탈퇴',
              icon: Icons.person_remove_outlined,
              titleColor: Colors.redAccent,
              showArrow: false,
              onTap: () => _handleWithdrawal(context, ref),
            ),

            SizedBox(height: 40.h),

            // 4. 앱 버전 정보 (하단 마무리)
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

  // 섹션 헤더 빌더
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      color: Colors.grey.shade50,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}