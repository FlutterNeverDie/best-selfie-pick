import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/interface/i_date_util.dart';
import '../../model/m_entry.dart';


// Firebase 글로벌 변수 사용 (실제 앱 ID 경로를 위해 필요)
const String _globalAppId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

// Canvas 환경에서 안전하게 __app_id 변수를 참조합니다.
final String _appId = const bool.fromEnvironment('dart.vm.product')
    ? const String.fromEnvironment('CANVAS_APP_ID', defaultValue: _globalAppId)
    : _globalAppId;


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
  String get _collectionPath => 'artifacts/$_appId/public/data/contest_entries';

  // 💡 생성자를 통해 DB 및 Storage 인스턴스 주입
  EntryRepository(this._firestore, this._storage);


  /// 1. 현재 회차의 참가 기록 조회 (My Entry Tab의 핵심 쿼리)
  Future<EntryModel?> fetchCurrentEntry(String userId, String weekKey, String regionCity) async {
    try {
      // 💡 V3.0 핵심 쿼리: UID, WeekKey, RegionCity 세 가지 필드가 모두 일치해야 함.
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
      debugPrint('Error fetching current entry: $e');
      throw Exception('참가 정보를 불러오는 중 오류가 발생했습니다.');
    }
  }


  /// 2. 사진을 Cloud Storage에 업로드 (WebP 변환/썸네일 로직은 클라이언트 처리 가정)
  Future<Map<String, String>> uploadPhoto(String userId, File photoFile) async {
    // 💡 _dateUtil 내부 인스턴스를 사용하여 weekKey 계산
    final currentWeekKey = _dateUtil.getContestWeekKey(DateTime.now());
    final fileName = '${userId}_$currentWeekKey.webp';
    final storagePath = 'entry_photos/$currentWeekKey/$fileName';

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
    final now = DateTime.now();

    // 💡 _dateUtil 내부 인스턴스를 사용하여 currentWeekKey 계산
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

    try {
      final docRef = await _firestore.collection(_collectionPath).add(newEntry.toMap());

      // 저장된 문서 ID를 포함하여 EntryModel 반환
      return newEntry.copyWith(entryId: docRef.id);
    } catch (e) {
      debugPrint('Error saving entry: $e');
      throw Exception('참가 신청 정보를 저장하는 중 오류가 발생했습니다.');
    }
  }


  /// 4. 실시간 득표 수 스트림 (My Entry Tab의 voting_active 상태에서 사용)
  Stream<EntryModel> streamVotes(String entryId) {
    return _firestore.collection(_collectionPath).doc(entryId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception("참가 문서가 존재하지 않습니다.");
      }
      // Firestore에서 변경된 득표 수를 EntryModel로 변환하여 실시간으로 전달
      return EntryModel.fromMap(snapshot.data()!, snapshot.id);
    }).handleError((e) {
      debugPrint('Error streaming entry votes: $e');
      throw Exception('실시간 득표 정보를 불러오는데 실패했습니다.');
    });
  }

  /// 5. 관리자 승인 완료 후 상태 갱신 (핵심 로직)
  /// * 💡 V3.0 로직: 관리자가 승인(approved)하면, 클라이언트가 바로 voting_active로 전환함.
  Future<void> updateEntryStatusAfterApproval(String entryId, String nextWeekKey) async {
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
}