// 챔피언 상태 모델 (복사)
import '../../../my_contest/model/m_entry.dart';

class ChampionState {
  final bool isLoading;
  final List<EntryModel> champions;
  final String? error;

  const ChampionState({
    this.isLoading = false,
    this.champions = const [],
    this.error,
  });

  ChampionState copyWith({
    bool? isLoading,
    List<EntryModel>? champions,
    String? error,
  }) {
    return ChampionState(
      isLoading: isLoading ?? this.isLoading,
      champions: champions ?? this.champions,
      error: error,
    );
  }
}