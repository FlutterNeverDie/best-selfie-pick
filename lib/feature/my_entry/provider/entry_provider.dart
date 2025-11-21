import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_entry/provider/repo/entry_repo.dart';

import '../../../shared/provider/contest_status/contest_status_provider.dart';
import '../../auth/provider/auth_notifier.dart';
import '../model/m_entry.dart';

final entryProvider = AsyncNotifierProvider<EntryNotifier, EntryModel?>(
  () => EntryNotifier(), name:  'EntryProvider',
);

class EntryNotifier extends AsyncNotifier<EntryModel?> {
  EntryRepository get _repository => ref.read(entryRepoProvider);

  @override
  Future<EntryModel?> build() async {
    // 💡 세 가지 필수 조건 감시: UID, WeekKey, Region
    final authState = ref.watch(authProvider);
    final userModel = authState.user;
    final contestStatus = ref.watch(contestStatusProvider);

    // 2. 인증/상태 로딩 및 필수 데이터 확인
    if (authState.isLoading ||
        authState.user == null ||
        contestStatus.currentWeekKey == null ||
        userModel == null) {
      return null;
    }

    final userId = authState.user!.uid;
    final currentWeekKey = contestStatus.currentWeekKey!;
    final currentUserRegion = userModel.region;

    // 3. 현재 주차, 현재 지역, 현재 사용자의 참가 내역 조회 시도
    // 💡 V3.0 핵심: 이 쿼리가 null을 반환하면 미참가로 간주됨 (지난 회차/다른 지역 기록 자동 제외)
    try {
      final currentEntry = await _repository.fetchCurrentEntry(
        userId,
        currentWeekKey,
        currentUserRegion, // 현재 유저의 설정 지역으로 조회 (지역 종속성)
      );


      return currentEntry;
    } catch (e) {
      debugPrint('참가 정보 초기 로드 실패: $e');
      throw Exception('참가 상태를 불러오는데 실패했습니다. 네트워크 또는 DB 연결을 확인해주세요.');
    }
  }

  // 참가 신청 플로우 처리 (repo_entry.dart의 saveEntry 호출)
  Future<void> submitNewEntry({
    required File photo,
    required String snsId,
    required String snsUrl,
  }) async {
    const methodName = 'EntryNotifier.참가신청_제출(submitNewEntry)'; // 디버깅용 한글 메소드명

    final user = ref.read(authProvider).user; // UserModel 로드
    final currentEntry = state.value;

    if (user == null || user.region == 'NotSet') {
      debugPrint('$methodName: [에러] 사용자 정보 및 지역 설정이 유효하지 않습니다.');
      throw Exception('로그인 정보 및 지역 설정이 유효하지 않습니다. 마이페이지를 확인해주세요.');
    }

    // 💡 V3.0: 현재 회차, 현재 지역에 이미 참가 중인지 확인 (단일 참가 강제)
    if (currentEntry != null && currentEntry.status != 'completed') {
// 🚨 새로 추가된 로직: Rejected 상태라면 기존 데이터 삭제 후 재신청 허용
      if (currentEntry.status == 'rejected') {
        debugPrint(
            '$methodName: [재신청 감지] 반려(Rejected) 상태입니다. 기존 데이터 삭제 후 새 신청을 진행합니다.');

        // 1. 기존 데이터 삭제 (Repository 호출)
        await _repository.deleteEntryAndPhoto(currentEntry);

        // 삭제 완료 후, 이 조건문을 통과하여 아래의 새 신청 플로우로 진입합니다.
      } else {
        // pending, approved 등의 상태라면 에러 반환 (중복 참가 방지)
        debugPrint(
            '$methodName: [에러] 이미 이번 주차 콘테스트에 참가 신청을 하셨습니다. 상태: ${currentEntry.status}');
        throw Exception('이미 이번 주차 콘테스트에 참가 신청을 하셨습니다. 상태를 확인하세요.');
      }
    }

    state = const AsyncValue.loading();
    debugPrint('$methodName: [상태변경] 로딩 상태로 변경되었습니다.');

    try {
      // 3. 사진 업로드 및 URL 획득
      debugPrint(
          '$methodName: [요청] Cloud Storage 사진 업로드 시작 (UserID: ${user.uid}, FileSize: ${photo.lengthSync() / 1024} KB)');

      final photoUrls =
          await _repository.uploadPhoto(user.email, photo, user.region, snsId);

      debugPrint(
          '$methodName: [응답] Cloud Storage 업로드 완료. PhotoUrl: ${photoUrls['photoUrl']!}');

      // 4. Firestore에 참가 신청 데이터 저장 (regionCity는 UserModel의 지역을 따름)
      debugPrint(
          '$methodName: [요청] Firestore 참가 신청 데이터 저장 시작 (지역: ${user.region}, SNS ID: $snsId)');

      final newEntry = await _repository.saveEntry(
        userId: user.uid,
        regionCity: user.region,
        // 사용자의 현재 지역을 참가 지역으로 설정
        photoUrl: photoUrls['photoUrl']!,
        thumbnailUrl: photoUrls['thumbnailUrl']!,
        snsId: snsId,
        snsUrl: snsUrl,
      );

      debugPrint(
          '$methodName: [응답] Firestore 저장 완료. EntryID: ${newEntry.entryId}, Status: ${newEntry.status}');

      // 5. 상태 업데이트 (UI에 PENDING 상태 반영)
      state = AsyncValue.data(newEntry);
      debugPrint('$methodName: [성공] Notifier 상태 PENDING으로 업데이트 완료. 플로우 종료.');
    } catch (e, stack) {
      debugPrint('$methodName: [실패] 참가 신청 실패: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 8. 💡 [신규] 투표 비공개 전환 (approved -> private)
  Future<void> setEntryPrivate() async {
    final entry = state.value;
    if (entry == null || entry.status != 'approved') {
      throw Exception('현재 투표 활성화 상태가 아니므로 비공개로 전환할 수 없습니다.');
    }

    state = const AsyncValue.loading();

    try {
      // 1. DB 상태 변경 요청
      await _repository.setEntryStatus(entry.entryId, 'private');

      // 2. 상태 업데이트: Notifier 상태를 'private'으로 갱신
      state = AsyncValue.data(entry.copyWith(status: 'private'));

    } catch (e, stack) {
      // 오류 발생 시 이전 상태 유지하고 에러 반환
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// 9. 💡 [신규] 투표 공개 전환 (private -> approved)
  Future<void> setEntryPublic() async {
    final entry = state.value;
    if (entry == null || entry.status != 'private') {
      throw Exception('현재 비공개 상태가 아니므로 공개로 전환할 수 없습니다.');
    }

    state = const AsyncValue.loading();

    try {
      // 1. DB 상태 변경 요청
      await _repository.setEntryStatus(entry.entryId, 'approved');

      // 2. 상태 업데이트: Notifier 상태도 'approved'로 갱신
      state = AsyncValue.data(entry.copyWith(status: 'approved'));

    } catch (e, stack) {
      // 오류 발생 시 기존 상태 유지하고 에러 반환
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }



}
