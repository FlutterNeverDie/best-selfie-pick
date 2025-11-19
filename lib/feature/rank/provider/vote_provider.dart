import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/rank/provider/repo/repo_ranking.dart';
import '../../../shared/provider/contest_status/contest_status_provider.dart';
import 'model/m_voting_status.dart';

import '../../my_contest/model/m_entry.dart';
import '../../auth/provider/auth_notifier.dart';

// 💡 VoteNotifierProvider 정의
final voteProvider = StateNotifierProvider<VoteNotifier, VotingStatus>((ref) {
  final rankingRepo = ref.watch(rankingRepoProvider);
  final authState = ref.watch(authProvider);
  final contestStatus = ref.watch(contestStatusProvider);

  // 초기 로딩 또는 데이터 불충분 시 기본 상태 반환
  if (authState.user == null || contestStatus.currentWeekKey == null) {
    return VoteNotifier(rankingRepo, '', '', '');
  }

  // VoteNotifier가 관리할 최종 데이터
  return VoteNotifier(
    rankingRepo,
    authState.user!.uid,
    authState.user!.region, // UserModel의 지역 필드
    contestStatus.currentWeekKey!,
  );
}, name:  'voteProvider');

class VoteNotifier extends StateNotifier<VotingStatus> {
  final RankingRepository _repository;
  final String _userId;
  final String _regionCity;
  final String _currentWeekKey;

  // 💡 투표 선택 제한 수
  static const int MAX_PICKS = 3;

  VoteNotifier(
    this._repository,
    this._userId,
    this._regionCity,
    this._currentWeekKey,
  ) : super(const VotingStatus()) {
    // 💡 초기화 시 데이터 로드 시작
    if (_userId.isNotEmpty) {
      checkIfAlreadyVoted(); // 투표 완료 여부 선행 체크
      loadCandidates();
    }
  }

  // ====================================================================
  // 1. 초기 투표 완료 여부 체크
  // ====================================================================

  /// 투표 완료 기록이 있는지 확인하고 상태를 업데이트합니다.
  Future<void> checkIfAlreadyVoted() async {
    if (_userId.isEmpty || _regionCity.isEmpty || _currentWeekKey.isEmpty)
      return;

    try {
      final isVoted = await _repository.checkIfVoted(
        _userId,
        _currentWeekKey,
        _regionCity,
      );

      // 이미 투표 완료 상태라면 isVoted를 true로 설정하여 랭킹 화면으로 전환
      if (mounted) {
        state = state.copyWith(isVoted: isVoted);
      }
    } catch (e) {
      debugPrint('Error checking vote status: $e');
      // UI에서 에러를 처리하도록 Exception을 던질 수도 있으나, 여기서는 상태만 업데이트
    }
  }

  // ====================================================================
  // 2. 데이터 로드 및 페이징 (후보 목록)
  // ====================================================================

  /// 초기 데이터 로드 및 무한 스크롤 다음 페이지 로드 로직 통합
  Future<void> loadCandidates() async {
    if (state.isVoted || state.isLoadingNextPage || !state.hasMorePages) return;

    final isInitialLoad = state.candidates.isEmpty;

    // 초기 로딩 시 candidates를 비우지 않고, 다음 페이지 로딩 상태로 전환
    state = state.copyWith(isLoadingNextPage: true);

    try {
      // 💡 Repository를 통해 후보 목록 조회
      final snapshot = await _repository.fetchCandidatesForVoting(
        _regionCity,
        _currentWeekKey,
        startAfterDoc: state.lastDocument,
      );

      final newCandidates = snapshot.docs
          .map((doc) => EntryModel.fromMap(doc.data(), doc.id))
          .toList();

      // 로드된 개수가 배치 사이즈와 같으면 다음 페이지가 더 있을 수 있음
      final hasMore = newCandidates.length == CANDIDATE_BATCH_SIZE;

      // 새 후보 목록을 기존 목록에 추가
      final updatedCandidates = [...state.candidates, ...newCandidates];



      // 상태 업데이트
      if (mounted) {
        state = state.copyWith(
          candidates: updatedCandidates,
          isLoadingNextPage: false,
          hasMorePages: hasMore,
          lastDocument: snapshot.docs.isNotEmpty
              ? snapshot.docs.last
              : state.lastDocument,
        );
      }
    } catch (e, stack) {
      debugPrint('Error loading candidates: $e');
      if (mounted) {
        state = state.copyWith(isLoadingNextPage: false); // 로딩만 해제
        // throw Exception('후보 목록을 불러오는 데 실패했습니다.');
      }
    }
  }

  // ====================================================================
  // 3. 투표 선택 로직 (UX)
  // ====================================================================

  /// 후보를 금/은/동 투표 목록에 추가하거나 제거합니다.
  void toggleCandidatePick(EntryModel candidate) {
    if (state.isVoted) return; // 투표 완료 시 선택 불가

    final currentPicks = List<EntryModel>.from(state.selectedPicks);

    if (currentPicks.contains(candidate)) {
      // 이미 선택된 경우: 선택 목록에서 제거 (선택 해제)
      currentPicks.remove(candidate);
    } else {
      // 선택되지 않은 경우
      if (currentPicks.length < MAX_PICKS) {
        // 최대 3명 미만일 때만 추가
        currentPicks.add(candidate);
      } else {
        // 최대 3명이 이미 선택된 경우, 가장 오래된 (가장 먼저 선택된) 항목을 제거하고 새로 추가
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
      // 1. CF 호출을 위한 데이터 변환 (금/은/동 순서 확정)
      final votesData = [
        {'entryId': state.selectedPicks[0].entryId, 'voteType': 'gold'},
        {'entryId': state.selectedPicks[1].entryId, 'voteType': 'silver'},
        {'entryId': state.selectedPicks[2].entryId, 'voteType': 'bronze'},
      ];

      // 2. Repository를 통해 CF 호출
      await _repository.submitVotesToCF(
        weekKey: _currentWeekKey,
        regionId: _regionCity,
        votes: votesData.cast<Map<String, String>>(),
      );

      // 3. 성공 시 상태 업데이트
      if (mounted) {
        state = state.copyWith(isVoted: true, isSubmitting: false);
        debugPrint('투표 제출 성공: 랭킹 조회 화면으로 전환Current User UID:됩니다.');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
      // UI 위젯으로 오류를 다시 던져서 사용자에게 메시지를 보여줍니다.
      rethrow;
    }
  }
}
