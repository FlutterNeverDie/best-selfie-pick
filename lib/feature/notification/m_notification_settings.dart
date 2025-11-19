import 'package:flutter/foundation.dart';

@immutable
class NotificationSettingsModel {
  // FCM 알림 항목
  final bool photoApproval; // 사진 승인 알림
  final bool voteResults; // 투표 마감 알림 (투표 결과)
  final bool marketing; // 이벤트 및 마케팅 알림

  const NotificationSettingsModel({
    required this.photoApproval,
    required this.voteResults,
    required this.marketing,
  });

  // 로컬 저장소 Key 정의 (Constants)
  static const String keyApproval = 'noti_approval';
  static const String keyResults = 'noti_results';
  static const String keyMarketing = 'noti_marketing';

  // 불변성을 위한 copyWith 수동 구현
  NotificationSettingsModel copyWith({
    bool? photoApproval,
    bool? voteResults,
    bool? marketing,
  }) {
    return NotificationSettingsModel(
      photoApproval: photoApproval ?? this.photoApproval,
      voteResults: voteResults ?? this.voteResults,
      marketing: marketing ?? this.marketing,
    );
  }
}