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
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      // 내 유저 문서의 blockedUserIds 배열에 대상 ID 추가
      await _firestore.collection(MyCollection.USERS).doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      debugPrint('Block Error: $e');
      throw Exception('차단 처리 중 오류가 발생했습니다.');
    }
  }
}