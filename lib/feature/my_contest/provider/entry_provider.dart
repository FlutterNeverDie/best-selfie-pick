import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/my_contest/provider/repo/entry_repo.dart';

import '../../../shared/provider/contest_status/contest_status_provider.dart';
import '../../auth/provider/auth_notifier.dart';
import '../model/m_entry.dart';

// EntryNotifier의 상태는 AsyncValue<EntryModel?> 형태입니다.
// data: null -> 미참가 (Not Entered)
final entryProvider = AsyncNotifierProvider<EntryNotifier, EntryModel?>(
      () => EntryNotifier(),
);

class EntryNotifier extends AsyncNotifier<EntryModel?> {
  late final EntryRepository _repository;

  @override
  Future<EntryModel?> build() async {
    // 1. 필요한 Repository 및 Notifier 상태를 주입 및 감시
    _repository = ref.read(entryRepoProvider);

    // 💡 세 가지 필수 조건 감시: UID, WeekKey, Region
    final authState = ref.watch(authProvider);
    final contestStatus = ref.watch(contestStatusProvider);
    final userModel = ref.watch(authProvider).user; // UserNotifier에서 UserModel 로드 가정

    // 2. 인증/상태 로딩 및 필수 데이터 확인
    if (authState.isLoading || authState.user == null || contestStatus.currentWeekKey == null || userModel == null) {
      return null;
    }

    final userId = authState.user!.uid;
    final currentWeekKey = contestStatus.currentWeekKey!;
    final currentUserRegion = userModel.region; // 현재 사용자의 설정 지역

    // 3. 현재 주차, 현재 지역, 현재 사용자의 참가 내역 조회 시도
    // 💡 V3.0 핵심: 이 쿼리가 null을 반환하면 미참가로 간주됨 (지난 회차/다른 지역 기록 자동 제외)
    try {
      final currentEntry = await _repository.fetchCurrentEntry(
        userId,
        currentWeekKey,
        currentUserRegion, // 현재 유저의 설정 지역으로 조회 (지역 종속성)
      );

      // 💡 상태 분기 로직: 'approved' → 'voting_active' 즉시 전환 (V3.0 즉시 참여 로직)
      // 관리자 승인 완료 직후, 클라이언트가 바로 투표 가능 상태로 전환
      if (currentEntry != null && currentEntry.status == 'approved') {
        await _repository.updateEntryStatusAfterApproval(
            currentEntry.entryId,
            currentWeekKey // 현재 회차로 weekKey를 최종 확정
        );
        // 상태 갱신된 모델을 수동으로 반환하여 UI에 반영
        return currentEntry.copyWith(status: 'voting_active', weekKey: currentWeekKey);
      }

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
  }) async {
    final user = ref.read(authProvider).user; // UserModel 로드
    final currentEntry = state.value;

    if (user == null || user.region == 'NotSet') {
      throw Exception('로그인 정보 및 지역 설정이 유효하지 않습니다. 마이페이지를 확인해주세요.');
    }

    // 💡 V3.0: 현재 회차, 현재 지역에 이미 참가 중인지 확인 (단일 참가 강제)
    if (currentEntry != null && currentEntry.status != 'completed') {
      throw Exception('이미 이번 주차 콘테스트에 참가 신청을 하셨습니다. 상태를 확인하세요.');
    }

    state = const AsyncValue.loading();

    try {
      // 3. 사진 업로드 및 URL 획득
      final photoUrls = await _repository.uploadPhoto(user.uid, photo);

      // 4. Firestore에 참가 신청 데이터 저장 (regionCity는 UserModel의 지역을 따름)
      final newEntry = await _repository.saveEntry(
        userId: user.uid,
        regionCity: user.region, // 사용자의 현재 지역을 참가 지역으로 설정
        photoUrl: photoUrls['photoUrl']!,
        thumbnailUrl: photoUrls['thumbnailUrl']!,
        snsId: snsId,
      );

      // 5. 상태 업데이트 (UI에 PENDING 상태 반영)
      state = AsyncValue.data(newEntry);
    } catch (e, stack) {
      debugPrint('참가 신청 실패: $e');
      // 오류 시 이전 상태 유지 후 에러 메시지 전달 (copyWithPrevious)
      state =  AsyncValue.error(e, stack);
      throw e;
    }
  }

  // 득표 스트림 제공 (MyEntryScreen의 voting_active 뷰에서 사용)
  Stream<EntryModel> get voteStream {
    final entry = state.value;
    if (entry == null || entry.status != 'voting_active') {
      // 투표 진행 중이 아니면 빈 스트림 반환
      return const Stream.empty();
    }
    // Repository에서 실시간 득표 스트림 가져옴
    return _repository.streamVotes(entry.entryId);
  }
}