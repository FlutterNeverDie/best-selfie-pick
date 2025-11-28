import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

class ReportDialog extends StatefulWidget {
  final Function(String reason, String desc) onReport;

  const ReportDialog({super.key, required this.onReport});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _selectedReason = 'spam';
  final TextEditingController _descController = TextEditingController();

  final Map<String, String> _reasons = {
    '스팸': '스팸 / 부적절한 홍보',
    '욕설': '욕설 / 비하 발언',
    '음란물': '음란물 / 불건전한 콘텐츠',
    '도용': '사칭 / 도용',
    '기타': '기타 사유',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 WCustomConfirmDialog와 동일한 SimpleDialog 스타일 적용 (통일성 유지)
    return SimpleDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.w)),
      contentPadding: EdgeInsets.zero,
      children: [
        // 1. 헤더 및 내용 (WCustomConfirmDialog의 Padding 값과 동일)
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 타이틀 (아이콘 포함)
              Row(
                children: [
                  Icon(Icons.report_gmailerrorred_rounded,
                      color: Colors.pinkAccent, size: 22.sp),
                  SizedBox(width: 6.w),
                  Text(
                    '신고하기',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '신고 사유를 선택해주세요.\n신고 접수 시 해당 사용자는 즉시 차단됩니다.',
                style: TextStyle(
                  fontSize: 16.sp, // WCustomConfirmDialog 폰트 사이즈와 일치
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),

              // 사유 선택 리스트
              ..._reasons.entries.map((entry) {
                final isSelected = _selectedReason == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReason = entry.key),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pinkAccent.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(
                        color: isSelected ? Colors.pinkAccent : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Colors.pinkAccent : Colors.grey.shade400,
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // 기타 사유 입력창
              if (_selectedReason == 'other') ...[
                SizedBox(height: 8.h),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '상세 사유를 입력해주세요 (선택)',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.all(12.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.w),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ],
          ),
        ),

        // 2. 액션 버튼 영역 (WCustomConfirmDialog와 동일 구조)
        Divider(height: 1.0, color: Colors.grey.shade200),

        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 취소 버튼
              Expanded(
                child: TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              VerticalDivider(width: 1.0, thickness: 1.0, color: Colors.grey.shade200),

              // 신고하기 버튼
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.onReport(_selectedReason, _descController.text);
                    context.pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '신고하기',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent, // 신고는 빨간색 강조
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}