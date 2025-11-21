import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/singup/s_email.dart';

import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login_screen';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  // --- 🎯 로그인 핸들러 ---
  Future<void> _handleLogin() async {
    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final bool success = await ref.read(authProvider.notifier).signIn(email, password);

    if (context.mounted) {
      if (success) {
        context.go('/home');
      } else {
        final msg = ref.read(authProvider).error;
        _showMessage(msg ?? '로그인에 실패했습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 화면 터치 시 키보드 내림
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // 1. 헤더 텍스트
                Text(
                  '다시 만나서 반가워요! 👋 ',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '이메일과 비밀번호로 로그인해주세요.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade500,
                  ),
                ),

                SizedBox(height: 40.h),

                // 2. 이메일 입력
                _buildLabel('이메일'),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 16.sp),
                  decoration: _buildInputDecoration(
                    hintText: 'example@email.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) => v == null || !v.contains('@') ? '올바른 이메일 형식을 입력해주세요.' : null,
                ),

                SizedBox(height: 24.h),

                // 3. 비밀번호 입력
                _buildLabel('비밀번호'),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(fontSize: 16.sp),
                  decoration: _buildInputDecoration(
                    hintText: '비밀번호를 입력해주세요',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.grey.shade400,
                        size: 22.sp,
                      ),
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

                // 4. 로그인 버튼
                ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColor.primary.withOpacity(0.3),
                    minimumSize: Size(double.infinity, 56.h), // 버튼 높이 키움
                    elevation: 0, // 플랫한 디자인
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    '로그인',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 24.h),

                // 5. 하단 링크 (회원가입)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '아직 회원이 아니신가요?',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () {
                        context.goNamed(EmailSignupScreen.routeName);
                      },
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 🎨 UI 헬퍼 메서드 ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22.sp),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50, // 아주 연한 회색 배경
      contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}