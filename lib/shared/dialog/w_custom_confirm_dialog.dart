// w_custom_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 🎨 공용 확인/취소 SimpleDialog 스타일 위젯
/// 제목, 내용, 버튼 텍스트를 외부에서 받아 깔끔한 디자인으로 노출합니다.
class WCustomConfirmDialog extends StatelessWidget {

  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  const WCustomConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      // 다이얼로그 배경을 흰색으로 유지
      backgroundColor: Colors.white,
      // 모서리 둥글게
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.w)),

      // 내용물 패딩 설정
      contentPadding: EdgeInsets.zero,

      children: [
        // 1. 다이얼로그 제목 및 내용 영역
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 내용 크기에 맞춰 동적 높이 설정
            children: [
              // 제목 (Title)
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              // 내용 (Content)
              Text(
                content,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54,
                  height: 1.4, // 가독성을 위한 줄 간격
                ),
              ),
            ],
          ),
        ),

        // 2. 액션 버튼 영역 (좌우 배치)
        // 디자인 구분을 위해 상단에 구분선 추가
        Divider(height: 1.0, color: Colors.grey.shade200),

        IntrinsicHeight( // Row 내 TextButton 높이 일치
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 취소 버튼 (좌측)
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    // 패딩 제거 및 최소 크기 조정
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    cancelText,
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // 수직 구분선
              VerticalDivider(width: 1.0, thickness: 1.0, color: Colors.grey.shade200),

              // 확인 버튼 (우측, 핑크 악센트)
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      // 🚨 핑크 악센트 컬러 적용
                      color: Colors.pinkAccent,
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