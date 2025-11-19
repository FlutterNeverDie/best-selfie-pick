import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';

import '../auth/provider/auth_notifier.dart'; // Auth Notifier import
import '../../model/m_user.dart';
import '../notice/s_notice.dart';
import '../notification/s_notification_settings.dart'; // UserModel import (경로가 m_user.dart라고 가정)


class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  // --- 🎨 UI 빌더: 메뉴 항목 위젯 ---
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.h)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: Colors.grey.shade600),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: titleColor ?? Colors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // --- 🎯 로그아웃 핸들러 ---
  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 확인'),
        content: const Text('정말로 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(authProvider.notifier).signOut();
        if (context.mounted) {
          // context.go를 사용하여 AuthGateScreen으로 이동시키면,
          // AuthGateScreen이 로그아웃 상태임을 확인하고 최종적으로 SignupScreen으로 리디렉션합니다.
          context.go(AuthGateScreen.routeName);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 사용자 정보 감시 (Riverpod)
    final authState = ref.watch(authProvider);
    final UserModel? user = authState.user;

    // 2. ScreenUtil 초기화 (최상위에서 이미 되었다고 가정)
    // 3. UI 구성
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- A. 사용자 정보 섹션 ---
            Container(
              padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  // 프로필 아이콘 (임시)
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user?.email.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(fontSize: 24.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email ?? '로그인 필요',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          // 지역 (시 단위)
                          Icon(Icons.location_on, size: 16.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            user?.region == 'NotSet' ? '지역 미설정' : user?.region ?? '미설정',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                          ),
                          SizedBox(width: 12.w),
                          // 성별
                          Icon(
                            user?.gender == 'Female' ? Icons.female : Icons.male,
                            size: 16.sp,
                            color: user?.gender == 'Female' ? Colors.pink : Colors.blue,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            user?.gender == 'Female' ? '여성' : (user?.gender == 'Male' ? '남성' : '미설정'),
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- B. 설정 및 고객 지원 섹션 ---
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text('   설정 및 지원', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            ),

            // 1. 알림 설정
            _buildMenuItem(
              title: '알림 설정',
              icon: Icons.notifications,
              onTap: () {
                context.goNamed(NotificationSettingsScreen.routeName);
              },
            ),
            // 2. 공지사항
            _buildMenuItem(
              title: '공지사항',
              icon: Icons.campaign,
              onTap: () {
                context.goNamed(NoticeScreen.routeName);
              },
            ),
            // 3. 문의 (1:1)
            _buildMenuItem(
              title: '1:1 문의',
              icon: Icons.support_agent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문의하기 화면으로 이동합니다.')));
              },
            ),
            // 4. 운영 정책
            _buildMenuItem(
              title: '운영 정책 및 약관',
              icon: Icons.policy,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('운영 정책 화면으로 이동합니다.')));
              },
            ),

            // --- C. 계정 관리 섹션 ---
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text('   계정 관리', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            ),

            // 5. 로그아웃
            _buildMenuItem(
              title: '로그아웃',
              icon: Icons.logout,
              onTap: () => _handleSignOut(context, ref),
              titleColor: Colors.blue,
            ),

            // 6. 회원 탈퇴
            _buildMenuItem(
              title: '회원 탈퇴',
              icon: Icons.person_remove,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원 탈퇴 처리 화면으로 이동합니다.')));
              },
              titleColor: Colors.red,
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}