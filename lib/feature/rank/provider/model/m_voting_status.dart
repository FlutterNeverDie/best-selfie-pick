import 'package:flutter/foundation.dart';
import '../../../my_contest/model/m_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class VotingStatus {
  // 1. 투표 상태
  final List<EntryModel> candidates; // 현재 로드된 모든 후보 목록
  final List<EntryModel> selectedPicks; // 금/은/동으로 선택된 3명의 후보
  final bool isVoted; // 투표 완료 여부 (True 시 랭킹 조회 화면으로 전환)
  final bool isSubmitting; // 투표 제출 중 로딩 상태 ⬅️ 이 필드가 필요합니다.

  // 2. 페이징 상태
  final bool isLoadingNextPage;
  final bool hasMorePages;
  final DocumentSnapshot? lastDocument; // 다음 페이지 로드를 위한 커서

  const VotingStatus({
    this.candidates = const [],
    this.selectedPicks = const [],
    this.isVoted = false,
    this.isSubmitting = false, // 기본값 false
    this.isLoadingNextPage = false,
    this.hasMorePages = true,
    this.lastDocument,
  });

  // 불변성을 위한 copyWith
  VotingStatus copyWith({
    List<EntryModel>? candidates,
    List<EntryModel>? selectedPicks,
    bool? isVoted,
    bool? isSubmitting, // ⬅️ copyWith에도 포함
    bool? isLoadingNextPage,
    bool? hasMorePages,
    DocumentSnapshot? lastDocument,
  }) {
    return VotingStatus(
      candidates: candidates ?? this.candidates,
      selectedPicks: selectedPicks ?? this.selectedPicks,
      isVoted: isVoted ?? this.isVoted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  @override
  String toString() {
    return 'VotingStatus{candidates: $candidates, selectedPicks: $selectedPicks, isVoted: $isVoted, isSubmitting: $isSubmitting, isLoadingNextPage: $isLoadingNextPage, hasMorePages: $hasMorePages, lastDocument: $lastDocument}';
  }
}