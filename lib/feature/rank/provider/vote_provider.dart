import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_entry/provider/repo/entry_repo.dart';
import 'package:selfie_pick/feature/rank/provider/repo/repo_vote.dart';
import 'model/m_voting_status.dart';

import '../../my_entry/model/m_entry.dart';
import '../../auth/provider/auth_notifier.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';

final voteProvider = NotifierProvider<VoteNotifier, VotingState>(
      () => VoteNotifier(),
  name: 'voteProvider',
);

class VoteNotifier extends Notifier<VotingState> {
  // 💡 투표 선택 제한 수
  static const int MAX_PICKS = 3;
  // 💡 한 번에 불러올 데이터 수 (상수로 관리 권장)
  static const int FETCH_LIMIT = 10;

  @override
  VotingState build() {
    // 생명주기 관리를 위한 watch
    final authState = ref.watch(authProvider);
    final contestStatus = ref.watch(contestStatusProvider);

    final userId = authState.user?.uid ?? '';
    final userChannel = authState.user?.channel ?? '';
    final currentWeekKey = contestStatus.currentWeekKey ?? '';

    // 초기 데이터 로드 조건 충족 시 실행
    if (userId.isNotEmpty &&
        userChannel.isNotEmpty &&
        userChannel != 'NotSet' && // 채널 미설정 시 로드 방지
        currentWeekKey.isNotEmpty) {
      Future.microtask(() => _initializeData());
    }

    return const VotingState(isLoadingNextPage: false);
  }

  // 💡 헬퍼 메서드 (안전한 접근 보장)
  VoteRepository get _voteRepository => ref.read(voteRepoProvider);
  EntryRepository get _entryRepository => ref.read(entryRepoProvider);

  // 🚨 [수정] Null Safety 강화: 유저가 없거나 차단 목록이 null일 경우 안전하게 빈 리스트 반환
  List<String> get _blockedUserIds =>
      ref.read(authProvider).user?.blockedUserIds ?? [];

  String get _userId => ref.read(authProvider).user?.uid ?? '';
  String get _userChannel => ref.read(authProvider).user?.channel ?? '';
  String get _currentWeekKey => ref.read(contestStatusProvider).currentWeekKey ?? '';


  // ====================================================================
  // 초기 데이터 로드
  // ====================================================================
  Future<void> _initializeData() async {
    try {
      await checkIfAlreadyVoted();
      // 아직 데이터를 안 불러왔다면 로드 시작
      if (state.candidates.isEmpty) {
        await loadCandidates();
      }
    } catch (e) {
      debugPrint('Initial data load failed: $e');
      state = state.copyWith(isLoadingNextPage: false, hasMorePages: false);
    }
  }

  // ====================================================================
  // 1. 초기 투표 완료 여부 체크
  // ====================================================================
  Future<void> checkIfAlreadyVoted() async {
    if (_userId.isEmpty || _userChannel.isEmpty || _currentWeekKey.isEmpty) return;

    try {
      final isVoted = await _voteRepository.checkIfVoted(
        _userId,
        _currentWeekKey,
        _userChannel,
      );
      state = state.copyWith(isVoted: isVoted);
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    }
  }

