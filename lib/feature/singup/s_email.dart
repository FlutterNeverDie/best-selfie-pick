import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';

import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';
// 💡 새로 만든 다이얼로그 Import
import 'dialog/d_region_selection.dart';

class EmailSignupScreen extends ConsumerStatefulWidget {
  const EmailSignupScreen({super.key});

  static const routeName = 'email_signup_screen';

  @override
  ConsumerState<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends ConsumerState<EmailSignupScreen> {
  int _currentStep = 1;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  String? _selectedChannel;
  String _selectedGender = 'Female';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 💡 닉네임 중복 확인 관련 상태
  bool _isNicknameChecked = false;
  String _checkedNickname = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
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

  // --- 🎯  선택 다이얼로그 호출 ---
  Future<void> _showChannelDialog() async {
    final result = await showDialog<String>(
      context: context,
      routeSettings:  const RouteSettings(name: ChannelSelectionDialog.routeName),
      builder: (context) => ChannelSelectionDialog(initialChannel: _selectedChannel),
    );

    if (result != null) {
      setState(() {
        _selectedChannel = result;
      });
    }
  }

  // --- 🎯 닉네임 중복 확인 핸들러 ---
  Future<void> _handleNicknameCheck() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showMessage('닉네임을 입력해주세요.');
      return;
    }

    // 최소 2자 이상 권장 등 추가 정책 가능
    if (nickname.length < 2) {
      _showMessage('닉네임은 최소 2자 이상이어야 합니다.');
      return;
    }

