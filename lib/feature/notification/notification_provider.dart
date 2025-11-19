import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/notification/repo_notification.dart';
import 'm_notification_settings.dart';

// AsyncNotifierProvider로 정의하여 비동기 초기 로드를 처리합니다.
final notificationProvider =
AsyncNotifierProvider<NotificationNotifier, NotificationSettingsModel>(
      () => NotificationNotifier(),
);

class NotificationNotifier extends AsyncNotifier<NotificationSettingsModel> {
  late final NotificationRepository _repository;

  @override
  Future<NotificationSettingsModel> build() async {
    _repository = ref.read(notificationRepoProvider);
    // 💡 Repository를 통해 로컬에 저장된 상태를 비동기로 로드합니다.
    return _repository.loadSettings();
  }

  /// 1. 알림 상태 토글 및 로컬 저장
  Future<void> toggleSetting(String key, bool value) async {
    final currentState = state.value;
    if (currentState == null) return;

    // 1. Repository를 통해 로컬 저장소에 값 저장
    await _repository.saveSetting(key, value);

    // 2. Notifier의 상태 업데이트 (copyWith 사용)
    state = AsyncValue.data(currentState.copyWith(
      photoApproval: key == NotificationSettingsModel.keyApproval ? value : currentState.photoApproval,
      voteResults: key == NotificationSettingsModel.keyResults ? value : currentState.voteResults,
      marketing: key == NotificationSettingsModel.keyMarketing ? value : currentState.marketing,
    ));

    // TODO: FCM SDK를 사용하여 구독/구독 해제 로직 추가 필요
  }
}