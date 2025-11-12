import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ScreenUtil import

import 'package:selfie_pick/feature/singup/s_email.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';
import 'package:selfie_pick/feature/singup/s_profile_setup.dart';

import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';
import '../home/s_home.dart';



// NOTE: 이 파일은 AuthGate에서 리디렉션되는 '회원가입/로그인 선택' 화면입니다.
// 벤치마킹 앱의 IMG_7265.PNG 화면에 해당합니다.

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  static const routeName = '/signup'; // GoRouter에서 사용하는 경로 이름

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {

  // 🎯 이 화면에 진입할 때 무조건 로그아웃을 실행하여 모든 인증 상태를 리셋합니다.
  @override
  void initState() {
    super.initState();

  }

  // --- 유틸리티 ---
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 소셜 로그인 핸들러 ---
  Future<void> _handleSocialSignIn(String provider, Future<void> Function() signInFunction) async {
    // AuthNotifier가 isLoading 상태를 관리하므로, 별도 로딩 처리는 UI에서 감시합니다.
    try {
      await signInFunction();

      if (mounted) {
        context.go(SocialProfileSetupScreen.routeName);
      }
      // 성공 시 AuthGate에서 /home 또는 /signup/email_signup으로 리디렉션 처리됨
    } catch (e) {
      // 에러는 AuthState에 저장되어 UI 하단에 표시됩니다.
    }
  }

  // --- 🎨 UI 빌더 ---

  // Container와 InkWell을 사용하여 버튼 구현
  // icon 대신 Widget을 받아 FaIcon이나 기본 Icon 모두 수용 가능하도록 변경
  Widget _buildSocialButton({
    required String text,
    required Color backgroundColor,
    required Widget iconWidget,
    required Future<void> Function() onPressed,
    Color iconColor = Colors.white,
    Color textColor = Colors.white
  }) {
    final isLoading = ref.watch(authProvider).isLoading;

    // 버튼 클릭 핸들러 (로딩 상태 체크)
    void handleTap() {
      if (!isLoading) {
        onPressed();
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h), // 반응형 수직 패딩
      child: Container(
        height: 55.h, // 반응형 높이
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.r), // 반응형 둥근 모서리
          // 로딩 중일 때 약간 투명하게 처리
          boxShadow: isLoading ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1.r,
              blurRadius: 5.r,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : handleTap,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w), // 반응형 수평 패딩
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [


                  SizedBox(width: 50.w), // 반응형 공간

                  // 아이콘
                  // FaIcon이나 Icon 위젯이 직접 전달됩니다.
                  IconTheme(
                    data: IconThemeData(color: iconColor, size: 22.sp),
                    child: iconWidget,
                  ),
                  SizedBox(width: 8.w), // 반응형 공간

                  // 텍스트
                  Text(
                      text,
                      style: TextStyle(
                          fontSize: 18.sp, // 반응형 폰트 크기
                          fontWeight: FontWeight.bold,
                          color: textColor
                      )
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0.w, vertical: 60.0.h), // 반응형 패딩
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // --- 앱 타이틀 영역 (IMG_7265) ---
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          '지역별 여성들의 셀카 콘테스트',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey) // 반응형 폰트
                      ),
                      SizedBox(height: 10.h), // 반응형 공간
                      Text(
                        '베스트 Pick', // 앱 이름
                        style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w900, color: AppColor.primary), // 반응형 폰트
                      ),
                    ],
                  ),
                ),
              ),


              _buildSocialButton(
                text: 'Go Home (Test)', // 테스트용 버튼 텍스트
                backgroundColor: Colors.blue.shade300, // 파란색 계열
                iconWidget: const Icon(Icons.home), // 집 아이콘
                iconColor: Colors.white,
                textColor: Colors.white,
                onPressed: () async {
                  // 강제로 로그인 및 프로필 완료 상태를 가정하여 Home으로 이동
                  // 실제 앱에서는 이런 방식으로 직접 홈으로 가지 않고,
                  // AuthNotifier의 상태 변경을 통해 redirect가 작동해야 합니다.
                  debugPrint('TEST: Attempting to go to Home Screen directly.');
                  context.go(HomeScreen.routeName);
                },
              ),
              SizedBox(height: 10.h), // 반응형 공간


              // --- 소셜/이메일 버튼 영역 (IMG_7265) ---
              // 1. KaKao 버튼: 말풍선 아이콘 적용
              _buildSocialButton(
                text: 'KaKao로 시작하기',
                backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
                iconWidget:  FaIcon(FontAwesomeIcons.solidComment), // Font Awesome 아이콘
                iconColor: Colors.black,
                textColor: Colors.black,
                onPressed: () => _handleSocialSignIn('Kakao', authNotifier.signInWithKakao),
              ),
              SizedBox(height: 10.h), // 반응형 공간

              // 2. Google 버튼: Google 아이콘 적용
              _buildSocialButton(
                text: 'Google로 시작하기',
                backgroundColor: Colors.red.shade700,
                iconWidget:  FaIcon(FontAwesomeIcons.google), // Font Awesome 아이콘
                iconColor: Colors.white,
                textColor: Colors.white,
                onPressed: () => _handleSocialSignIn('Google', authNotifier.signInWithGoogle),
              ),
              SizedBox(height: 10.h), // 반응형 공간

              // 3. Apple 버튼: Apple 아이콘 적용
              _buildSocialButton(
                text: 'Apple로 시작하기',
                backgroundColor: Colors.black,
                iconWidget: Icon(FontAwesomeIcons.apple), // Font Awesome 아이콘
                iconColor: Colors.white,
                textColor: Colors.white,
                onPressed: () => _handleSocialSignIn('Apple', authNotifier.signInWithApple),
              ),
              SizedBox(height: 10.h), // 반응형 공간

              // 4. 이메일 버튼 (기본 Flutter 아이콘 사용)
              _buildSocialButton(
                text: 'Email로 시작하기',
                backgroundColor: Colors.grey.shade100,
                iconWidget: const Icon(Icons.mail_outline), // 기본 Icon 위젯
                iconColor: Colors.black,
                textColor: Colors.black,
                onPressed: () async {

                  ref.read(authProvider.notifier).resetError();

                  // 이메일 가입/로그인 화면으로 이동 (다단계 폼)
                  context.goNamed(EmailSignupScreen.routeName);
                },
              ),
              SizedBox(height: 20.h), // 반응형 공간

              // 로그인/가입 안내 텍스트 (IMG_7265)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('이미 계정이 있으신가요?', style: TextStyle(color: Colors.grey, fontSize: 14.sp)), // 반응형 폰트
                  TextButton(
                    onPressed: () {

                      context.goNamed(LoginScreen.routeName);

                    },
                    child: Text('로그인', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14.sp)), // 반응형 폰트
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}