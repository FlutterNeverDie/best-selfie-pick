import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:selfie_pick/core/data/collection.dart';

import '../../../../shared/interface/i_date_util.dart';
import '../../../rank/provider/repo/repo_vote.dart';
import '../../model/m_entry.dart';

final entryRepoProvider = Provider((ref) => EntryRepository(
      FirebaseFirestore.instance, // 인스턴스 주입
      FirebaseStorage.instance, // 인스턴스 주입
    ));

class EntryRepository {
  static int CANDIDATE_BATCH_SIZE = 10;

  // 💡 final 필드로 선언하고 생성자로부터 주입받습니다.
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // IDateUtil 구현체를 Repository 내부에서 인스턴스화합니다.
  final IDateUtil _dateUtil = DateUtilImpl();

  // 💡 생성자를 통해 DB 및 Storage 인스턴스 주입
  EntryRepository(this._firestore, this._storage);

  /// 1. 현재 회차의 참가 기록 조회 (My Entry Tab의 핵심 쿼리)
  Future<EntryModel?> fetchCurrentEntry(
      String userId, String weekKey, String regionCity) async {
    try {
      final querySnapshot = await _firestore
          .collection(MyCollection.ENTRIES)
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

  /// 2. 사진을 Cloud Storage에 업로드 (썸네일만 저장하는 최적화 버전)
  Future<Map<String, String>> uploadPhoto(
      String userId, File photoFile, String regionCity, String snsId) async {
    const methodName = 'EntryRepository.사진업로드(uploadPhoto_V2_ThumbnailOnly)';
    final currentWeekKey = _dateUtil.getContestWeekKey(DateTime.now());

    final baseFileName = '${userId}_${snsId}_$currentWeekKey.webp';
    XFile? thumbnailFileX;

    // 💡 썸네일 경로만 정의
    final thumbnailStoragePath =
        'entry_photos/$regionCity/$currentWeekKey/thumb_$baseFileName';

    // 썸네일 생성 및 업로드에 걸린 총 시간 측정을 위한 시작 시간
    final startTime = DateTime.now();

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;

      // ----------------------------------------------------
      // Step 1. 썸네일 파일 생성 (원본을 바로 리사이즈/압축)
      // ----------------------------------------------------
      final time1_start = DateTime.now();
      final thumbnailPath = p.join(tempPath, 'thumb_$baseFileName');

      // 💡 원본을 바로 리사이즈하여 썸네일 파일 하나만 생성합니다.
      thumbnailFileX = await FlutterImageCompress.compressAndGetFile(
        photoFile.path,
        thumbnailPath,
        minWidth: 720, // 💡 썸네일 너비를 조금 더 키워 퀄리티 확보 (예: 720px)
        minHeight: 900,
        quality: 75, // 품질을 약간 올려서 원본에 가깝게 유지
        format: CompressFormat.webp,
      );

      if (thumbnailFileX == null) throw Exception("썸네일 파일 생성 실패.");
      final time1_end = DateTime.now();
      debugPrint(
          '$methodName: [시간 측정] 1. 썸네일 생성 및 압축 소요 시간: ${time1_end.difference(time1_start).inMilliseconds} ms');

      // ----------------------------------------------------
      // Step 2. 썸네일 업로드 (Storage 통신)
      // ----------------------------------------------------
      final time2_start = DateTime.now();
      final thumbnailUploadTask = _storage
          .ref()
          .child(thumbnailStoragePath)
          .putFile(File(thumbnailFileX.path),
              SettableMetadata(contentType: 'image/webp'));
      final thumbnailSnapshot = await thumbnailUploadTask;
      final thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
      final time2_end = DateTime.now();
      debugPrint(
          '$methodName: [시간 측정] 2. Storage 업로드 소요 시간: ${time2_end.difference(time2_start).inMilliseconds} ms');

      // ----------------------------------------------------
      // Final. 최종 정리
      // ----------------------------------------------------
      final thumbnailSize = File(thumbnailFileX.path).lengthSync() / 1024;
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint(
          '$methodName: [최종 업로드] 총 소요 시간: $totalTime ms, 최종 파일 크기: $thumbnailSize KB');

      // 💡 썸네일 URL을 두 필드에 모두 반환 (원본 없음)
      return {
        'photoUrl': thumbnailUrl, // 💡 원본 자리에 썸네일 URL을 대체
        'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      debugPrint('Error uploading photo or creating thumbnail: $e');
      throw Exception('사진 업로드 중 오류가 발생했습니다.');
    } finally {
      // 💡 임시 썸네일 파일만 삭제
      if (thumbnailFileX != null) {
        File(thumbnailFileX.path).deleteSync();
      }
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
      entryId: '',
      // Firestore가 ID를 할당할 예정
      userId: userId,
      regionCity: regionCity,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      snsId: snsId,
      weekKey: currentWeekKey,
      status: 'pending',
      // 관리자 승인 대기 상태로 저장
      createdAt: now,
    );

    // 💡 추가된 디버그 코드: Firestore로 전송될 최종 Map 데이터 출력
    final dataToSave = newEntry.toMap();
    debugPrint('$methodName: [전송 데이터 확인] Firestore로 전송될 Map: $dataToSave');

    try {
      final docRef = await _firestore
          .collection(MyCollection.ENTRIES)
          .add(dataToSave); // dataToSave 사용

      // 저장된 문서 ID를 포함하여 EntryModel 반환
      return newEntry.copyWith(entryId: docRef.id);
    } catch (e) {
      debugPrint('Error saving entry: $e');
      throw Exception('참가 신청 정보를 저장하는 중 오류가 발생했습니다.');
    }
  }

  /// 6. 참가 기록 및 사진 삭제 (반려 후 재신청 시 사용)
  Future<void> deleteEntryAndPhoto(EntryModel entry) async {
    const methodName = 'EntryRepository.데이터_삭제(deleteEntryAndPhoto)';

    // 1. Firestore 문서 삭제
    try {
      await _firestore
          .collection(MyCollection.ENTRIES)
          .doc(entry.entryId)
          .delete();
      debugPrint(
          '$methodName: [성공] Firestore 문서 삭제 완료. EntryID: ${entry.entryId}');
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

  Future<QuerySnapshot<Map<String, dynamic>>> fetchCandidatesForVoting(
      String regionCity, String weekKey,
      {DocumentSnapshot? startAfterDoc}) async {
    // ... (로직 유지)
    Query query = _firestore
        .collection(MyCollection.ENTRIES)
        .where('regionCity', isEqualTo: regionCity)
        .where('weekKey', isEqualTo: weekKey)
        .where('status', isEqualTo: 'approved')
        .orderBy('totalScore', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return await query.limit(CANDIDATE_BATCH_SIZE).get()
        as QuerySnapshot<Map<String, dynamic>>;
  }

  /// 7. 💡 [신규] 투표 상태 변경 (비공개/공개 전환)
  Future<void> setEntryStatus(String entryId, String newStatus) async {
    try {
      await _firestore.collection(MyCollection.ENTRIES).doc(entryId).update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Entry status updated to $newStatus for entry $entryId');
    } catch (e) {
      debugPrint('Error setting entry status to $newStatus: $e');
      throw Exception('참가 상태를 변경하는 데 실패했습니다.');
    }
  }
}
