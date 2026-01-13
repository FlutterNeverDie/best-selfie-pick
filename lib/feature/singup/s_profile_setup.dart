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

  // 입력 컨트롤러
  late TextEditingController _emailController;
  late TextEditingController _nicknameController;

  String? _selectedChannel;
  String _selectedGender = 'Female';

  // 💡 닉네임 중복 확인 관련 상태
  bool _isNicknameChecked = false;
  String _checkedNickname = '';

  @override
  void initState() {
    super.initState();
    // 💡 초기값 설정: 현재 AuthState에 담긴 (임시)이메일을 미리 채워줌
    final initialEmail = ref.read(authProvider).user?.email ?? '';
    _emailController = TextEditingController(text: initialEmail);
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- 🎯 닉네임 중복 확인 핸들러 ---
  Future<void> _handleNicknameCheck() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showMessage('닉네임을 입력해주세요.');
      return;
    }

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

  Future<void> _showChannelDialog() async {
    final result = await showDialog<String>(
      context: context,
      routeSettings: const RouteSettings(name: ChannelSelectionDialog.routeName),
      builder: (context) => ChannelSelectionDialog(initialChannel: _selectedChannel),
    );

    if (result != null) {
      setState(() => _selectedChannel = result);
    }
  }

  Future<void> _handleFinalProfileSetup() async {
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
      // 💡 수정한 이메일과 새 닉네임을 포함하여 호출
      await ref.read(authProvider.notifier).completeSocialSignUp(
        _emailController.text.trim(),
        _nicknameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 완성하기'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('환영합니다! 😊', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('서비스 이용을 위해 정보를 완성해주세요.', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              SizedBox(height: 32.h),

              // 1. 닉네임 입력 + 중복확인 버튼
              _buildLabel('닉네임'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nicknameController,
                      maxLength: 11,
                      decoration: _buildInputDecoration(hintText: '사용할 닉네임을 입력하세요', icon: Icons.face),
                      onChanged: (val) {
                        if (_isNicknameChecked) {
                          setState(() => _isNicknameChecked = false);
                        }
                      },
                      validator: (v) => v!.isEmpty ? '닉네임은 필수입니다.' : null,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleNicknameCheck,
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
              SizedBox(height: 20.h),

              // 2. 이메일 확인/수정 (선택적 수정)
              _buildLabel('이메일 (확인 및 수정)'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(hintText: '이메일을 입력하세요', icon: Icons.email_outlined),
                validator: (v) => (v == null || !v.contains('@')) ? '유효한 이메일을 입력하세요.' : null,
              ),
              SizedBox(height: 20.h),

              // 3. 채널 선택
              _buildLabel('활동 채널'),
              GestureDetector(
                onTap: _showChannelDialog,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: _selectedChannel != null ? AppColor.primary : Colors.grey),
                      SizedBox(width: 12.w),
                      Text(_selectedChannel ?? '채널을 선택해주세요',
                          style: TextStyle(color: _selectedChannel != null ? Colors.black : Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // 4. 성별 선택
              _buildLabel('성별'),
              Row(
                children: [
                  Expanded(child: _buildGenderButton('여성', 'Female', Icons.female, _selectedGender == 'Female')),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildGenderButton('남성', 'Male', Icons.male, _selectedGender == 'Male')),
                ],
              ),
              SizedBox(height: 40.h),

              // 제출 버튼
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleFinalProfileSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('시작하기', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
  );

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) => InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon, color: Colors.grey),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColor.primary, width: 1.5)),
  );

  Widget _buildGenderButton(String label, String value, IconData icon, bool isSelected) => GestureDetector(
    onTap: () => setState(() => _selectedGender = value),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColor.primary : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isSelected ? AppColor.primary : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}