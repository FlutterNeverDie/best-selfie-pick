import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_entry/provider/repo/entry_repo.dart';
import 'package:selfie_pick/feature/rank/provider/repo/repo_vote.dart';
import 'model/m_voting_status.dart';

import '../../my_entry/model/m_entry.dart';
import '../../auth/provider/auth_notifier.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';

// 💡 VoteNotifierProvider 정의
final voteProvider = NotifierProvider<VoteNotifier, VotingState>(
  () => VoteNotifier(),
  name: 'voteProvider',
);

class VoteNotifier extends Notifier<VotingState> {
  // 💡 투표 선택 제한 수
  static const int MAX_PICKS = 3;

  @override
  VotingState build() {
    // 💡 build() 시점에서 Auth, ContestStatus를 watch하여 Notifier의 생명주기를 결정하고 상태를 초기화합니다.
    final authState = ref.watch(authProvider);
    final contestStatus = ref.watch(contestStatusProvider);

    // 1. 필수 데이터 (UID, Region, WeekKey) 확보
    final userId = authState.user?.uid ?? '';
    final userChannel = authState.user?.channel ?? '';
    final currentWeekKey = contestStatus.currentWeekKey ?? '';

    // 2. 초기 로드가 필요한지 판단 (Provider 생성 시점)
    if (userId.isNotEmpty &&
        userChannel.isNotEmpty &&
        currentWeekKey.isNotEmpty) {
      // 3. 투표 완료 여부와 후보 목록을 비동기로 로드합니다.
      Future.microtask(() => _initializeData());
    }

    // 4. 초기 상태 반환 (isLoadingNextPage: true 제거)
    // 💡 이제 초기 상태는 로딩 중이 아님을 명시합니다. 로딩 상태는 loadCandidates에서 설정됩니다.
    return const VotingState(isLoadingNextPage: false);
  }

  // 💡 Repository와 값을 메서드 내에서 필요할 때마다 가져오는 헬퍼 메서드
  VoteRepository get _voteRepository => ref.read(voteRepoProvider);
  EntryRepository get _entryRepository => ref.read(entryRepoProvider);
  String get _userId => ref.read(authProvider).user!.uid;
  String get _userChannel => ref.read(authProvider).user!.channel;
  String get _currentWeekKey => ref.read(contestStatusProvider).currentWeekKey!;

  // ====================================================================
  // 초기 데이터 로드 (build()에서 비동기 호출)
  // ====================================================================
  Future<void> _initializeData() async {
    // build()에서 이미 로딩 상태를 설정했으므로, 이 시점에서는 isVoted 체크만 수행합니다.
    try {
      await checkIfAlreadyVoted();
      // 투표 완료 상태가 아니라면 후보 로드 시작
      await loadCandidates();
    } catch (e) {
      // 초기 로드 중 발생한 오류는 상태에 반영할 수 있으나, 현재는 로그만 남깁니다.
      debugPrint('Initial data load failed: $e');
      state = state.copyWith(isLoadingNextPage: false, hasMorePages: false);
    }
  }

  // ====================================================================
  // 1. 초기 투표 완료 여부 체크
  // ====================================================================

  /// 투표 완료 기록이 있는지 확인하고 상태를 업데이트합니다.
  Future<void> checkIfAlreadyVoted() async {
    // 💡 Repository 접근에 필요한 값들을 ref.read로 가져옴
    if (_userId.isEmpty || _userChannel.isEmpty || _currentWeekKey.isEmpty)
      return;

    try {
      // ⬅️ _voteRepository 대신 _repository(RankingRepository) 사용
      final isVoted = await _voteRepository.checkIfVoted(
        _userId,
        _currentWeekKey,
        _userChannel,
      );

      // 이미 투표 완료 상태라면 isVoted를 true로 설정하여 랭킹 화면으로 전환
      state = state.copyWith(isVoted: isVoted);
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    }
  }

  // ====================================================================
  // 2. 데이터 로드 및 페이징 (후보 목록)
  // ====================================================================

