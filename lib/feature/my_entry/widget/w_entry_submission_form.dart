import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// 💡 분리된 위젯들 Import
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
  final TextEditingController _urlController = TextEditingController();
  File? _selectedImage;
  bool _isAgreed = false;

  // 로컬 로딩 상태
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
    _urlController.dispose();
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

  // 💡 URL도 필수 조건 포함
  bool _canSubmit() =>
      _selectedImage != null &&
          _snsController.text.trim().isNotEmpty &&
          _urlController.text.trim().isNotEmpty &&
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

  Future<void> _submitEntry() async {
    if (!_canSubmit()) return;

    if (_hasProfanity(_snsController.text) || _hasProfanity(_urlController.text)) {
      _showSnackbar('부적절하거나 사용할 수 없는 단어가 포함되어 있습니다.');
      return;
    }

    // 1. 키보드 내리기
    FocusScope.of(context).unfocus();

    setState(() {
      _isLocalLoading = true;
    });

    // 2. 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: WLoadingOverlay(message: '사진을 업로드하고 있어요...\n잠시만 기다려주세요.'),
      ),
    );

    try {
      // 3. 비즈니스 로직
      await ref.read(entryProvider.notifier).submitNewEntry(
        photo: _selectedImage!,
        snsId: _snsController.text.trim(),
        snsUrl: _urlController.text.trim(),
      );

      // 4. 성공 시
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        _showSnackbar('참가 신청이 완료되었습니다! 승인을 기다려주세요.');
        context.go('/home?tab=my_entry');
      }
    } catch (e) {
      // 5. 실패 시
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
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
    final isRegionSet = user != null && user.channel != 'NotSet';

    if (!isRegionSet) {
      return _buildChannelNotSetView(context);
    }

    // Stack 제거 -> SingleChildScrollView만 사용
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

          // 사진 선택
          _buildPhotoSelector(),

          SizedBox(height: 24.h),

          // SNS 입력
          _buildSnsInputField(),

          // 약관 동의
          SizedBox(height: 10.h),
          _buildAgreementCheckbox(),

          SizedBox(height: 30.h),

          // 💡 버튼을 먼저 배치
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

          SizedBox(height: 30.h),

          // 💡 맨 하단에 법적 책임 안내 문구 배치 (Footer 느낌)
          _buildWarningBox(),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // --- 하위 위젯 빌더 ---

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
        Text('홍보용 SNS ID (필수)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
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

        Text('홍보용 프로필 링크 (필수)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _urlController,
          enabled: !_isLocalLoading,
          keyboardType: TextInputType.url,
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value != null && _hasProfanity(value)) {
              return '부적절한 단어가 포함되어 있습니다.';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'https://instagram.com/my_id',
            prefixIcon: const Icon(Icons.link, color: Colors.grey),
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

  // 💡 법적 책임 안내 문구 (Footer style)
  Widget _buildWarningBox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '사진 도용 및 법적 책임 안내',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            '• 타인의 사진을 무단으로 도용하여 발생한 초상권 침해, 저작권 위반 등 모든 법적 책임은 전적으로 게시자 본인에게 있습니다.\n'
                '• 도용 사실이 적발될 경우, 예고 없이 계정이 영구 정지되며 관련 법령에 의거하여 민형사상 처벌을 받을 수 있습니다.\n'
                '• 투표 진행 중 중단을 원하시면 [내 참가] 탭에서 비공개로 전환해주세요.',
            style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black87,
                height: 1.6,
                letterSpacing: -0.5
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelNotSetView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 60.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('채널 설정이 필요해요', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('참가 신청을 위해 마이페이지에서\n나의 활동 채널 설정해 주세요.',
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
            child: Text('채널 설정하러 가기', style: TextStyle(fontSize: 16.sp)),
          )
        ],
      ),
    );
  }
}