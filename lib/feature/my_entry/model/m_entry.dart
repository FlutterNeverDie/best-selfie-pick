import 'package:cloud_firestore/cloud_firestore.dart';

// Contest Entry Model (불변성 유지)
class EntryModel {
  // DB 필드
  final String entryId;
  final String userId;
  final String channel; // 참가 채널
  final String weekKey; // 참가 회차
  final String thumbnailUrl;
  final String snsId;
  final String snsUrl;
  final DateTime createdAt;

  // 상태 및 결과
  final String status; // pending, rejected, approved, completed, private
  final int goldVotes;
  final int silverVotes;
  final int bronzeVotes;
  final int totalScore;

  const EntryModel({
    required this.entryId,
    required this.userId,
    required this.channel,
    required this.weekKey,
    required this.thumbnailUrl,
    required this.snsId,
    this.snsUrl = '',
    required this.createdAt,
    this.status = 'pending',
    this.goldVotes = 0,
    this.silverVotes = 0,
    this.bronzeVotes = 0,
    this.totalScore = 0,
  });

  // Firestore Map에서 EntryModel로 변환
  factory EntryModel.fromMap(Map<String, dynamic> map, String docId) {
    return EntryModel(
      entryId: docId,
      userId: map['userId'] as String? ?? '',
      channel: map['channel'] as String? ?? '',
      weekKey: map['weekKey'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      snsId: map['snsId'] as String? ?? '',
      snsUrl: map['snsUrl'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
      goldVotes: (map['goldVotes'] as num?)?.toInt() ?? 0,
      silverVotes: (map['silverVotes'] as num?)?.toInt() ?? 0,
      bronzeVotes: (map['bronzeVotes'] as num?)?.toInt() ?? 0,
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
    );
  }

  // EntryModel에서 Firestore Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'channel': channel,
      'weekKey': weekKey,
      'thumbnailUrl': thumbnailUrl,
      'snsId': snsId,
      'snsUrl': snsUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'goldVotes': goldVotes,
      'silverVotes': silverVotes,
      'bronzeVotes': bronzeVotes,
      'totalScore': totalScore,
    };
  }

  // 불변성을 위한 copyWith 수동 구현
  EntryModel copyWith({
    String? entryId,
    String? userId,
    String? channel,
    String? weekKey,
    String? photoUrl,
    String? thumbnailUrl,
    String? snsId,
    String? snsUrl,
    DateTime? createdAt,
    String? status,
    int? goldVotes,
    int? silverVotes,
    int? bronzeVotes,
    int? totalScore,
  }) {
    return EntryModel(
      entryId: entryId ?? this.entryId,
      userId: userId ?? this.userId,
      channel: channel ?? this.channel,
      weekKey: weekKey ?? this.weekKey,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      snsId: snsId ?? this.snsId,
      snsUrl: snsUrl ?? this.snsUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      goldVotes: goldVotes ?? this.goldVotes,
      silverVotes: silverVotes ?? this.silverVotes,
      bronzeVotes: bronzeVotes ?? this.bronzeVotes,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  @override
  String toString() {
    return 'EntryModel(entryId: $entryId, userId: $userId, channel: $channel, weekKey: $weekKey,  thumbnailUrl: $thumbnailUrl, snsId: $snsId, createdAt: $createdAt, status: $status, goldVotes: $goldVotes, silverVotes: $silverVotes, bronzeVotes: $bronzeVotes, totalScore: $totalScore)';
  }
}