  /// 초기 데이터 로드 및 무한 스크롤 다음 페이지 로드 로직 통합
  Future<void> loadCandidates() async {
    debugPrint('[채널 참가자 로드 시작...]');
    // 💡  이미 로딩 중이거나, 페이지가 더 없으면 중단
    if (state.isLoadingNextPage || !state.hasMorePages) {
      debugPrint('로딩 중이거나 더 이상 페이지가 없습니다. 로드 중단.');
      return;
    }

    // 💡 Repository 접근에 필요한 값들을 ref.read로 가져옴
    final userChannel = _userChannel;
    final currentWeekKey = _currentWeekKey;

    // 🚨 로딩 시작 (가드 조건 통과 후 여기서 설정)
    state = state.copyWith(isLoadingNextPage: true);

    try {
      // 시간을 비교해서 현재 시간과 30초 이상 차이가 안나면 로딩 중단, 리프레시 취소
      if (state.lastFetchedTime != null) {
        final timeSinceLastFetch =
            DateTime.now().difference(state.lastFetchedTime!);
        if (timeSinceLastFetch.inSeconds < 30) {
          debugPrint('최근에 데이터를 불러왔습니다. 리프레시를 취소합니다.');
          state = state.copyWith(isLoadingNextPage: false);
          return;
        }
      }

      final snapshot = await _entryRepository.fetchCandidatesForVoting(
        userChannel,
        currentWeekKey,
        startAfterDoc: state.lastDocument,
      );

      final newCandidates = snapshot.docs
          .map((doc) => EntryModel.fromMap(doc.data(), doc.id))
          .toList();

      final hasMore =
          newCandidates.length == 10; // CANDIDATE_BATCH_SIZE가 10이라고 가정

      final updatedCandidates = [...state.candidates, ...newCandidates];

      // 상태 업데이트
      state = state.copyWith(
        candidates: updatedCandidates,
        isLoadingNextPage: false,
        hasMorePages: hasMore,
        lastDocument:
            snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument,
        lastFetchedTime: DateTime.now(),
      );
      debugPrint('[채널 참가자 수: ${updatedCandidates.length}]');
    } catch (e, stack) {
      debugPrint('Error loading 참가자 조회: $e');
      state = state.copyWith(isLoadingNextPage: false); // 로딩만 해제
    }
  }

  // ====================================================================
  // 3. 투표 선택 로직 (UX)
  // ====================================================================

  /// 후보를 금/은/동 투표 목록에 추가하거나 제거합니다.
  void togglePick(EntryModel candidate) {
    if (state.isVoted) return;

    final currentPicks = List<EntryModel>.from(state.selectedPicks);

    if (currentPicks.contains(candidate)) {
      currentPicks.remove(candidate);
    } else {
      if (currentPicks.length < MAX_PICKS) {
        currentPicks.add(candidate);
      } else {
        currentPicks.removeAt(0);
        currentPicks.add(candidate);
      }
    }

    state = state.copyWith(selectedPicks: currentPicks);
  }

  // ====================================================================
  // 4. 최종 투표 제출 (Cloud Functions 연동)
  // ====================================================================

  /// 최종 투표 제출 로직 (CF 호출)
  Future<void> submitPicks() async {
    if (state.selectedPicks.length != MAX_PICKS) {
      throw Exception('금/은/동 3명을 모두 선택해야 합니다.');
    }
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      // 💡 Repository 접근에 필요한 값들을 ref.read로 가져옴
      final currentWeekKey = _currentWeekKey;
      final channel = _userChannel;

      // 1. CF 호출을 위한 데이터 변환 (금/은/동 순서 확정)
      final votesData = [
        {'entryId': state.selectedPicks[0].entryId, 'voteType': 'gold'},
        {'entryId': state.selectedPicks[1].entryId, 'voteType': 'silver'},
        {'entryId': state.selectedPicks[2].entryId, 'voteType': 'bronze'},
      ];

      // 2. Repository를 통해 CF 호출
      await _voteRepository.submitVotesToCF(
        weekKey: currentWeekKey,
        channel: channel,
        votes: votesData.cast<Map<String, String>>(),
      );

      // 3. 성공 시 상태 업데이트
      state = state.copyWith(isVoted: true, isSubmitting: false);
      debugPrint('투표 제출 성공: 랭킹 조회 화면으로 전환됩니다.');
    } catch (e) {
      state = state.copyWith(isSubmitting: false);

      rethrow;
    }
  }
}
