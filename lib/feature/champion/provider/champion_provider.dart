import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/champion/provider/repo/repo_champion.dart';
import 'package:selfie_pick/feature/champion/provider/state/champion.state.dart';
import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';



// Provider 정의
final championProvider =
StateNotifierProvider.autoDispose<ChampionNotifier, ChampionState>((ref) {
  final repository = ref.watch(championRepoProvider);
  final authState = ref.watch(authProvider);
  final contestStatus = ref.watch(contestStatusProvider);

  // 필수 정보가 로드되지 않았을 경우 기본 상태 반환
  if (authState.user?.region == null || contestStatus.lastSettledWeekKey == null) {
    return ChampionNotifier(repository, null, null); // Region이나 WeekKey가 없으면 null 전달
  }

  return ChampionNotifier(
      repository,
      authState.user!.region, // User의 현재 지역
      contestStatus.lastSettledWeekKey! // 지난 정산 회차 키
  );
});

class ChampionNotifier extends StateNotifier<ChampionState> {
  final ChampionRepository _repository;
  final String? _userRegion;
  final String? _lastSettledWeekKey;

  ChampionNotifier(this._repository, this._userRegion, this._lastSettledWeekKey)
      : super(const ChampionState()) {
    _loadChampions();
  }

  Future<void> _loadChampions() async {
    // 1. 필수 조건 확인: 지역 정보와 지난 정산 회차 키가 모두 있어야 함
    if (_userRegion == null || _lastSettledWeekKey == null) {
      state = state.copyWith(error: '지역 설정 또는 정산 정보가 로드되지 않았습니다.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null); // 에러 초기화

    try {
      // 2. Repository 호출: 현재 사용자 지역의 지난 정산 결과를 요청
      final champions = await _repository.fetchChampions(
          _userRegion,
          _lastSettledWeekKey
      );

      state = state.copyWith(
        isLoading: false,
        champions: champions,
      );
    } catch (e) {
      debugPrint('Error loading champions: $e');
      state = state.copyWith(
        isLoading: false,
        error: '챔피언 정보를 불러오는 데 실패했습니다.',
      );
    }
  }
}