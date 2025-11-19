import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'm_notification_settings.dart';

// Repository Provider 정의
final notificationRepoProvider = Provider((ref) => NotificationRepository());

class NotificationRepository {
  // 💡 shared_preferences의 인스턴스를 비동기적으로 가져옵니다.
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// 1. 알림 설정 상태 전체 로드
  Future<NotificationSettingsModel> loadSettings() async {
    final prefs = await _prefs;

    // 로컬에 저장된 상태가 없다면 기본값(true)을 사용합니다.
    final approval = prefs.getBool(NotificationSettingsModel.keyApproval) ?? true;
    final results = prefs.getBool(NotificationSettingsModel.keyResults) ?? true;
    final marketing = prefs.getBool(NotificationSettingsModel.keyMarketing) ?? true;

    return NotificationSettingsModel(
      photoApproval: approval,
      voteResults: results,
      marketing: marketing,
    );
  }

  /// 2. 특정 알림 설정 상태 저장 (토글)
  Future<void> saveSetting(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
    debugPrint('Notification setting saved: $key = $value');
  }
}