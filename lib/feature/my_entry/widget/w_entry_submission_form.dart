import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// 💡 외부 위젯 Import
import '../../../shared/widget/w_dashed_border_painter.dart';
import '../../../shared/widget/w_loading_overlay.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../auth/provider/auth_notifier.dart';
import '../../my_entry/provider/entry_provider.dart';

class WEntrySubmissionForm extends ConsumerStatefulWidget {
  const WEntrySubmissionForm({super.key});

  @override
  ConsumerState<WEntrySubmissionForm> createState() => _WEntrySubmissionFormState();
}

class _WEntrySubmissionFormState extends ConsumerState<WEntrySubmissionForm> {
  final TextEditingController _snsController = TextEditingController();
  File? _selectedImage;
  bool _isAgreed = false;

  // 💡 로컬 로딩 상태 (버튼 비활성화용)
  bool _isLocalLoading = false;
  List<String> _bannedWords = [];

  @override
  void initState() {
    super.initState();
    _loadBannedWords();
  }

  @override
  void dispose() {
    _snsController.dispose();
    super.dispose();
  }

  Future<void> _loadBannedWords() async {
    try {
      final String fileContent = await rootBundle.loadString('assets/fwordList.txt');
      if (mounted) {
        setState(() {
          _bannedWords = fileContent
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('금지어 로드 실패: $e');
    }
  }

  bool _hasProfanity(String text) {
    if (_bannedWords.isEmpty) return false;
    final String cleanText = text.replaceAll(RegExp(r'\s+'), '');
    for (var word in _bannedWords) {
      if (cleanText.contains(word)) return true;
    }
    return false;
  }

  bool _canSubmit() =>
      _selectedImage != null &&
          _snsController.text.trim().isNotEmpty &&
          _isAgreed &&
          !_isLocalLoading;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 💡 [핵심 수정] Stack 대신 showDialog 사용
  Future<void> _submitEntry() async {
    if (!_canSubmit()) return;

    if (_hasProfanity(_snsController.text)) {
      _showSnackbar('부적절하거나 사용할 수 없는 단어가 포함되어 있습니다.');
      return;
    }

    // 1. 키보드 내리기 (충돌 방지)
    FocusScope.of(context).unfocus();

    setState(() {
      _isLocalLoading = true;
    });

    // 2. 💡 로딩 다이얼로그 띄우기 (UI 충돌 없는 안전한 방식)
    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: 'EntrySubmissionLoadingDialog'),
      barrierDismissible: false, // 터치로 닫기 방지
      builder: (context) => const PopScope(
        canPop: false, // 뒤로가기 방지
        child: WLoadingOverlay(message: '사진을 업로드하고 있어요...\n잠시만 기다려주세요.'),
      ),
    );

    try {
      // 3. 비즈니스 로직 실행
      await ref.read(entryProvider.notifier).submitNewEntry(
        photo: _selectedImage!,
        snsId: _snsController.text.trim(),
      );

      // 4. 성공 시 로직
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showSnackbar('참가 신청이 완료되었습니다! 승인을 기다려주세요.');
        context.go('/home?tab=my_entry');
      }
    } catch (e) {
      // 5. 실패 시 로직
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showSnackbar('신청 실패: ${e.toString().replaceAll('Exception: ', '')}');
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: 14.sp)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isRegionSet = user != null && user.region != 'NotSet';

    if (!isRegionSet) {
      return _buildRegionNotSetView(context);
    }

    // 💡 [핵심 수정] Stack 제거하고 바로 SingleChildScrollView 반환
    // 이렇게 하면 키보드가 움직일 때 parentDataDirty 에러가 발생할 구조적 원인이 사라집니다.
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('이번 주 주인공은 바로 당신! ✨',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 8.h),
          Text('가장 자신 있는 사진을 올려주세요.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
          SizedBox(height: 24.h),

          // 사진 선택 영역
          _buildPhotoSelector(),

          SizedBox(height: 24.h),

          // SNS 입력 영역
          _buildSnsInputField(),

          // 약관 동의
          SizedBox(height: 10.h),
          _buildAgreementCheckbox(),

          SizedBox(height: 24.h),

          // 주의 사항
          _buildWarningBox(),

          SizedBox(height: 30.h),

          // 제출 버튼
          ElevatedButton(
            onPressed: _canSubmit() ? _submitEntry : null,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 54.h),
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
            ),
            child: Text('참가 신청 제출하기',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // --- 하위 빌더 함수들 ---

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _isLocalLoading ? null : _pickImage,
      child: CustomPaint(
        painter: _selectedImage == null
            ? DashedBorderPainter(color: Colors.grey.shade400, gap: 6.w)
            : null,
        child: Container(
          height: 320.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.w),
            border: _selectedImage != null ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: _selectedImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12.w),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_selectedImage!, fit: BoxFit.cover),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white, size: 16.w),
                        SizedBox(width: 8.w),
                        Text('사진 변경하기', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 48.w, color: AppColor.primary.withOpacity(0.7)),
              SizedBox(height: 12.h),
              Text('여기를 눌러 사진 업로드', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              SizedBox(height: 4.h),
              Text('(정사각형 또는 세로형 이미지 권장)', style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnsInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('홍보용 SNS ID', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        TextFormField(
          maxLength: 50,
          controller: _snsController,
          enabled: !_isLocalLoading,
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value != null && _hasProfanity(value)) {
              return '부적절한 단어가 포함되어 있습니다.';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: '인스타그램, 블로그 ID 등',
            prefixText: '@ ',
            prefixStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16.sp),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide(color: AppColor.primary, width: 1.5)),
            errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
          style: TextStyle(fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildAgreementCheckbox() {
    return InkWell(
      onTap: () { if (!_isLocalLoading) setState(() => _isAgreed = !_isAgreed); },
      borderRadius: BorderRadius.circular(8.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.w, height: 24.w,
              child: Checkbox(
                value: _isAgreed,
                activeColor: AppColor.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
                onChanged: (value) { if (!_isLocalLoading) setState(() => _isAgreed = value ?? false); },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text('서비스 이용 약관 및 개인정보 처리방침에 동의하며,\n본인의 사진으로 참가함에 동의합니다.',
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20.w),
              SizedBox(width: 8.w),
              Text('참가 전 꼭 확인해주세요!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          Text('• 제출 후에는 사진 수정이 불가능합니다.\n• 투표 진행 중 중단을 원하시면 [내 참가] 탭에서 언제든지 "비공개" 상태로 전환할 수 있습니다.\n• 부적절한 사진은 예고 없이 승인 거절될 수 있습니다.',
              style: TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRegionNotSetView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 60.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('지역 설정이 필요해요', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('참가 신청을 위해 마이페이지에서\n나의 활동 지역을 설정해 주세요.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], height: 1.4)),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/home?tab=mypage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
            ),
            child: Text('지역 설정하러 가기', style: TextStyle(fontSize: 16.sp)),
          )
        ],
      ),
    );
  }
}