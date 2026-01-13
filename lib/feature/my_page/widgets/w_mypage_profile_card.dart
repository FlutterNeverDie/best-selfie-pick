import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';
import '../../../../model/m_user.dart';
import '../dialog/d_channel_change.dart';

class WMyPageProfileCard extends StatelessWidget {
  final UserModel? user;

  const WMyPageProfileCard({super.key, required this.user});

  // 💡 채널 변경 다이얼로그 호출
  void _showChannelChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: 'ChannelChangeDialog'),
      builder: (context) => const ChannelChangeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 닉네임이 없을 경우 이메일 앞부분 사용
    final String displayName = user?.nickname.isNotEmpty == true
        ? user!.nickname
        : (user?.email.split('@').first ?? '로그인 필요');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w), // 토스 스타일의 넉넉한 라운딩
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. 프로필 아바타 (더 차분한 톤의 원형)
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // 2. 유저 정보 (닉네임 메인 + 이메일 서브)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h), // 간격을 더 좁혀서 한 그룹으로 보이게 함
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 💡 우측 화살표 제거 완료
            ],
          ),

          SizedBox(height: 24.h),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade50),
          SizedBox(height: 20.h),

          // 3. 하단 활동 정보 뱃지
          Row(
            children: [
              // 📍 활동 채널 (클릭 가능한 '버튼' 형태)
              GestureDetector(
                onTap: () => _showChannelChangeDialog(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.08), // 너무 진하지 않게 변경
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14.sp, color: AppColor.primary),
                      SizedBox(width: 4.w),
                      Text(
                        user?.channel == 'NotSet' ? '채널 설정' : (user?.channel ?? '미설정'),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.edit_rounded, size: 12.sp, color: AppColor.primary.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // ⚧ 성별 (클릭 불가능한 '정보' 형태)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, // 무채색 배경으로 버튼과 차별화
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        user?.gender == 'Female' ? Icons.female : Icons.male,
                        size: 14.sp,
                        color: user?.gender == 'Female' ? Colors.pink.shade300 : Colors.blue.shade300
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      user?.gender == 'Female' ? '여성' : (user?.gender == 'Male' ? '남성' : '미설정'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600, // 차분한 텍스트 색상
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}