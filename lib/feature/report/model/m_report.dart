import 'package:cloud_firestore/cloud_firestore.dart';

/// 신고 정보를 담는 데이터 모델
class ReportModel {
  /// 신고 문서 ID (Auto ID)
  final String reportId;

  /// 신고자 UID
  final String reporterUid;

  /// 신고 대상 게시물(사진) ID
  final String targetEntryId;

  /// 신고 대상 유저 UID (게시물 작성자)
  final String targetUserUid;

  /// 신고 사유 (예: "spam", "abusive", "adult", "other")
  final String reason;

  /// 신고 상세 내용 (선택 사항)
  final String description;

  /// 신고 일시
  final DateTime createdAt;

  /// 처리 상태 (예: 'pending'(대기), 'reviewed'(검토완료), 'resolved'(조치완료))
  final String status;

  const ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.targetEntryId,
    required this.targetUserUid,
    required this.reason,
    this.description = '',
    required this.createdAt,
    this.status = 'pending',
  });

  /// 초기 생성용 팩토리
  factory ReportModel.create({
    required String reportId,
    required String reporterUid,
    required String targetEntryId,
    required String targetUserUid,
    required String reason,
    String description = '',
  }) {
    return ReportModel(
      reportId: reportId,
      reporterUid: reporterUid,
      targetEntryId: targetEntryId,
      targetUserUid: targetUserUid,
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
      status: 'pending',
    );
  }

  /// Firestore Map -> ReportModel
  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      reportId: docId,
      reporterUid: map['reporterUid'] as String? ?? '',
      targetEntryId: map['targetEntryId'] as String? ?? '',
      targetUserUid: map['targetUserUid'] as String? ?? '',
      reason: map['reason'] as String? ?? 'other',
      description: map['description'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
    );
  }

  /// ReportModel -> Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'targetEntryId': targetEntryId,
      'targetUserUid': targetUserUid,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  /// copyWith
  ReportModel copyWith({
    String? reportId,
    String? reporterUid,
    String? targetEntryId,
    String? targetUserUid,
    String? reason,
    String? description,
    DateTime? createdAt,
    String? status,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      reporterUid: reporterUid ?? this.reporterUid,
      targetEntryId: targetEntryId ?? this.targetEntryId,
      targetUserUid: targetUserUid ?? this.targetUserUid,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $reportId, reporter: $reporterUid, targetEntry: $targetEntryId, reason: $reason, status: $status)';
  }
}