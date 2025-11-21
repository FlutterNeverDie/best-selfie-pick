// w_entry_status_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../model/m_entry.dart';

class WEntryStatusView extends StatelessWidget {
  final EntryModel entry;
  final String statusText;
  final Color color;
  final IconData icon;
  final String? message;
  final bool showResubmitButton;

  const WEntryStatusView({
    super.key,
    required this.entry,
    required this.statusText,
    required this.color,
    required this.icon,
    this.message,
    this.showResubmitButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusHeader(context),
          SizedBox(height: 20.h),
          _buildEntryPhoto(entry),
          SizedBox(height: 20.h),
          if (message != null)
            _buildMessageBox(message!, color),

          // 반려 상태일 경우 재신청 유도 버튼 노출
          if (showResubmitButton && entry.status == 'rejected')
            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: ElevatedButton(
                onPressed: () {
                  // 챔피언 탭으로 이동 (신청은 챔피언 탭에서 처리)
                  context.go('/home?tab=champion');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
                ),
                child: Text('사진 재신청하기', style: TextStyle(fontSize: 16.sp)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: color, width: 1.5.w),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.w),
          SizedBox(width: 10.w),
          Text(
            statusText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryPhoto(EntryModel entry) {
    return Column(
      children: [
        Text('등록된 사진', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.w),
          child: Image.network(
            entry.thumbnailUrl,
            height: 300.h,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 300.h,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 300.h,
              color: Colors.red[100],
              child: Center(child: Text('사진 로드 실패', style: TextStyle(fontSize: 14.sp))),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text('SNS ID: ${entry.snsId}', style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }

  Widget _buildMessageBox(String message, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 1.w),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 14.sp),
      ),
    );
  }
}