import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/singup/s_email.dart';

import '../../core/theme/colors/app_color.dart'; // AppColor 사용을 위해 import
import '../auth/provider/auth_notifier.dart'; // Auth Notifier import

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login_screen'; // GoRouter 경로 이름

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 로그인 핸들러 ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. AuthNotifier를 통해 로그인 로직 호출
      await ref.read(authProvider.notifier).signIn(email, password);

      // 2. 성공 시: AuthGate가 상태 변화를 감지하여 홈으로 리디렉션함.
      if (context.mounted) {
        // NOTE: 로그인 성공 후 홈으로 이동 (AuthGate를 보조)
        context.go('/home');
      }
    } catch (e) {
      // 에러 메시지는 UI 하단에 표시되거나 _showMessage로 즉시 알림
      _showMessage('로그인 실패: ${e.toString().split(':').last.trim()}');
    }
  }

  // --- 🎨 UI 빌더: 링크 항목 위젯 ---
  Widget _buildLinkItem({
    required String prompt,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prompt,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
            SizedBox(width: 10.w),
            Text(
              actionText,
              style: TextStyle(fontSize: 12.sp, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32.0.w, vertical: 20.0.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 50.h),
                  Text('로그인', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 50.h),

                  // --- 1. 이메일 입력 ---
                  Text('이메일', style: TextStyle(fontSize: 16.sp)),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: '이메일을 입력해주세요.',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? '올바른 이메일 형식을 입력해주세요.' : null,
                  ),
                  SizedBox(height: 30.h),

                  // --- 2. 비밀번호 입력 ---
                  Text('비밀번호', style: TextStyle(fontSize: 16.sp)),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력해주세요.',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null,
                  ),
                  SizedBox(height: 40.h),

                  // --- 3. 로그인 버튼 ---
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary, // AppColor.primary 사용
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w))
                        : Text('로그인', style: TextStyle(fontSize: 18.sp)),
                  ),
                  SizedBox(height: 40.h),

                  // --- 4. 추가 기능 버튼 (컬럼 배치 및 스타일 적용) ---
                  Column(
                    children: [
                      // 1. 회원가입 링크
                      _buildLinkItem(
                        prompt: '아직 회원이 아니신가요?',
                        actionText: '회원가입',
                        onPressed: isLoading ? () {} : () {
                          context.goNamed(EmailSignupScreen.routeName);
                        },
                      ),
                      SizedBox(height: 8.h),
                      // 2. 비밀번호 찾기 링크
                      _buildLinkItem(
                        prompt: '비밀번호를 잊으셨나요?',
                        actionText: '비밀번호 찾기',
                        onPressed: isLoading ? () {} : () {
                          _showMessage('비밀번호 찾기 기능 구현 필요');
                          // TODO: 비밀번호 찾기 화면 경로로 이동
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}