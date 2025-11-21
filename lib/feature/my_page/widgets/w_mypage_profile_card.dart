import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';
import '../../../../model/m_user.dart';
import '../dialog/d_region_change.dart';

class WMyPageProfileCard extends StatelessWidget {
  final UserModel? user;

  const WMyPageProfileCard({super.key, required this.user});

  // 💡 지역 변경 다이얼로그 호출
  void _showRegionChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RegionChangeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w), // 둥근 모서리
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 프로필 아바타
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColor.primary.withOpacity(0.2), width: 2.w),
            ),
            child: Center(
              child: Text(
                user?.email.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  fontSize: 28.sp,
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 20.w),

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
                SizedBox(height: 10.h),

                // 뱃지 Row
                Row(
                  children: [
                    // 📍 지역 뱃지 (클릭 가능)
                    GestureDetector(
                      onTap: () => _showRegionChangeDialog(context),
                      child: _buildInfoBadge(
                        icon: Icons.location_on_rounded,
                        text: user?.region == 'NotSet' ? '지역 설정' : (user?.region ?? '미설정'),
                        color: Colors.white,
                        bgColor: AppColor.primary,
                        showEditIcon: true, // 연필 아이콘
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // ⚧ 성별 뱃지
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

  // 뱃지 공통 위젯
  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    bool showEditIcon = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: showEditIcon
            ? [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
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
            Icon(Icons.edit_rounded, size: 12.sp, color: color.withOpacity(0.8)),
          ]
        ],
      ),
    );
  }
}