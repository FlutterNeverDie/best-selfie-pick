// w_entry_submission_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../auth/provider/auth_notifier.dart';
import '../../my_entry/provider/entry_provider.dart';

// 참가 신청 폼: 사진 선택 및 SNS ID 입력을 처리하고 EntryNotifier에 제출합니다.
// ConsumerWidget 대신 ConsumerStatefulWidget을 사용하여 폼 상태(텍스트, 이미지)를 관리합니다.
class WEntrySubmissionForm extends ConsumerStatefulWidget {
  const WEntrySubmissionForm({super.key});

  @override
  ConsumerState<WEntrySubmissionForm> createState() => _WEntrySubmissionFormState();
}

class _WEntrySubmissionFormState extends ConsumerState<WEntrySubmissionForm> {
  final TextEditingController _snsController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _snsController.dispose();
    super.dispose();
  }

  // 갤러리에서 이미지 선택 (사진 수정 시 광고 시청 조건은 추후 구현 필요)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 참가 신청 제출 로직
  Future<void> _submitEntry() async {
    if (_selectedImage == null) {
      _showSnackbar('사진을 선택해 주세요.');
      return;
    }
    if (_snsController.text.trim().isEmpty) {
      _showSnackbar('홍보용 SNS ID를 입력해 주세요.');
      return;
    }

    // 폼이 이미 제출 중이면 중복 실행 방지
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Notifier를 읽어 비즈니스 로직 실행
      await ref.read(entryProvider.notifier).submitNewEntry(
        photo: _selectedImage!,
        snsId: _snsController.text.trim(),
      );

      _showSnackbar('참가 신청이 완료되었습니다! 관리자 승인을 기다려주세요.');

      // 신청 완료 후, '내 참가' 탭으로 돌아가기
      // HomeScreen의 '내 참가' 탭은 2번째 탭이라고 가정
      context.go('/home?tab=my_entry');

    } catch (e) {
      _showSnackbar('신청 실패: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: TextStyle(fontSize: 14.sp))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 정보 감시 (지역 설정 확인용)
    final user = ref.watch(authProvider).user;
    final isRegionSet = user != null && user.region != 'NotSet';

    if (!isRegionSet) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            children: [
              Text(
                '참가 신청을 위해 마이페이지에서 지역 설정을 완료해 주세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  // 마이페이지(4번째 탭)로 이동 유도
                  context.go('/home?tab=mypage');
                },
                child: Text('지역 설정하러 가기', style: TextStyle(fontSize: 16.sp)),
              )
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '참가 사진 및 정보 입력',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 22.sp),
          ),
          SizedBox(height: 20.h),

          // 1. 사진 선택 영역
          GestureDetector(
            onTap: _isSubmitting ? null : _pickImage,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.grey.shade300, width: 2.w),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10.w),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 50.w, color: Colors.grey),
                    SizedBox(height: 8.h),
                    Text('셀카 선택 (갤러리)', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // 2. SNS ID 입력
          TextFormField(
            maxLength: 100,
            controller: _snsController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: '홍보용 SNS ID (필수)',
              hintText: '@instagram_id 또는 my_blog',
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
            ),
            style: TextStyle(fontSize: 16.sp),
          ),
          SizedBox(height: 30.h),

          // 3. 신청 버튼
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitEntry,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50.h),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3.w)
                : Text(
              '참가 신청 제출하기',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: Text(
              '* 등록된 사진은 관리자 수동 승인을 거쳐야 투표 대상에 노출됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}