import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/core/data/collection.dart';

// Repository Provider 정의
final voteRepoProvider = Provider<VoteRepository>((ref) => VoteRepository(
  FirebaseFirestore.instance,
));

class VoteRepository {
  final FirebaseFirestore _firestore;

  VoteRepository(this._firestore);

  /// 2. 투표 완료 여부 확인
  Future<bool> checkIfVoted(
      String userId, String weekKey, String regionId) async {
    try {
      // 💡 금/은/동 투표 내역 중 하나라도 존재하면 투표 완료로 간주
      final querySnapshot = await _firestore
          .collection(MyCollection.VOTES)
          .where('userId', isEqualTo: userId)
          .where('weekKey', isEqualTo: weekKey)
          .where('channel', isEqualTo: regionId)
          .limit(1)
          .get();

      debugPrint('[투표 완료 여부 결과 ${querySnapshot.docs.isNotEmpty}]');

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
          'Error checking vote status (Firebase): ${e.code} - ${e.message}');
      throw Exception('투표 기록을 확인하는 중 DB 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      debugPrint('Error checking vote status (Unknown): $e');
      throw Exception('투표 기록을 확인하는 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 3. 최종 투표 제출 (Direct Firestore Transaction)
  Future<void> submitVotesToCF({
    required String weekKey,
    required String channel,
    required List<Map<String, String>> votes,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final userId = currentUser.uid;

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 투표 기록 생성 (votes) & 점수 업데이트 (contest_entries)
        for (final vote in votes) {
          final entryId = vote['entryId']!;
          final voteType = vote['voteType']!;

          // 1-1. votes 컬렉션에 기록 추가 (금/은/동 3개)
          // 💡 문서 ID를 자동 생성하면 중복 투표 체크가 어렵지만,
          // checkIfVoted가 UI단에서 막아주고 있으므로 여기선 저장에 집중합니다.
          final voteRef = _firestore.collection(MyCollection.VOTES).doc();
          transaction.set(voteRef, {
            'userId': userId,
            'weekKey': weekKey,
            'channel': channel,
            'entryId': entryId,
            'voteType': voteType,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 1-2. contest_entries 점수 증가
          final entryRef = _firestore
              .collection(MyCollection.ENTRIES)
              .doc(entryId);

          int scoreToAdd = 0;
          String fieldToIncrement = '';

          if (voteType == 'gold') {
            scoreToAdd = 5;
            fieldToIncrement = 'goldVotes';
          } else if (voteType == 'silver') {
            scoreToAdd = 3;
            fieldToIncrement = 'silverVotes';
          } else if (voteType == 'bronze') {
            scoreToAdd = 1;
            fieldToIncrement = 'bronzeVotes';
          }

          if (fieldToIncrement.isNotEmpty) {
            transaction.update(entryRef, {
              fieldToIncrement: FieldValue.increment(1),
              'totalScore': FieldValue.increment(scoreToAdd),
            });
          }
        }


      });

      debugPrint('투표 트랜잭션 성공');
    } catch (e) {
      debugPrint('투표 트랜잭션 실패: $e');
      throw Exception('투표 처리 중 오류가 발생했습니다: $e');
    }
  }
}