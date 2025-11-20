import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/inquiry/repo_inquiry.dart';

import '../../core/theme/colors/app_color.dart';
import '../auth/provider/auth_notifier.dart';
import 'm_inquiry_data.dart';

class InquiryScreen extends ConsumerStatefulWidget {
  static const String routeName = '/inquiry';
  const InquiryScreen({super.key});

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  InquiryType? _selectedType;
  bool _isSubmitting = false;

  static const int MAX_LENGTH = 500;

  @override
  void initState() {
    super.initState();
    // 초기 드롭다운 값 설정
    _selectedType = InquiryType.account;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 문의 제출 로직
  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      _showMessage('문의 유형과 내용을 모두 작성해 주세요.');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) {
      _showMessage('로그인이 필요합니다.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inquiryRepo = ref.read(inquiryRepoProvider);

      final inquiryData = InquiryData(
        userId: user.uid,
        title: _selectedType!.displayName,
        content: _contentController.text.trim(),
        submittedAt: DateTime.now(),
      );

      await inquiryRepo.submitInquiry(inquiryData);

      _showMessage('문의가 성공적으로 접수되었습니다. 감사합니다.');

      // 제출 후 화면 닫기
      if (mounted) {
        context.pop();
      }

    } catch (e) {
      _showMessage('문의 제출 중 오류 발생: ${e.toString().split(':').last.trim()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(fontSize: 14.sp))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자의 이메일을 가져와 안내 문구에 사용합니다.
    final userEmail = ref.read(authProvider).user?.email ?? '가입하신 이메일';

    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '문의 유형 선택',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),

              // 1. 문의 유형 드롭다운
              DropdownButtonFormField<InquiryType>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                value: _selectedType,
                items: InquiryType.values.map((type) {
                  return DropdownMenuItem<InquiryType>(
                    value: type,
                    child: Text(type.displayName, style: TextStyle(fontSize: 16.sp)),
                  );
                }).toList(),
                onChanged: (InquiryType? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) => value == null ? '문의 유형을 선택해주세요.' : null,
              ),

              SizedBox(height: 30.h),

              Text(
                '상세 문의 내용 (최대 ${MAX_LENGTH}자)',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),

              // 2. 문의 내용 입력 필드
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                maxLength: MAX_LENGTH,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: '자세한 내용을 작성해 주세요.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                style: TextStyle(fontSize: 16.sp),
                validator: (value) => value == null || value.trim().isEmpty ? '문의 내용을 입력해주세요.' : null,
              ),

              // ✅ 답변 안내 문구 추가
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '답변은 가입하신 이메일 (${userEmail})로 발송됩니다.',
                  style: TextStyle(fontSize: 12.sp, color: AppColor.darkGrey),
                ),
              ),

              SizedBox(height: 30.h),

              // 3. 제출 버튼
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInquiry,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3.w)
                    : Text(
                  '문의 제출하기',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}