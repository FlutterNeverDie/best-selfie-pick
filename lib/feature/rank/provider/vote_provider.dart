// lib/feature/ranking/provider/vote_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/rank/provider/repo/repo_ranking.dart';

import 'package:selfie_pick/feature/my_contest/model/m_entry.dart';
import 'package:selfie_pick/shared/provider/contest_status/contest_status_provider.dart'; // ContestStatusNotifier
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';

import 'model/m_voting_status.dart'; // AuthNotifier

// 💡 VoteNotifierProvider 정의
final voteProvider = StateNotifierProvider<VoteNotifier, VotingStatus>((ref) {
  final rankingRepo = ref.watch(rankingRepoProvider);
  final authState = ref.watch(authProvider);
  final contestStatus = ref.watch(contestStatusProvider);

  // 필수 정보가 로드될 때까지 Notifier 생성을 지연하거나 기본값으로 처리합니다.
  if (authState.user == null || contestStatus.currentWeekKey == null) {
    // 초기 로딩 또는 데이터 불충분 시 기본 상태 반환
    return VoteNotifier(rankingRepo, '', '', '');
  }

  return VoteNotifier(
    rankingRepo,
    authState.user!.uid,
    authState.user!.region, // UserModel의 지역 필드 가정
    contestStatus.currentWeekKey!,
  );
});


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
      loadCandidates();
      // 투표 완료 여부 체크 로직도 여기서 호출되어야 하지만, 나중에 추가 예정
    }
  }

  // ====================================================================
  // 1. 데이터 로드 및 페이징
  // ====================================================================

  /// 초기 데이터 로드 및 무한 스크롤 다음 페이지 로드 로직 통합
  Future<void> loadCandidates() async {
    if (state.isVoted || state.isLoadingNextPage || !state.hasMorePages) return;

    // 초기 로딩이 아닌 경우 (다음 페이지 로딩)
    final isInitialLoad = state.candidates.isEmpty;

    // 로딩 상태 시작
    state = state.copyWith(isLoadingNextPage: true);

    try {
      // 💡 Repository를 통해 10개 후보 목록 조회
      final snapshot = await _repository.fetchCandidatesForVoting(
        _regionCity,
        _currentWeekKey,
        startAfterDoc: state.lastDocument,
      );

      final newCandidates = snapshot.docs
          .map((doc) => EntryModel.fromMap(doc.data(), doc.id))
          .toList();

      final hasMore = newCandidates.length == CANDIDATE_BATCH_SIZE;

      // 새 후보 목록을 기존 목록에 추가
      final updatedCandidates = [...state.candidates, ...newCandidates];

      // 상태 업데이트
      state = state.copyWith(
        candidates: updatedCandidates,
        isLoadingNextPage: false,
        hasMorePages: hasMore, // 로드된 개수가 배치 사이즈와 같으면 다음 페이지가 더 있을 수 있음
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument, // 마지막 문서 업데이트
      );

    } catch (e, stack) {
      // 초기 로딩 실패 시 에러 상태로 처리할 수도 있으나, 여기서는 UI 에러 핸들링에 맡깁니다.
      debugPrint('Error loading candidates: $e');
      state = state.copyWith(isLoadingNextPage: false); // 로딩만 해제
      // throw Exception('후보 목록을 불러오는 데 실패했습니다.'); // UI 에러 핸들링을 위해 throw
    }
  }

  // ====================================================================
  // 2. 투표 선택 로직 (오버레이와 연동)
  // ====================================================================

  /// 후보를 금/은/동 투표 목록에 추가하거나 제거합니다.
  void toggleCandidatePick(EntryModel candidate) {
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

  /// 최종 투표 제출 로직 (나중에 Cloud Functions 연동)
  Future<void> submitPicks() async {
    if (state.selectedPicks.length != MAX_PICKS) {
      throw Exception('금/은/동 3명을 모두 선택해야 합니다.');
    }

    // 💡 투표 로직 (CF 호출)을 여기서 실행합니다. (현재는 Mock)
    debugPrint('투표 제출 준비: Gold, Silver, Bronze 순서로 CF 호출 예정.');

    // ... (FunctionsRepository.submitVote 호출) ...

    // 성공 가정 후 상태 업데이트
    state = state.copyWith(isVoted: true);
    // UI는 WRankingListView로 분기될 것입니다.
  }
}