import 'package:flutter/foundation.dart';
import 'package:selfie_pick/feature/my_entry/model/m_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class VotingState {
  // 1. 투표 상태
  final List<EntryModel> candidates; // 현재 로드된 모든 후보 목록
  final List<EntryModel> selectedPicks; // 금/은/동으로 선택된 3명의 후보
  final bool isVoted; // 투표 완료 여부 (True 시 랭킹 조회 화면으로 전환)
  final bool isSubmitting; // 투표 제출 중 로딩 상태

  // 2. 페이징 상태
  final bool isLoadingNextPage;
  final bool hasMorePages;
  final DocumentSnapshot? lastDocument; // 다음 페이지 로드를 위한 커서

  // 3. ✨ 새로고침 관리
  final DateTime? lastFetchedTime; // 마지막으로 서버에 요청을 보낸 시간 (로컬 캐싱 관리용)


  const VotingState({
    this.candidates = const [],
    this.selectedPicks = const [],
    this.isVoted = false,
    this.isSubmitting = false,
    this.isLoadingNextPage = false,
    this.hasMorePages = true,
    this.lastDocument,
    this.lastFetchedTime, // 초기값 null
  });

  // 불변성을 위한 copyWith
  VotingState copyWith({
    List<EntryModel>? candidates,
    List<EntryModel>? selectedPicks,
    bool? isVoted,
    bool? isSubmitting,
    bool? isLoadingNextPage,
    bool? hasMorePages,
    DocumentSnapshot? lastDocument,
    DateTime? lastFetchedTime, // ⬅️ copyWith에 추가
  }) {
    return VotingState(
      candidates: candidates ?? this.candidates,
      selectedPicks: selectedPicks ?? this.selectedPicks,
      isVoted: isVoted ?? this.isVoted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      lastDocument: lastDocument ?? this.lastDocument,
      lastFetchedTime: lastFetchedTime ?? this.lastFetchedTime, // ⬅️ 값 유지
    );
  }

  @override
  String toString() {
    return 'VotingStatus{candidates: $candidates, selectedPicks: $selectedPicks, isVoted: $isVoted, isSubmitting: $isSubmitting, isLoadingNextPage: $isLoadingNextPage, hasMorePages: $hasMorePages, lastDocument: $lastDocument, lastFetchedTime: $lastFetchedTime}';
  }
}