import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/colors/app_color.dart';
import 'm_notification_settings.dart';
import 'notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  static const String routeName = '/notifications';

  const NotificationSettingsScreen({super.key});

  // 알림 항목 UI 구성
  Widget _buildSwitchTile(
      BuildContext context,
      WidgetRef ref,
      String title,
      String subtitle,
      String key,
      bool currentValue,
      ) {
    final notifier = ref.read(notificationProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: AppColor.darkGrey)),
        value: currentValue,
        onChanged: (newValue) {
          // 상태 토글 로직 호출
          notifier.toggleSetting(key, newValue);
        },
        activeColor: AppColor.primary,
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColor.primary)),
        error: (e, s) => Center(child: Text('설정을 불러오는 데 실패했습니다.', style: TextStyle(color: Colors.red, fontSize: 16.sp))),
        data: (settings) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 활동 알림',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColor.darkGrey),
                ),
                Divider(height: 20.h),

                // 1. 사진 승인 알림
                _buildSwitchTile(
                  context, ref,
                  '사진 승인 알림',
                  '참가 신청 사진이 관리자 승인 완료 또는 반려되었을 때 알림을 받습니다.',
                  NotificationSettingsModel.keyApproval,
                  settings.photoApproval,
                ),

                // 2. 투표 마감 알림 (투표 결과)
                _buildSwitchTile(
                  context, ref,
                  '투표 마감/결과 알림',
                  '매주 토요일 00:00에 지난 주차 콘테스트 결과 발표 알림을 받습니다.',
                  NotificationSettingsModel.keyResults,
                  settings.voteResults,
                ),

                SizedBox(height: 30.h),

                Text(
                  '선택적 알림',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColor.darkGrey),
                ),
                Divider(height: 20.h),

                // 3. 이벤트 및 마케팅 알림
                _buildSwitchTile(
                  context, ref,
                  '이벤트 및 마케팅 알림',
                  '새로운 기능 출시, 할인 정보 및 서비스 이벤트 소식을 받습니다.',
                  NotificationSettingsModel.keyMarketing,
                  settings.marketing,
                ),

                SizedBox(height: 50.h),
              ],
            ),
          );
        },
      ),
    );
  }
}