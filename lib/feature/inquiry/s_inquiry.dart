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
    _selectedType = InquiryType.account;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

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

    // 키보드 내리기
    FocusScope.of(context).unfocus();

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

      if (mounted) {
        // 성공 다이얼로그 또는 스낵바 후 종료
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문의가 접수되었습니다. 빠르게 답변 드릴게요!', style: TextStyle(fontSize: 14.sp)),
            backgroundColor: AppColor.primary,
          ),
        );
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
    final userEmail = ref.read(authProvider).user?.email ?? '정보 없음';

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 배경색: 아주 연한 회색
      appBar: AppBar(
        title: Text(
          '1:1 문의하기',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 안내 문구 (카드 형태)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '답변 안내',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                color: Colors.blueAccent
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '보내주신 문의에 대한 답변은 가입하신 이메일로 발송됩니다.',
                            style: TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.4),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '📩 $userEmail',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // 2. 문의 유형 선택
              Text(
                '문의 유형',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: DropdownButtonFormField<InquiryType>(
                  decoration: InputDecoration(
                    border: InputBorder.none, // 기본 테두리 제거
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  dropdownColor: Colors.white,
                  value: _selectedType,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                  items: InquiryType.values.map((type) {
                    return DropdownMenuItem<InquiryType>(
                      value: type,
                      child: Text(type.displayName, style: TextStyle(fontSize: 15.sp, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedType = newValue),
                  validator: (value) => value == null ? '문의 유형을 선택해주세요.' : null,
                ),
              ),

              SizedBox(height: 24.h),

              // 3. 문의 내용 입력
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '문의 내용',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    '${_contentController.text.length} / $MAX_LENGTH자',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  maxLength: MAX_LENGTH,
                  keyboardType: TextInputType.multiline,
                  onChanged: (value) => setState(() {}), // 글자 수 업데이트
                  decoration: InputDecoration(
                    hintText: '불편하시거나 궁금하신 점을 자세히 적어주세요.\n빠르게 확인 후 답변 드리겠습니다.',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
                    border: InputBorder.none, // 테두리 제거 (Container가 대신함)
                    contentPadding: EdgeInsets.all(16.w),
                    counterText: '', // 기본 카운터 숨김
                  ),
                  style: TextStyle(fontSize: 15.sp, height: 1.5),
                  validator: (value) => value == null || value.trim().isEmpty ? '내용을 입력해주세요.' : null,
                ),
              ),

              SizedBox(height: 40.h),

              // 4. 제출 버튼
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInquiry,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 54.h),
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                )
                    : Text(
                  '문의 제출하기',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 40.h), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}