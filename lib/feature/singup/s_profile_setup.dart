import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import '../../core/data/region.data.dart';
import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';

// NOTE: 이 파일은 소셜 로그인 후 필수 정보 (지역/성별) 입력을 위한 전용 화면입니다.
class SocialProfileSetupScreen extends ConsumerStatefulWidget {
  const SocialProfileSetupScreen({super.key});

  static const routeName = 'social_profile_setup_screen';

  @override
  ConsumerState<SocialProfileSetupScreen> createState() =>
      _SocialProfileSetupScreenState();
}

class _SocialProfileSetupScreenState
    extends ConsumerState<SocialProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 최종 회원가입 정보
  String? _selectedRegion;
  String? _selectedGender = 'Female'; // 기본값 여성

  @override
  void initState() {
    super.initState();
    // 🎯 중요: 초기화 시 AuthState를 검사하여 user가 없거나 프로필이 이미 완전하면
    // 이 화면에 진입하지 않도록 방지하는 안전 장치를 마련할 수도 있습니다.
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 최종 프로필 업데이트 핸들러 ---
  Future<void> _handleFinalProfileSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null || _selectedGender == null) {
      _showMessage('거주 지역과 성별을 선택해주세요.');
      return;
    }

    // Notifier의 현재 상태를 확인합니다.
    final authState = ref.read(authProvider);

    if (authState.user == null) {
      _showMessage('세션 정보가 유효하지 않습니다. 다시 로그인해주세요.');
      // 로그인 화면으로 리디렉션
      if (context.mounted) {
        context.go('/');
      }
      return;
    }

    try {
      // 🎯 AuthNotifier의 completeSocialSignUp 함수 호출
      // 이 함수는 Repository를 통해 Firestore에 최종 UserModel 문서를 저장하고 상태를 업데이트합니다.
      await ref.read(authProvider.notifier).completeSocialSignUp(
        _selectedRegion!,
        _selectedGender!,
      );

      // 성공 시 AuthGate가 isProfileIncomplete == false를 감지하여 /home으로 리디렉션합니다.
      // 여기서는 AuthGate의 리디렉션을 보조하며, 문제가 발생하면 로그인 화면으로 돌아가도록 처리합니다.
      if (context.mounted) {
        context.go(HomeScreen.routeName);
      }
    } catch (e) {
      // 에러 메시지 상세화
      _showMessage('프로필 설정 실패: ${e.toString().split(':').last.trim()}');
    }
  }

  // --- 🎨 UI 빌더 (EmailSignupScreen의 _buildStep2 재활용) ---

  Widget _buildSetupForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50.h),
        Text('추가 필수 정보 설정',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Text(
          '소셜 로그인 정보를 완성하고 서비스를 시작합니다.',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        ),
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

        // 최종 확인 버튼
        ElevatedButton(
          onPressed: isLoading ? null : _handleFinalProfileSetup,
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
              : Text('프로필 완성 및 시작', style: TextStyle(fontSize: 18.sp)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 🎯 중요: AuthState 검사 후 불필요한 진입을 막고 리디렉션합니다.
    if (authState.user != null && !authState.user!.isProfileIncomplete && !authState.isLoading) {
      // 프로필이 이미 완료되었거나 (이메일 가입 등), 로딩이 끝났는데 아직 여기 있다면 홈으로 보냅니다.
      // AuthGate의 역할을 보조합니다.
      Future.microtask(() => context.go(HomeScreen.routeName));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // AuthState.user가 null이거나 isLoading 중이면 잠시 기다립니다.
    if (authState.user == null || authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('필수 정보 설정'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.0.w, vertical: 20.0.h),
        child: Form(
          key: _formKey,
          child: _buildSetupForm(authState.isLoading),
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