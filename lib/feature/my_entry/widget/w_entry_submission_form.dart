import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../auth/provider/auth_notifier.dart';
import '../../my_entry/provider/entry_provider.dart';

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({this.color = Colors.grey, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // 둥근 사각형 경로 생성
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(12.w)));

    Path dashPath = Path();
    double dashWidth = 10.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WEntrySubmissionForm extends ConsumerStatefulWidget {
  const WEntrySubmissionForm({super.key});

  @override
  ConsumerState<WEntrySubmissionForm> createState() => _WEntrySubmissionFormState();
}

class _WEntrySubmissionFormState extends ConsumerState<WEntrySubmissionForm> {
  final TextEditingController _snsController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isAgreed = false;

  @override
  void dispose() {
    _snsController.dispose();
    super.dispose();
  }

  // 💡 버튼 활성화 여부를 결정하는 Getter
  bool get _canSubmit =>
      _selectedImage != null &&
          _snsController.text.trim().isNotEmpty &&
          _isAgreed &&
          !_isSubmitting;

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
    // 이중 체크 (버튼 비활성화로 막히지만 안전장치)
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus(); // 키보드 내리기

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(entryProvider.notifier).submitNewEntry(
        photo: _selectedImage!,
        snsId: _snsController.text.trim(),
      );

      if (mounted) {
        _showSnackbar('참가 신청이 완료되었습니다! 승인을 기다려주세요.');
        context.go('/home?tab=my_entry');
      }
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
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: 14.sp)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isRegionSet = user != null && user.region != 'NotSet';

    if (!isRegionSet) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 60.w, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              '지역 설정이 필요해요',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '참가 신청을 위해 마이페이지에서\n나의 활동 지역을 설정해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], height: 1.4),
            ),
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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '이번 주 주인공은 바로 당신! ✨',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              Text(
                '가장 자신 있는 사진을 올려주세요.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 24.h),

              // 1. 사진 선택 영역
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: CustomPaint(
                  painter: _selectedImage == null
                      ? _DashedBorderPainter(color: Colors.grey.shade400, gap: 6.w)
                      : null,
                  child: Container(
                    height: 320.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.w),
                      border: _selectedImage != null
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.w),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
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
                        Text(
                          '여기를 눌러 사진 업로드',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '(정사각형 또는 세로형 이미지 권장)',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 2. SNS ID 입력
              Text(
                '홍보용 SNS ID',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                maxLength: 50,
                controller: _snsController,
                enabled: !_isSubmitting,
                // 💡 입력할 때마다 상태 업데이트 -> 버튼 활성화 체크
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: '인스타그램, 블로그 ID 등',
                  prefixText: '@ ',
                  prefixStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.w),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.w),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.w),
                    borderSide: BorderSide(color: AppColor.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                style: TextStyle(fontSize: 16.sp),
              ),

              // 3. 약관 및 동의 (체크박스)
              SizedBox(height: 10.h),
              InkWell(
                onTap: () {
                  if (!_isSubmitting) {
                    setState(() {
                      _isAgreed = !_isAgreed;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8.w),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: Checkbox(
                          value: _isAgreed,
                          activeColor: AppColor.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
                          onChanged: (value) {
                            if (!_isSubmitting) {
                              setState(() {
                                _isAgreed = value ?? false;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '서비스 이용 약관 및 개인정보 처리방침에 동의하며,\n본인의 사진으로 참가함에 동의합니다.',
                          style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 4. 하단 주의 사항 안내
              Container(
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
                        Text(
                          '참가 전 꼭 확인해주세요!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '• 제출 후에는 사진 수정이 불가능합니다.\n• 투표 진행 중 중단을 원하시면 [내 참가] 탭에서 언제든지 "비공개" 상태로 전환할 수 있습니다.\n• 부적절한 사진은 예고 없이 승인 거절될 수 있습니다.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // 5. 신청 버튼 (최하단)
              ElevatedButton(
                // 💡 모든 조건(_canSubmit)이 만족되어야 버튼 활성화
                onPressed: _canSubmit ? _submitEntry : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 54.h),
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300], // 비활성화 시 색상
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                ),
                child: Text(
                  '참가 신청 제출하기',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 24.h), // 하단 여백 확보
            ],
          ),
        ),

        // 6. 로딩 오버레이
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3.w),
                  SizedBox(height: 16.h),
                  Text(
                    '사진을 업로드하고 있어요...\n잠시만 기다려주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}