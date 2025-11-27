import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/champion/provider/repo/repo_champion.dart';
import 'package:selfie_pick/feature/champion/provider/state/champion.state.dart';

import '../../../shared/provider/contest_status/contest_status_provider.dart';

// Provider 정의
final championProvider = NotifierProvider<ChampionNotifier, ChampionState>(() {
  return ChampionNotifier();
}, name: 'championProvider');

class ChampionNotifier extends Notifier<ChampionState> {
  ChampionRepository get _repository => ref.read(championRepoProvider);

  @override
  ChampionState build() {
    // 1. 필요한 Provider들의 상태를 감시 (Watch)
    final authState = ref.watch(authProvider);
    final contestStatus = ref.watch(contestStatusProvider);

    final String? userRegion = authState.user?.region;
    final String? lastSettledWeekKey = contestStatus.lastSettledWeekKey;

    // 2. 필수 조건 확인
    if (userRegion == null || lastSettledWeekKey == null) {
      // 필수 정보가 로드되지 않았을 경우, 에러 상태를 동기적으로 반환합니다.
      return const ChampionState(error: '지역 설정 또는 정산 정보가 로드되지 않았습니다.');
    }

    // 3. Future.microtask로 초기 비동기 로드 호출
    // build()가 완료되어 Notifier가 초기화된 후, 다음 마이크로태스크 큐에서 로드를 시작합니다.
    Future.microtask(() => _loadChampions(userRegion, lastSettledWeekKey));

    // 4. 로딩 시작 상태를 동기적으로 반환합니다.
    return const ChampionState();
  }

  Future<void> _loadChampions(
      String userRegion, String lastSettledWeekKey) async {
    // 💡 강화된 중복 호출 방지 가드:
    // build()에서 이미 isLoading: true를 반환했기 때문에,
    // 로직이 정상적으로 실행될 경우 이 가드에 걸려 바로 종료됩니다.
    // 이는 상태 변경이 두 번 발생하는 것을 방지합니다.
    if (state.isLoading) {
      debugPrint('챔피언 로드 - 중복 호출을 방지, 조회 중단');
      return;
    }

    try {
      // 2. Repository 호출: 현재 사용자 지역의 지난 정산 결과를 요청
      final champions =
          await _repository.fetchChampions(userRegion, lastSettledWeekKey);

      // 3. 로딩 상태 해제 및 결과 반영
      state = state.copyWith(
        isLoading: false,
        champions: champions,
        error: null,
      );

      debugPrint('로드 완료 champions 수 : ${champions.length}');
    } catch (e) {
      debugPrint('Error loading champions: $e');
      // 4. 오류 발생 시 로딩 해제 및 오류 반영
      state = state.copyWith(
        isLoading: false,
        error: '챔피언 정보를 불러오는 데 실패했습니다.',
      );
    }
  }
}
