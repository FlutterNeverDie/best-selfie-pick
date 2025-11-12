import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';

import '../../core/data/region.data.dart';
import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart'; // Auth Notifier import

// NOTE: 이 파일은 이메일/비밀번호 회원가입 2단계 프로세스입니다.
// 1단계: 이메일/비밀번호 설정 (IMG_7266 + IMG_7270 통합)
// 2단계: 필수 정보 설정 (지역/성별)

class EmailSignupScreen extends ConsumerStatefulWidget {
  const EmailSignupScreen({super.key});

  static const routeName = 'email_signup_screen';

  @override
  ConsumerState<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends ConsumerState<EmailSignupScreen> {
  // 상태 관리: 1단계 (이메일/비번) -> 2단계 (필수 정보)
  int _currentStep = 1;

  // 폼 및 컨트롤러
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 최종 회원가입 정보
  String? _selectedRegion;
  String? _selectedGender = 'Female'; // 기본값 여성

  // 비밀번호 가시성 토글
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 단계별 핸들러 ---

  // 1단계 핸들러: 이메일/비밀번호 입력 후 2단계로 이동
  Future<void> _handleEmailPasswordSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // 입력 유효성 검증 성공 시 2단계로 이동 (인증 단계는 생략)
    setState(() {
      _currentStep = 2;
    });
    _showMessage('비밀번호 설정 완료. 회원가입에 필요한 필수 정보를 입력해주세요.');
  }

  // 2단계 핸들러: 최종 회원가입 (지역, 성별 설정)
  Future<void> _handleFinalSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null || _selectedGender == null) {
      _showMessage('거주 지역과 성별을 선택해주세요.');
      return;
    }

    try {
      final email = _emailController.text.trim();

      final password = _passwordController.text.trim();

      // 최종 회원가입 및 Firestore 데이터 저장 로직 호출 (AuthNotifier)
      await ref.read(authProvider.notifier).signUp(
            email,
            password,
            _selectedRegion!,
            _selectedGender!,
          );

      // 성공 시 AuthGate에서 /home으로 리디렉션 처리됨
      if (context.mounted) {
        context.go(HomeScreen.routeName); // AuthGate의 리디렉션 로직을 보조
      }
    } catch (e) {
      // 에러 메시지 상세화
      _showMessage('회원가입 실패: ${e.toString().split(':').last.trim()}');
    }
  }

  // --- 🎨 UI 빌더 ---

  Widget _buildStep1( bool isLoading) {
    // 이메일/비밀번호 입력
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50.h),

        // 이메일 입력 필드 (IMG_7266 참고)
        Text('이메일', style: TextStyle(fontSize: 16.sp)),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: '이메일을 입력해주세요.',
            // IMG_7266 스타일을 참고하여 꽉 찬 배경색으로 설정
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              v!.isEmpty || !v.contains('@') ? '올바른 이메일 형식을 입력해주세요.' : null,
        ),
        SizedBox(height: 30.h),

        // 비밀번호 설정 (IMG_7270 참고)
        Text('비밀번호', style: TextStyle(fontSize: 16.sp)),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible, // 가시성 토글 적용
          decoration: InputDecoration(
            hintText: '비밀번호를 입력해주세요.',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (v) => v!.length < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null,
        ),
        SizedBox(height: 12.h),

        // 비밀번호 확인 (IMG_7270 참고)
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible, // 가시성 토글 적용
          decoration: InputDecoration(
            hintText: '비밀번호를 다시 한번 입력해주세요.',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (v) {
            if (v!.isEmpty) return '비밀번호 확인을 입력해주세요.';
            if (v != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
            return null;
          },
        ),
        SizedBox(height: 40.h),

        // 다음 단계 버튼 (IMG_7266 참고)
        ElevatedButton(
          onPressed: isLoading ? null : _handleEmailPasswordSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
            // IMG_7266 버튼 스타일
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.w))
              : Text('다음 단계 (필수 정보 입력)', style: TextStyle(fontSize: 18.sp)),
        ),
        SizedBox(height: 20.h),

        // 로그인 버튼
        InkWell(
          onTap: (){
            context.goNamed(LoginScreen.routeName);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '이미 회원이신가요?',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                ),
                SizedBox(width: 10.w),
                Text(
                  '로그인',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2( bool isLoading) {
    // 지역/성별 설정 (최종 가입)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50.h),
        Text('필수 정보 설정',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 30.h),

        // 지역 선택
        Text('거주 지역 선택 (투표 권한 설정)',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: '지역 선택',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
          ),
          value: _selectedRegion,
          items: regions
              .map((region) => DropdownMenuItem(
                    value: region,
                    child: Text(region, style: TextStyle(fontSize: 16.sp)),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedRegion = value);
          },
          validator: (v) => v == null ? '지역을 선택해주세요' : null,
        ),
        SizedBox(height: 24.h),

        // 성별 선택
        Text('성별 (참가자격: 여성 필수)',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: '성별 선택',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
          ),
          value: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'Female', child: Text('여성')),
            DropdownMenuItem(value: 'Male', child: Text('남성')),
          ],
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
          validator: (v) => v == null ? '성별을 선택해주세요' : null,
        ),
        SizedBox(height: 40.h),

        // 최종 확인 버튼 (IMG_7270의 '확인' 버튼 스타일 참고)
        ElevatedButton(
          onPressed: isLoading ? null : _handleFinalSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.w))
              : Text('가입 완료 및 시작', style: TextStyle(fontSize: 18.sp)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        // 단계 제목 업데이트
        title: Text(_currentStep == 1 ? '이메일로 가입' : '필수 정보 설정'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.0.w, vertical: 20.0.h),
        child: Form(
          key: _formKey,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 1
                ? _buildStep1( authState.isLoading)
                : _buildStep2(authState.isLoading),
          ),
        ),
      ),
      // 에러 메시지 표시
      bottomNavigationBar: authState.error != null
          ? Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.red.shade50,
              child: Text('시스템: ${authState.error!}',
                  style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            )
          : null,
    );
  }
}
