import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';
import 'dialog/d_region_selection.dart';

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
  String? _selectedChannel;
  String _selectedGender = 'Female'; // 기본값 여성

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 채널 선택 다이얼로그 호출 (재사용) ---
  Future<void> _showChannelDialog() async {
    final result = await showDialog<String>(

      context: context,
      routeSettings: const RouteSettings(name: ChannelSelectionDialog.routeName),
      builder: (context) => ChannelSelectionDialog(initialChannel: _selectedChannel),
    );

    if (result != null) {
      setState(() {
        _selectedChannel = result;
      });
    }
  }

  // --- 🎯 최종 프로필 업데이트 핸들러 ---
  Future<void> _handleFinalProfileSetup() async {
    if (_selectedChannel == null) {
      _showMessage('채널을 선택해주세요.');
      return;
    }

    final authState = ref.read(authProvider);

    if (authState.user == null) {
      _showMessage('세션 정보가 유효하지 않습니다. 다시 로그인해주세요.');
      if (context.mounted) context.go('/');
      return;
    }

    try {
      await ref.read(authProvider.notifier).completeSocialSignUp(
        _selectedChannel!,
        _selectedGender,
      );

      if (context.mounted) {
        context.go(HomeScreen.routeName);
      }
    } catch (e) {
      _showMessage('프로필 설정 실패: ${e.toString().split(':').last.trim()}');
    }
  }

  // 🎨 성별 선택 버튼 빌더 (EmailSignupScreen 스타일 통일)
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
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.sp, color: textColor),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 이미 프로필이 완성된 유저라면 홈으로 리디렉션
    if (authState.user != null &&
        !authState.user!.isProfileIncomplete &&
        !authState.isLoading) {
      Future.microtask(() => context.go(HomeScreen.routeName));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('필수 정보 설정'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                '거의 다 왔어요! 🎉',
                style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              Text(
                '원활한 활동을 위해 필수 정보를 알려주세요.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 40.h),

              // 💡 1. 채널 선택 (Dialog 호출형)
              Text('채널',
                  style:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: _showChannelDialog,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: _selectedChannel != null
                              ? AppColor.primary
                              : Colors.grey.shade400,
                          size: 22.sp),
                      SizedBox(width: 12.w),
                      Text(
                        _selectedChannel ?? '채널을 선택해주세요',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _selectedChannel != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                          fontWeight: _selectedChannel != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 💡 2. 성별 선택
              Text('성별',
                  style:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton(
                      label: '여성',
                      value: 'Female',
                      icon: Icons.female,
                      isSelected: _selectedGender == 'Female',
                      activeColor: AppColor.primary, // 🩷
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildGenderButton(
                      label: '남성',
                      value: 'Male',
                      icon: Icons.male,
                      isSelected: _selectedGender == 'Male',
                      activeColor: Colors.blueAccent, // 💙
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              // 완료 버튼
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleFinalProfileSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                ),
                child: authState.isLoading
                    ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                    : Text('시작하기',
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}