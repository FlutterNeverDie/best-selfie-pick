import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:selfie_pick/feature/singup/s_email.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';

import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  static const routeName = '/welcome';

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with TickerProviderStateMixin {

  // 1. 화면 등장 애니메이션
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // 2. 아이콘 회전 애니메이션
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // --- 등장 애니메이션 설정 ---
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();

    // --- 회전 애니메이션 설정 ---
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialSignIn(String provider, Future<void> Function() signInFunction) async {
    try {
      await signInFunction();
    } catch (e) {
      debugPrint('$provider 로그인 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider 로그인 실패: ${e.toString().split(':').last.trim()}')),
        );
      }
    }
  }

  // 🎨 소셜 버튼 빌더
  Widget _buildSocialButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Widget icon,
    required VoidCallback onPressed,
    bool hasBorder = false,
  }) {
    final isLoading = ref.watch(authProvider).isLoading;

    return _BouncingButton(
      onPressed: isLoading ? null : onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
            boxShadow: (!isLoading && !hasBorder) ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Row(
            children: [
              SizedBox(width: 24.w, child: Center(child: icon)),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(width: 24.w),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    final bool isAndroid = Platform.isAndroid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),

                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- 1. 상단 로고 영역 ---
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primary.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [AppColor.primary, Colors.purpleAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: RotationTransition(
                                  turns: _rotationController,
                                  child: Icon(
                                    Icons.camera,
                                    size: 70.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30.h),

                            Text(
                              'Best Pick',
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: -1.0,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              '우리 동네 베스트 셀카 챌린지',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // --- 2. 하단 버튼 영역 ---
                        Column(
                          children: [
                            SizedBox(height: 32.h),

                            // 🟡 카카오 로그인
                            _buildSocialButton(
                              text: 'Kakao로 계속하기',
                              backgroundColor: const Color(0xFFFEE500),
                              textColor: const Color(0xFF191919),
                              icon: const FaIcon(FontAwesomeIcons.solidComment, color: Color(0xFF191919), size: 20),
                              onPressed: () => _handleSocialSignIn('Kakao', authNotifier.signInWithKakao),
                            ),

                            // 🟢 [신규] 네이버 로그인 추가
                            _buildSocialButton(
                              text: 'Naver로 계속하기',
                              backgroundColor: const Color(0xFF03C75A), // 네이버 그린
                              textColor: Colors.white,
                              // 네이버 로고 대신 심플한 N 텍스트 아이콘 사용
                              icon: Text(
                                'N',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20.sp,
                                  fontFamily: 'sans-serif', // 기본 폰트 사용
                                ),
                              ),
                              onPressed: () => _handleSocialSignIn('Naver', authNotifier.signInWithNaver),
                            ),

                            // ⚪️ 구글 로그인
                            _buildSocialButton(
                              text: 'Google로 계속하기',
                              backgroundColor: Colors.white,
                              textColor: Colors.black87,
                              hasBorder: true,
                              icon: const FaIcon(FontAwesomeIcons.google, color: Colors.black87, size: 20),
                              onPressed: () => _handleSocialSignIn('Google', authNotifier.signInWithGoogle),
                            ),

                            // ⚫️ 애플 로그인 (안드로이드 숨김)
                            if (!isAndroid)
                              _buildSocialButton(
                                text: 'Apple로 계속하기',
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
                                onPressed: () => _handleSocialSignIn('Apple', authNotifier.signInWithApple),
                              ),

                            SizedBox(height: 16.h),

                            // 이메일 로그인/가입
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _BouncingButton(
                                  onPressed: () {
                                    authNotifier.resetError();
                                    context.goNamed(EmailSignupScreen.routeName);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Text(
                                      '이메일로 가입',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14.sp
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 12.h,
                                  width: 1,
                                  color: Colors.grey.shade300,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                ),
                                _BouncingButton(
                                  onPressed: () => context.goNamed(LoginScreen.routeName),
                                  child: Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Text(
                                      '로그인',
                                      style: TextStyle(
                                          color: AppColor.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20.h),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 눌렀을 때 작아지는 애니메이션 버튼
class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _BouncingButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}