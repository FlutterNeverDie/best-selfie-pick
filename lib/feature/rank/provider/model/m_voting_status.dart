// lib/feature/ranking/model/m_voting_status.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../my_contest/model/m_entry.dart';

@immutable
class VotingStatus {
  /// 💡 현재까지 무한 스크롤로 로드된 전체 투표 후보 목록 (EntryModel의 썸네일 사용)
  final List<EntryModel> candidates;

  /// 💡 현재 주차에 사용자가 투표를 완료했는지 여부 (투표 완료 시 true)
  final bool isVoted;

  /// 💡 다음 페이지의 후보를 Firestore에서 로드 중인지 여부 (중복 로딩 방지용)
  final bool isLoadingNextPage;

  /// 💡 서버에 더 로드할 후보 데이터가 남아있는지 여부 (Infinite Scroll 종료 조건)
  final bool hasMorePages;

  /// 💡 Firestore 페이징의 커서 역할. 다음 쿼리를 시작할 마지막 문서의 스냅샷
  final DocumentSnapshot? lastDocument;

  /// 💡 사용자가 금/은/동 투표를 위해 현재 선택한 후보 목록 (최대 3명)
  final List<EntryModel> selectedPicks;

  const VotingStatus({
    this.candidates = const [],
    this.isVoted = false,
    this.isLoadingNextPage = false,
    this.hasMorePages = true,
    this.lastDocument,
    this.selectedPicks = const [],
  });

  // 💡 불변성을 위한 수동 copyWith 구현
  VotingStatus copyWith({
    List<EntryModel>? candidates,
    bool? isVoted,
    bool? isLoadingNextPage,
    bool? hasMorePages,
    DocumentSnapshot? lastDocument,
    List<EntryModel>? selectedPicks,
  }) {
    return VotingStatus(
      candidates: candidates ?? this.candidates,
      isVoted: isVoted ?? this.isVoted,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      lastDocument: lastDocument ?? this.lastDocument,
      selectedPicks: selectedPicks ?? this.selectedPicks,
    );
  }
}