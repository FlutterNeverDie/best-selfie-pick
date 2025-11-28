import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/colors/app_color.dart';
import 'm_notification_settings.dart';
import 'notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  static const String routeName = '/notifications_screen';

  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 배경은 연한 회색
      appBar: AppBar(
        title: const Text('알림 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
          ),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 40.w),
              SizedBox(height: 10.h),
              Text('설정을 불러올 수 없습니다.', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        ),
        data: (settings) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 활동 알림 섹션
                _buildSectionHeader('내 활동 알림'),
                _buildSettingsCard(
                  children: [
                    _buildSwitchTile(
                      context: context,
                      ref: ref,
                      title: '사진 승인 및 반려',
                      subtitle: '참가 신청한 사진의 심사 결과(승인/반려)를 알려드립니다.',
                      settingKey: NotificationSettingsModel.keyApproval,
                      currentValue: settings.photoApproval,
                      icon: Icons.fact_check_rounded,
                      iconColor: Colors.blueAccent,
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      context: context,
                      ref: ref,
                      title: '투표 결과 발표',
                      subtitle: '매주 토요일 00:00, 지난 주차 베스트 픽 결과를 받아봅니다.',
                      settingKey: NotificationSettingsModel.keyResults,
                      currentValue: settings.voteResults,
                      icon: Icons.emoji_events_rounded,
                      iconColor: Colors.orangeAccent,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 2. 혜택 알림 섹션
                _buildSectionHeader('혜택 및 정보'),
                _buildSettingsCard(
                  children: [
                    _buildSwitchTile(
                      context: context,
                      ref: ref,
                      title: '이벤트 및 혜택 알림', // 마케팅
                      subtitle: '새로운 기능, 채널별 이벤트 등 유용한 소식을 놓치지 마세요.',
                      settingKey: NotificationSettingsModel.keyMarketing,
                      currentValue: settings.marketing,
                      icon: Icons.campaign_rounded,
                      iconColor: AppColor.primary,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 3. 하단 안내 문구
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18.w, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '기기 설정에서 앱 알림 권한이 허용되어 있어야 정상적으로 알림을 받을 수 있습니다.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 🏗️ UI 빌더 메서드들 ---

  // 섹션 헤더
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // 흰색 카드 컨테이너
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // 구분선
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
    );
  }

  // 스위치 타일 (디자인 적용)
  Widget _buildSwitchTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String settingKey,
    required bool currentValue,
    required IconData icon,
    required Color iconColor,
  }) {
    final notifier = ref.read(notificationProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      child: Row(
        children: [
          // 1. 아이콘 (원형 배경)
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.w),
          ),
          SizedBox(width: 16.w),

          // 2. 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // 3. 스위치
          Switch(
            value: currentValue,
            onChanged: (newValue) {
              // 햅틱 피드백 추가 (선택 사항)
              // HapticFeedback.lightImpact();
              notifier.toggleSetting(settingKey, newValue);
            },
            activeColor: Colors.white, // 켜졌을 때 동그라미 색
            activeTrackColor: AppColor.primary, // 켜졌을 때 트랙 색
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade200,
            trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => Colors.transparent, // 테두리 제거
            ),
          ),
        ],
      ),
    );
  }
}