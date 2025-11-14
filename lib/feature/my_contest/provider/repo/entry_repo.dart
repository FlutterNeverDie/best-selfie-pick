import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/interface/i_date_util.dart';
import '../../model/m_entry.dart';





// Repository Provider 정의: DB 인스턴스들을 주입합니다.
final entryRepoProvider = Provider((ref) => EntryRepository(
  FirebaseFirestore.instance, // 인스턴스 주입
  FirebaseStorage.instance,   // 인스턴스 주입
));

class EntryRepository {
  // 💡 final 필드로 선언하고 생성자로부터 주입받습니다.
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // IDateUtil 구현체를 Repository 내부에서 인스턴스화합니다.
  final IDateUtil _dateUtil = DateUtilImpl();

  // DB 경로: /artifacts/{appId}/public/data/contest_entries
  // 💡 Note: 현재 DB 규칙과 일치시키기 위해 'contest_entries'로 임시 수정됨
  // String get _collectionPath => 'artifacts/$_appId/public/data/contest_entries';
  String get _collectionPath => 'contest_entries'; // <-- 임시 최상위 경로 사용 중

  // 💡 생성자를 통해 DB 및 Storage 인스턴스 주입
  EntryRepository(this._firestore, this._storage);


  /// 1. 현재 회차의 참가 기록 조회 (My Entry Tab의 핵심 쿼리)
  Future<EntryModel?> fetchCurrentEntry(String userId, String weekKey, String regionCity) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .where('weekKey', isEqualTo: weekKey)
          .where('regionCity', isEqualTo: regionCity)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // 참가 기록 없음 (미참가 상태)
      }
      final doc = querySnapshot.docs.first;
      return EntryModel.fromMap(doc.data(), doc.id);

    } catch (e) {
      debugPrint('Error fetchCurrentEntry current entry: $e');
      throw Exception('참가 정보를 불러오는 중 오류가 발생했습니다.');
    }
  }


  /// 2. 사진을 Cloud Storage에 업로드 (WebP 변환/썸네일 로직은 클라이언트 처리 가정)
  Future<Map<String, String>> uploadPhoto(String userId, File photoFile, String regionCity, String snsId) async {
    // ... (로직 유지)
    final currentWeekKey = _dateUtil.getContestWeekKey(DateTime.now());
    final fileName = '${userId}_${snsId}_$currentWeekKey.webp';
    final storagePath = 'entry_photos/$regionCity/$currentWeekKey/$fileName';

    try {
      final uploadTask = _storage.ref().child(storagePath).putFile(photoFile,
          SettableMetadata(contentType: 'image/webp') // WebP 타입 명시
      );
      final snapshot = await uploadTask;
      final photoUrl = await snapshot.ref.getDownloadURL();

      // V3.0: 썸네일/WebP 변환은 클라이언트에서 처리 후, 여기서는 동일 URL로 임시 처리
      return {
        'photoUrl': photoUrl,
        'thumbnailUrl': photoUrl,
      };

    } catch (e) {
      debugPrint('Error uploading photo: $e');
      throw Exception('사진 업로드 중 오류가 발생했습니다.');
    }
  }

  /// 3. 참가 신청 데이터 Firestore에 저장 (status: pending)
  Future<EntryModel> saveEntry({
    required String userId,
    required String regionCity,
    required String photoUrl,
    required String thumbnailUrl,
    required String snsId,
  }) async {
    const methodName = 'EntryRepository.참가데이터_저장(saveEntry)'; // 디버깅용 한글 메소드명
    final now = DateTime.now();
    final currentWeekKey = _dateUtil.getContestWeekKey(now);

    final newEntry = EntryModel(
      entryId: '', // Firestore가 ID를 할당할 예정
      userId: userId,
      regionCity: regionCity,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      snsId: snsId,
      weekKey: currentWeekKey,
      status: 'pending', // 관리자 승인 대기 상태로 저장
      createdAt: now,
    );

    // 💡 추가된 디버그 코드: Firestore로 전송될 최종 Map 데이터 출력
    final dataToSave = newEntry.toMap();
    debugPrint('$methodName: [전송 데이터 확인] Firestore로 전송될 Map: $dataToSave');

    try {
      final docRef = await _firestore.collection(_collectionPath).add(dataToSave); // dataToSave 사용

      // 저장된 문서 ID를 포함하여 EntryModel 반환
      return newEntry.copyWith(entryId: docRef.id);
    } catch (e) {
      debugPrint('Error saving entry: $e');
      throw Exception('참가 신청 정보를 저장하는 중 오류가 발생했습니다.');
    }
  }


  // 4. 실시간 득표 수 스트림 (삭제됨 - 필요 시 복구)
  /*
  Stream<EntryModel> streamVotes(String entryId) {
    // ...
  }
  */

  /// 5. 관리자 승인 완료 후 상태 갱신 (핵심 로직)
  /// * 💡 V3.0 로직: 관리자가 승인(approved)하면, 클라이언트가 바로 voting_active로 전환함.
  Future<void> updateEntryStatusAfterApproval(String entryId, String nextWeekKey) async {
    // ... (로직 유지)
    try {
      await _firestore.collection(_collectionPath).doc(entryId).update({
        'status': 'voting_active',
        'weekKey': nextWeekKey, // 현재 진행 중인 회차 키로 최종 확정
        'startedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Entry status and weekKey updated to voting_active');
    } catch (e) {
      debugPrint('Error updating status after approval: $e');
      throw Exception('참가 상태를 활성화하는데 실패했습니다.');
    }
  }


  /// 6. 참가 기록 및 사진 삭제 (반려 후 재신청 시 사용)
  Future<void> deleteEntryAndPhoto(EntryModel entry) async {
    const methodName = 'EntryRepository.데이터_삭제(deleteEntryAndPhoto)';

    // 1. Firestore 문서 삭제
    try {
      await _firestore.collection(_collectionPath).doc(entry.entryId).delete();
      debugPrint('$methodName: [성공] Firestore 문서 삭제 완료. EntryID: ${entry.entryId}');
    } catch (e) {
      // 권한 문제 등이 발생하면, 사용자에게는 재신청을 막지 않고 로그만 남김.
      debugPrint('$methodName: [실패] Firestore 문서 삭제 실패: $e');
    }

    // 2. Storage 사진 삭제
    try {
      // photoUrl에서 Storage 경로(Reference)를 추출하여 삭제합니다.
      final photoRef = _storage.refFromURL(entry.photoUrl);
      await photoRef.delete();
      debugPrint('$methodName: [성공] Storage 사진 삭제 완료. URL: ${entry.photoUrl}');

      // 썸네일 URL이 다르다면 썸네일도 삭제
      if (entry.thumbnailUrl != entry.photoUrl) {
        final thumbRef = _storage.refFromURL(entry.thumbnailUrl);
        await thumbRef.delete();
        debugPrint('$methodName: [성공] Storage 썸네일 삭제 완료.');
      }

    } catch (e) {
      // 사진이 이미 삭제되었을 수도 있으므로, 오류가 발생해도 플로우는 계속 진행
      debugPrint('$methodName: [실패] Storage 사진 삭제 실패: $e');
    }
  }
}