  // ====================================================================
  // 2. 데이터 로드 및 페이징 (후보 목록)
  // ====================================================================
  Future<void> loadCandidates() async {
    // 이미 로딩 중이거나, 더 이상 페이지가 없으면 중단
    if (state.isLoadingNextPage || !state.hasMorePages) return;

    // 🚨 로딩 시작 상태 변경
    state = state.copyWith(isLoadingNextPage: true);

    try {
      // 리프레시 스로틀링 (30초 제한)
      if (state.lastFetchedTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(state.lastFetchedTime!);
        if (timeSinceLastFetch.inSeconds < 30 && state.candidates.isNotEmpty) {
          // 데이터가 아예 없을 때는 30초 제한 무시하고 로드 시도
          debugPrint('최근에 데이터를 불러왔습니다. 리프레시를 취소합니다.');
          state = state.copyWith(isLoadingNextPage: false);
          return;
        }
      }

      final userChannel = _userChannel;
      final currentWeekKey = _currentWeekKey;

      // 1. DB Fetch
      final snapshot = await _entryRepository.fetchCandidatesForVoting(
        userChannel,
        currentWeekKey,
        startAfterDoc: state.lastDocument,
        limit: FETCH_LIMIT,
      );

      final newCandidates = snapshot.docs
          .map((doc) => EntryModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. 🚨 차단된 유저 필터링
      final blockedIds = _blockedUserIds; // getter 호출
      final filteredCandidates = newCandidates.where((entry) {
        return !blockedIds.contains(entry.userId);
      }).toList();

      // 3. 🚨 [수정] hasMore 판단 로직 수정
      // 필터링된 개수가 아니라 'DB에서 가져온 원본 개수'가 LIMIT과 같으면 더 있다고 판단해야 함
      final bool hasMore = newCandidates.length >= FETCH_LIMIT;

      // 4. 상태 업데이트 준비
      final updatedCandidates = [...state.candidates, ...filteredCandidates];
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument;

      state = state.copyWith(
        candidates: updatedCandidates,
        isLoadingNextPage: false,
        hasMorePages: hasMore,
        lastDocument: lastDoc,
        lastFetchedTime: DateTime.now(),
      );

      debugPrint('[로드 완료] 원본: ${newCandidates.length}, 필터후: ${filteredCandidates.length}, 누적: ${updatedCandidates.length}');

      // 5. 🚨 [추가] 중요! 필터링 후 남은 게 없는데 DB에 데이터가 더 있다면 재귀 호출
      // (이 로직이 없으면 차단된 유저만 불러와졌을 때 화면이 멈춘 것처럼 보임)
      if (filteredCandidates.isEmpty && hasMore) {
        debugPrint('[재귀 호출] 불러온 데이터가 모두 차단된 유저입니다. 다음 페이지를 즉시 로드합니다.');
        await loadCandidates();
      }

    } catch (e, stack) {
      debugPrint('Error loading 참가자 조회: $e');
      state = state.copyWith(isLoadingNextPage: false);
    }
  }

  // ====================================================================
  // 3. 투표 선택 로직 (UX)
  // ====================================================================
  void togglePick(EntryModel candidate) {
    if (state.isVoted) return;

    final currentPicks = List<EntryModel>.from(state.selectedPicks);

    if (currentPicks.contains(candidate)) {
      currentPicks.remove(candidate);
    } else {
      if (currentPicks.length < MAX_PICKS) {
        currentPicks.add(candidate);
      } else {
        // FIFO 방식: 가장 먼저 선택한 것을 제거하고 새 후보 추가
        currentPicks.removeAt(0);
        currentPicks.add(candidate);
      }
    }
    state = state.copyWith(selectedPicks: currentPicks);
  }

  // ====================================================================
  // 4. 최종 투표 제출
  // ====================================================================
  Future<void> submitPicks() async {
    if (state.selectedPicks.length != MAX_PICKS) {
      throw Exception('금/은/동 3명을 모두 선택해야 합니다.');
    }
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final currentWeekKey = _currentWeekKey;
      final channel = _userChannel;

      final votesData = [
        {'entryId': state.selectedPicks[0].entryId, 'voteType': 'gold'},
        {'entryId': state.selectedPicks[1].entryId, 'voteType': 'silver'},
        {'entryId': state.selectedPicks[2].entryId, 'voteType': 'bronze'},
      ];

      await _voteRepository.submitVotesToCF(
        weekKey: currentWeekKey,
        channel: channel,
        votes: votesData.cast<Map<String, String>>(),
      );

      state = state.copyWith(isVoted: true, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }


}