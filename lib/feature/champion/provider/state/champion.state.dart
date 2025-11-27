// 챔피언 상태 모델 (복사)
import '../../model/m_champion.dart';

class ChampionState {
  final bool isLoading;
  final List<ChampionModel> champions;
  final String? error;

  const ChampionState({
    this.isLoading = false,
    this.champions = const [],
    this.error,
  });

  ChampionState copyWith({
    bool? isLoading,
    List<ChampionModel>? champions,
    String? error,
  }) {
    return ChampionState(
      isLoading: isLoading ?? this.isLoading,
      champions: champions ?? this.champions,
      error: error,
    );
  }

  //toStirng
  @override
  String toString() {
    return 'ChampionState{isLoading: $isLoading, champions: $champions, error: $error}';
  }
}
