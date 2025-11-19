import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Cloud Functions 사용

// 💡 페이징 크기 상수 정의
const int CANDIDATE_BATCH_SIZE = 10;

// Repository Provider 정의: DB 인스턴스들을 주입합니다.
final rankingRepoProvider = Provider<RankingRepository>((ref) => RankingRepository(
  FirebaseFirestore.instance,
  FirebaseFunctions.instance, // Cloud Functions 인스턴스 주입
));

class RankingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions; // Cloud Functions 인스턴스
  final String _collectionPath = 'contest_entries';
  final String _collectionVotesRecord = 'votes_record'; // votes_record 컬렉션 경로
  final String _collectionVotes = 'votes';
  final String _collectionWeeklyChampions = 'weekly_champions';

  // 💡 Note: 실제 앱 ID 경로는 EntryRepository와 동일하게 처리해야 함.
  // 여기서는 편의상 EntryRepository의 로직이 적용되었다고 가정하고 컬렉션 이름만 사용.

  RankingRepository(this._firestore, this._functions);

  /// 1. 투표 후보 목록 로드 (Infinite Scroll 지원)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchCandidatesForVoting(
      String regionCity,
      String weekKey,
      {DocumentSnapshot? startAfterDoc}
      ) async {
    // ... (로직 유지)
    Query query = _firestore
        .collection(_collectionPath)
        .where('regionCity', isEqualTo: regionCity)
        .where('weekKey', isEqualTo: weekKey)
        .where('status', isEqualTo: 'voting_active')
        .orderBy('createdAt', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return await query.limit(CANDIDATE_BATCH_SIZE).get() as QuerySnapshot<Map<String, dynamic>>;
  }


  /// 2. 투표 완료 여부 확인 (V3.0: 주차별 지역당 1회 투표)
  /// * submitVote 함수와 동일한 검증 로직을 사용합니다.
  Future<bool> checkIfVoted(String userId, String weekKey, String regionId) async {
    try {
      // 💡 votes_record 컬렉션에서 해당 사용자가 이 주차, 이 지역에 투표했는지 확인
      final querySnapshot = await _firestore
          .collection(_collectionVotesRecord)
          .where('userId', isEqualTo: userId)
          .where('weekKey', isEqualTo: weekKey)
          .where('regionId', isEqualTo: regionId)
          .limit(1)
          .get();

      debugPrint('[본인 투표 기록 조회 결과]  ${querySnapshot.docs.length} documents.');

      return querySnapshot.docs.isNotEmpty; // 문서가 있으면 true (투표 완료)
    }  on FirebaseException catch (e) {
      debugPrint('Error checking vote status (Firebase): ${e.code} - ${e.message}');
      throw Exception('투표 기록을 확인하는 중 DB 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      debugPrint('Error checking vote status (Unknown): $e');
      throw Exception('투표 기록을 확인하는 중 알 수 없는 오류가 발생했습니다.');
    }
  }


  /// 3. 최종 투표 제출 (Cloud Functions 호출)
  /// * submitVote Cloud Function을 호출하여 서버에서 검증 및 트랜잭션을 실행합니다.
  Future<void> submitVotesToCF({
    required String weekKey,
    required String regionId,
    required List<Map<String, String>> votes, // [{entryId: id, voteType: 'gold'}, ...]
  }) async {
    const callableName = 'submitVote';
    final callable = _functions.httpsCallable(callableName);

    final data = {
      'weekKey': weekKey,
      'regionId': regionId,
      'votes': votes,
    };

    try {
      final result = await callable.call(data);

      if (result.data == null || result.data['success'] != true) {
        // 서버에서 HttpsError가 아닌, 일반적인 실패 응답을 보냈을 경우 처리
        throw Exception(result.data['message'] ?? '투표 제출에 실패했습니다.');
      }
    } on FirebaseFunctionsException catch (e) {
      // 서버에서 HttpsError (예: already voted, invalid argument)가 발생했을 경우
      debugPrint('CF Error during submitVotes: ${e.code} - ${e.message}');
      throw Exception(e.message ?? '투표 처리 중 오류가 발생했습니다.');
    } catch (e) {
      debugPrint('Unknown error during submitVotes: $e');
      rethrow;
    }
  }
}