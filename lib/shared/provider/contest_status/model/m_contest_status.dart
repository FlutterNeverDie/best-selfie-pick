import 'package:flutter/foundation.dart';

// Contest Status Model (불변성 유지)
@immutable
class ContestStatusModel {
  final String? currentWeekKey; // 현재 진행 중인 회차 키 (예: 2025-15)
  final String? lastSettledWeekKey; // 지난주 정산이 완료된 회차 키 (챔피언 탭 조회용)

  const ContestStatusModel({
    this.currentWeekKey,
    this.lastSettledWeekKey,
  });

  // 불변성을 위한 copyWith 수동 구현
  ContestStatusModel copyWith({
    String? currentWeekKey,
    String? lastSettledWeekKey,
  }) {
    return ContestStatusModel(
      currentWeekKey: currentWeekKey ?? this.currentWeekKey,
      lastSettledWeekKey: lastSettledWeekKey ?? this.lastSettledWeekKey,
    );
  }

  //toString
  @override
  String toString() {
    return 'ContestStatusModel('
        'currentWeekKey: $currentWeekKey, '
        'lastSettledWeekKey: $lastSettledWeekKey'')';
  }
}