    try {
      final isAvailable = await ref.read(authProvider.notifier).checkNicknameAvailability(nickname);

      if (isAvailable) {
        setState(() {
          _isNicknameChecked = true;
          _checkedNickname = nickname;
        });
        _showMessage('사용 가능한 닉네임입니다.');
      } else {
        setState(() {
          _isNicknameChecked = false;
        });
        _showMessage('이미 사용 중인 닉네임입니다.');
      }
    } catch (e) {
      _showMessage('닉네임 확인 중 오류가 발생했습니다.');
    }
  }

  // --- 🎯 1단계 핸들러 (이메일/비번 검증) ---
  Future<void> _handleEmailPasswordSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final notifier = ref.read(authProvider.notifier);

    FocusScope.of(context).unfocus();

    try {
      final bool emailNotExists = await notifier.checkEmailAvailability(email);

      if (emailNotExists) {
        setState(() {
          _currentStep = 2;
        });
      } else {
        final errorMsg = ref.read(authProvider).error;
        _showMessage(errorMsg ?? '이미 사용 중인 이메일입니다.');
      }
    } catch (e) {
      _showMessage('중복 확인 중 오류 발생: ${e.toString().split(':').last.trim()}');
    }
  }

  // --- 🎯 2단계 핸들러 (최종 가입) ---
  Future<void> _handleFinalSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // 💡 닉네임 중복 확인 여부 체크
    if (!_isNicknameChecked || _checkedNickname != _nicknameController.text.trim()) {
      _showMessage('닉네임 중복 확인이 필요합니다.');
      return;
    }

    if (_selectedChannel == null) {
      _showMessage('채널을 선택해주세요.');
      return;
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nickname = _nicknameController.text.trim();

      await ref.read(authProvider.notifier).signUp(
        email,
        password,
        nickname,
        _selectedChannel!,
        _selectedGender,
      );

      if (context.mounted) {
        context.go(HomeScreen.routeName);
      }
    } catch (e) {
      _showMessage('회원가입 실패: ${e.toString().split(':').last.trim()}');
    }
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
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColor.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.red.shade200)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  // --- 🏗️ 1단계 UI ---
  Widget _buildStep1(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text('이메일로 시작하기 ✉️', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        Text('로그인에 사용할 이메일과 비밀번호를 입력해주세요.', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        SizedBox(height: 30.h),

        Text('이메일', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          key: const ValueKey('signup_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 16.sp),
          decoration: _buildInputDecoration(hintText: 'example@email.com', icon: Icons.email_outlined),
          validator: (v) => v!.isEmpty || !v.contains('@') ? '올바른 이메일 형식을 입력해주세요.' : null,
        ),

        SizedBox(height: 20.h),

        Text('비밀번호', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          key: const ValueKey('signup_password'),
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(fontSize: 16.sp),
          decoration: _buildInputDecoration(
            hintText: '6자 이상 입력해주세요',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (v) => v!.length < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null,
        ),

        SizedBox(height: 12.h),

        TextFormField(
          key: const ValueKey('signup_confirm_password'),
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          style: TextStyle(fontSize: 16.sp),
          decoration: _buildInputDecoration(
            hintText: '비밀번호를 한 번 더 입력해주세요',
            icon: Icons.check_circle_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
          validator: (v) {
            if (v!.isEmpty) return '비밀번호 확인을 입력해주세요.';
            if (v != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
            return null;
          },
        ),

        SizedBox(height: 40.h),

        ElevatedButton(
          onPressed: isLoading ? null : _handleEmailPasswordSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56.h),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: isLoading
              ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text('다음으로', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ),

        SizedBox(height: 20.h),

        Center(
          child: TextButton(
            onPressed: () => context.goNamed(LoginScreen.routeName),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
                children: [
                  const TextSpan(text: '이미 계정이 있으신가요?  '),
                  TextSpan(text: '로그인', style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 🏗️ 2단계 UI ---
  Widget _buildStep2(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text('마지막 단계입니다! 🎉', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        Text('원활한 활동을 위해 필수 정보를 알려주세요.', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        SizedBox(height: 30.h),

        // 💡 1. 닉네임 입력 + 중복확인 버튼
        Text('닉네임', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('signup_nickname'),
                controller: _nicknameController,
                maxLines: 11,
                style: TextStyle(fontSize: 16.sp),
                decoration: _buildInputDecoration(hintText: '사용할 닉네임', icon: Icons.face_rounded),
                onChanged: (val) {
                  if (_isNicknameChecked) {
                    setState(() => _isNicknameChecked = false);
                  }
                },
                validator: (v) => v == null || v.isEmpty ? '닉네임을 입력해주세요.' : null,
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              height: 56.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleNicknameCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNicknameChecked ? Colors.green : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  _isNicknameChecked ? '확인됨' : '중복확인',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // 💡 2. 채널 선택
        Text('채널', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showChannelDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: _selectedChannel != null ? AppColor.primary : Colors.grey.shade400, size: 22.sp),
                SizedBox(width: 12.w),
                Text(
                  _selectedChannel ?? '채널을 선택해주세요',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: _selectedChannel != null ? Colors.black87 : Colors.grey.shade400,
                    fontWeight: _selectedChannel != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // 💡 3. 성별 선택
        Text('성별', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildGenderButton(
                label: '여성',
                value: 'Female',
                icon: Icons.female,
                isSelected: _selectedGender == 'Female',
                activeColor: AppColor.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildGenderButton(
                label: '남성',
                value: 'Male',
                icon: Icons.male,
                isSelected: _selectedGender == 'Male',
                activeColor: Colors.blueAccent,
              ),
            ),
          ],
        ),

        SizedBox(height: 40.h),

        // 가입 완료 버튼
        ElevatedButton(
          onPressed: isLoading ? null : _handleFinalSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56.h),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: isLoading
              ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text('가입 완료하기', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // 🎨 성별 선택 버튼 빌더
  Widget _buildGenderButton({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
  }) {
    final textColor = isSelected ? Colors.white : Colors.grey.shade600;
    final borderColor = isSelected ? activeColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.sp, color: textColor),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(1),
            SizedBox(width: 4.w),
            Container(width: 20.w, height: 2.h, color: Colors.grey.shade300),
            SizedBox(width: 4.w),
            _buildStepIndicator(2),
          ],
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _currentStep == 1
                  ? _buildStep1(authState.isLoading)
                  : _buildStep2(authState.isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: isActive ? AppColor.primary : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade500,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}