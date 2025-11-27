class ChampionModel {
  final String uid;
  final String snsId;
  final String snsUrl;
  final String email;
  final String entryId;
  final String imageUrl;
  final int totalScore;
  final String regionCity;
  final int rank;
  final String weekKey; // 부모 문서에서 주입받는 필드

  const ChampionModel({
    required this.uid,
    required this.snsId,
    required this.snsUrl,
    required this.email,
    required this.entryId,
    required this.imageUrl,
    required this.totalScore,
    required this.regionCity,
    required this.rank,
    required this.weekKey,
  });

  // Cloud Functions가 생성한 데이터 구조(rankN 객체)로부터 변환
  factory ChampionModel.fromJson(Map<String, dynamic> json, String weekKey) {
    return ChampionModel(
      uid: json['uid'] as String? ?? '',
      snsId: json['snsId'] as String? ?? '',
      snsUrl: json['snsUrl'] as String? ?? '',
      email: json['email'] as String? ?? '',
      entryId: json['entryId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      regionCity: json['regionCity'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      weekKey: weekKey,
    );
  }

  @override
  String toString() {
    return 'ChampionModel(rank: $rank, uid: $uid, region: $regionCity, score: $totalScore)';
  }
}
