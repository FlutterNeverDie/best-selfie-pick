import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/data/collection.dart';
import '../model/m_report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository(this._firestore);

  /// 1. 신고 제출하기
  Future<void> submitReport(ReportModel report) async {
    try {
      // reports 컬렉션에 추가 (문서 ID는 자동 생성되거나 모델의 ID 사용)
      // 여기서는 모델의 reportId가 이미 AutoID 형식이 아니라고 가정하고 add 사용,
      // 혹은 set을 사용. ReportModel 생성 시점에 ID를 만들었다면 set 권장.

      // 편의상 add로 새로운 ID 생성 로직
      await _firestore.collection(MyCollection.REPORT).add(report.toMap());
    } catch (e) {
      debugPrint('Report Error: $e');
      throw Exception('신고 처리 중 오류가 발생했습니다.');
    }
  }

  /// 2. 유저 차단하기
  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
    required String snsId,    // 💡 추가됨
    required String channel,  // 💡 추가됨
    required String weekKey,  // 💡 추가됨
  }) async {
    try {
      final batch = _firestore.batch();

      // A. 필터링용 배열에 ID 추가 (기존 로직)
      final userRef = _firestore.collection(MyCollection.USERS).doc(currentUserId);
      batch.update(userRef, {
        'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
      });

      // B. 💡 [신규] 차단 내역 서브 컬렉션에 상세 정보 저장 (Snapshot)
      final historyRef = userRef.collection('blocked_history').doc(targetUserId);
      batch.set(historyRef, {
        'uid': targetUserId,
        'snsId': snsId,
        'channel': channel,
        'weekKey': weekKey,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error blockUser(차단 - Repo) user: ${e.toString()}');
      throw Exception('차단 처리 중 오류가 발생했습니다.');
    }
  }

  /// 3. 차단 해제하기
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // A. 배열에서 제거
      final userRef = _firestore.collection(MyCollection.USERS).doc(currentUserId);
      batch.update(userRef, {
        'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
      });

      // B. 💡 서브 컬렉션 문서 삭제
      final historyRef = userRef.collection('blocked_history').doc(targetUserId);
      batch.delete(historyRef);

      await batch.commit();
    } catch (e) {
      throw Exception('차단 해제 처리 중 오류가 발생했습니다.');
    }
  }
}