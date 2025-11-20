import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/core/data/collection.dart';

import 'm_inquiry_data.dart';

final inquiryRepoProvider = Provider((ref) => InquiryRepository(
  FirebaseFirestore.instance,
));

class InquiryRepository {
  final FirebaseFirestore _firestore;

  // 💡 수정: 모든 문의는 이 단일 컬렉션에 저장됩니다.

  InquiryRepository(this._firestore);

  /// 문의를 Firestore에 제출합니다.
  Future<void> submitInquiry(InquiryData inquiry) async {
    // 💡 문의 제목(title)을 기반으로 하위 컬렉션을 분리하는 로직 제거

    // 1. 문서 ID 생성 (날짜_UID 조합)
    final now = inquiry.submittedAt;
    final docId = '${now.year}년${now.month}월${now.day}일${now.hour}시_${inquiry.userId}';

    final dataToSave = inquiry.toMap();

    debugPrint('Inquiry submitted to: ${MyCollection.INQUIRIES}/$docId');

    try {
      // 2. Firestore에 데이터 저장 (단일 컬렉션 사용)
      await _firestore.collection(MyCollection.INQUIRIES).doc(docId).set(dataToSave);
      debugPrint('Inquiry successfully saved.');
    } catch (e) {
      debugPrint('Error submitting inquiry: $e');
      throw Exception('문의 제출 중 오류가 발생했습니다.');
    }
  }
}