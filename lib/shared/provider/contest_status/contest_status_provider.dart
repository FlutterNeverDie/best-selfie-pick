import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../interface/i_date_util.dart';
import 'model/m_contest_status.dart';

// Contest Status Notifier Provider 정의
final contestStatusProvider =
    NotifierProvider<ContestStatusNotifier, ContestStatusModel>(
  () => ContestStatusNotifier(),
);

class ContestStatusNotifier extends Notifier<ContestStatusModel> {
  final IDateUtil _dateUtil = DateUtilImpl(); // DateUtil 구현체 직접 사용

  @override
  ContestStatusModel build() {
    // 1. 현재 시간 기준으로 현재 회차 키 계산 (현재 토요일 00:00 이전까지는 지난주 회차 키를 사용)
    final now = DateTime.now();
    final currentWeekKey = _dateUtil.getContestWeekKey(now);

    // 2. 지난 정산 회차 키 계산 (챔피언 탭에서 필요)
    // 정산은 토요일 00:00에 지난주 금요일까지의 투표를 마감합니다.
    final lastSettledTime = now.subtract(const Duration(days: 1));
    final lastSettledWeekKey = _dateUtil.getContestWeekKey(lastSettledTime);

    // 3. 초기 상태 반환
    ContestStatusModel model = ContestStatusModel(
      currentWeekKey: currentWeekKey,
      lastSettledWeekKey: lastSettledWeekKey,
    );

    debugPrint(' contestStatusProvider build(): $model');

    return model;
  }


}
