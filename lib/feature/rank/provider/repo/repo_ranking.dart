// lib/feature/ranking/repository/repo_ranking.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 💡 페이징 크기 상수 정의
const int CANDIDATE_BATCH_SIZE = 10;

// 💡 AuthRepository 제거
final rankingRepoProvider = Provider<RankingRepository>((ref) => RankingRepository(
  FirebaseFirestore.instance,
));

class RankingRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'contest_entries';

  RankingRepository(this._firestore);

  /// 1. 투표 후보 목록 로드 (Infinite Scroll 지원)
  /// 비용 효율을 위해 10개씩 로드하며, 페이징 커서를 사용합니다.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchCandidatesForVoting(
      String regionCity,
      String weekKey,
      {DocumentSnapshot? startAfterDoc}
      ) async {
    Query query = _firestore
        .collection(_collectionPath)
        .where('regionCity', isEqualTo: regionCity)
        .where('weekKey', isEqualTo: weekKey)
        .where('status', isEqualTo: 'voting_active')
        .orderBy('createdAt', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    // 💡 10개 항목만 읽어오는 비용 효율적인 쿼리
    return await query.limit(CANDIDATE_BATCH_SIZE).get() as QuerySnapshot<Map<String, dynamic>>;
  }

// 2. 투표 완료 여부 확인 (나중에 구현)
// 3. 최종 투표 제출 (나중에 구현)

}