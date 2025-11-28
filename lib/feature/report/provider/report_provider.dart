import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/report/model/m_report.dart';
import 'package:selfie_pick/feature/report/provider/repo_report.dart';

// Repository Provider
final reportRepoProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(FirebaseFirestore.instance);
});

// Notifier Provider
final reportProvider = NotifierProvider<ReportNotifier, void>(() {
  return ReportNotifier();
});

class ReportNotifier extends Notifier<void> {
  late final ReportRepository _repository;

  @override
  void build() {
    _repository = ref.read(reportRepoProvider);
  }

  /// 신고하기 로직 (신고 후 자동 차단 포함)
  Future<void> reportEntry({
    required String reporterUid,
    required String targetEntryId,
    required String targetUserUid,
    required String reason,
    String description = '',
    // 💡 차단에 필요한 추가 정보 (스냅샷용)
    required String snsId,
    required String channel,
    required String weekKey,
  }) async {
    try {
      // 1. 신고 접수 (DB)
      final report = ReportModel.create(
        reportId: '', // Repo에서 생성
        reporterUid: reporterUid,
        targetEntryId: targetEntryId,
        targetUserUid: targetUserUid,
        reason: reason,
        description: description,
      );

      await _repository.submitReport(report);

      // 2. 🎯 신고 대상 자동 차단 실행
      await blockUser(
        targetUserId: targetUserUid,
        snsId: snsId,
        channel: channel,
        weekKey: weekKey,
      );

    } catch (e) {
      rethrow;
    }
  }

  /// 차단하기 로직 (핵심: 로컬 상태 즉시 갱신)
  Future<void> blockUser({
    required String targetUserId,
    required String snsId,    // 💡 추가
    required String channel,  // 💡 추가
    required String weekKey,  // 💡 추가
  }) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    if (currentUser.blockedUserIds.contains(targetUserId)) return;

    try {
      // 1. DB 업데이트 (상세 정보 전달)
      await _repository.blockUser(
        currentUserId: currentUser.uid,
        targetUserId: targetUserId,
        snsId: snsId,
        channel: channel,
        weekKey: weekKey,
      );

      // 2. 💡 로컬 AuthState의 blockedUserIds 즉시 갱신
      final authNotifier = ref.read(authProvider.notifier);

      final updatedBlockedList = List<String>.from(currentUser.blockedUserIds)
        ..add(targetUserId);

      final updatedUser = currentUser.copyWith(blockedUserIds: updatedBlockedList);

      // AuthNotifier 업데이트 -> AuthState 변경 -> 이를 구독하는 Vote/Champion Provider 자동 재빌드
      authNotifier.updateUserLocally(updatedUser);

    } catch (e) {
      debugPrint('Error blockUser(차단 - Notifier) user: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // 1. DB 업데이트 (차단 해제)
      await _repository.unblockUser(currentUser.uid, targetUserId);

      // 2. 로컬 상태 즉시 갱신 (리스트에서 제거)
      final authNotifier = ref.read(authProvider.notifier);

      final updatedBlockedList = List<String>.from(currentUser.blockedUserIds)
        ..remove(targetUserId);

      final updatedUser = currentUser.copyWith(blockedUserIds: updatedBlockedList);

      authNotifier.updateUserLocally(updatedUser);

    } catch (e) {
      rethrow;
    }
  }
}