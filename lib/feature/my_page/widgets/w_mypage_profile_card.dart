import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/colors/app_color.dart';
import '../../../model/m_user.dart';

import '../dialog/d_region_change.dart';

class WMyPageProfileCard extends StatelessWidget {
  final UserModel? user;

  const WMyPageProfileCard({super.key, required this.user});

  void _showRegionChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: 'RegionChangeDialog'),
      barrierDismissible: false, // 바깥 터치로 닫기 방지 (선택사항)
      builder: (context) => const RegionChangeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 프로필 아바타
          CircleAvatar(
            radius: 32.w,
            backgroundColor: AppColor.primary.withOpacity(0.1),
            child: Text(
              user?.email.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(
                fontSize: 24.sp,
                color: AppColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // 2. 유저 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? '로그인 필요',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // 뱃지 Row
                Row(
                  children: [
                    // 💡 [수정됨] onTap에서 다이얼로그 호출
                    GestureDetector(
                      onTap: () => _showRegionChangeDialog(context),
                      child: _buildInfoBadge(
                        icon: Icons.location_on_rounded,
                        text: user?.region == 'NotSet' ? '지역 설정' : (user?.region ?? '미설정'),
                        color: Colors.white,
                        bgColor: AppColor.primary,
                        showEditIcon: true, // 연필 아이콘 표시
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // 성별 뱃지 (터치 X)
                    _buildInfoBadge(
                      icon: user?.gender == 'Female' ? Icons.female : Icons.male,
                      text: user?.gender == 'Female'
                          ? '여성'
                          : (user?.gender == 'Male' ? '남성' : '미설정'),
                      color: user?.gender == 'Female' ? Colors.pinkAccent : Colors.blueAccent,
                      bgColor: (user?.gender == 'Female' ? Colors.pink : Colors.blue).withOpacity(0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 뱃지 위젯 (기존 유지)
  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    bool showEditIcon = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (showEditIcon) ...[
            SizedBox(width: 4.w),
            Icon(Icons.edit, size: 12.sp, color: color.withOpacity(0.8)),
          ]
        ],
      ),
    );
  }
}