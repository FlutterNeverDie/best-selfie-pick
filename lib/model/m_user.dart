import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 정보를 담는 데이터 모델 클래스.
///
/// Firebase Authentication 및 Firestore의 사용자 문서를 매핑합니다.
/// 앱 내에서 사용자의 인증 정보, 프로필, 상태, **리워드(뱃지, 포인트)** 등을 관리합니다.
class UserModel {
  // ====================================================
  // I. 인증 및 시스템 필수 필드
  // ====================================================

  /// Firebase Authentication에서 발급된 고유 식별자 (UID)
  final String uid;

  /// 사용자 로그인 이메일 주소
  final String email;

  /// 푸시 알림 발송을 위한 FCM(Firebase Cloud Messaging) 토큰
  /// - null일 경우 알림을 받을 수 없습니다.
  final String? fcmToken;

  // ====================================================
  // II. 핵심 앱 로직 필수 필드
  // ====================================================

  /// 사용자 성별
  /// - 'Female': 여성 (투표 및 참가 가능)
  /// - 'Male': 남성 (투표 및 참가 불가, 관전만 가능할 수 있음)
  /// - 'NotSet': 초기 미설정 상태
  final String gender;

  /// 사용자 활동 채널
  /// - 투표 권한 제한 및 채널 기반 랭킹에 사용됩니다.
  /// - 'NotSet': 초기 미설정 상태
  final String channel;

  ///  채널가 마지막으로 업데이트된 시각
  /// - 채널 변경 빈도를 확인
  final DateTime channelUpdatedAt;

  /// 소셜 로그인(Google, Apple 등) 여부
  final bool isSocialLogin;

  /// 관리자 권한 여부
  final bool isAdmin;

  /// 마지막으로 참가한 주차(Week)의 키값
  /// - 중복 참가를 방지하거나 참가 기록을 추적하는 데 사용됩니다.
  final String? lastEntryWeekKey;

  // ====================================================
  // III. 🏆 리워드 및 활동 데이터 (신규 추가)
  // ====================================================

  /// 명예 점수 (Honor Score)
  /// - 우승, 투표 참여 등으로 획득하는 누적 명예 점수
  final int honorScore;

  /// 보유 포인트 (Points)
  /// - 아이템 구매 등에 사용 가능한 재화
  final int points;

  /// 골드 뱃지 획득 횟수 (1위)
  final int badgeGold;

  /// 실버 뱃지 획득 횟수 (2위)
  final int badgeSilver;

  /// 브론즈 뱃지 획득 횟수 (3위)
  final int badgeBronze;

  /// 기본 생성자
  ///
  /// 모든 필드를 초기화합니다. 불변 객체로 생성됩니다.
  const UserModel({
    required this.uid,
    required this.email,
    this.fcmToken,
    required this.gender,
    required this.channel,
    required this.channelUpdatedAt,
    this.isSocialLogin = false,
    this.isAdmin = false,
    this.lastEntryWeekKey,
    // 리워드 필드 초기화 (기본값 0)
    this.honorScore = 0,
    this.points = 0,
    this.badgeGold = 0,
    this.badgeSilver = 0,
    this.badgeBronze = 0,
  });

  /// 회원가입 직후 초기 사용자 객체를 생성하는 팩토리 생성자
  ///
  /// - [uid]: Firebase Auth UID
  /// - [email]: 사용자 이메일
  /// - [isSocialLogin]: 소셜 로그인 여부
  /// - [isAdmin]: 관리자 여부
  ///
  /// 성별과 채널은 'NotSet'으로 초기화되며,
  /// 리워드 관련 필드는 모두 0으로 시작합니다.
  factory UserModel.initial({
    required String uid,
    required String email,
    bool isSocialLogin = false,
    bool isAdmin = false,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fcmToken: null,
      gender: 'NotSet',
      channel: 'NotSet',
      // 초기에는 변경 가능하도록 1년 전으로 설정 (월 1회 제한을 바로 통과하기 위함)
      channelUpdatedAt: DateTime.now().subtract(const Duration(days: 365)),
      isSocialLogin: isSocialLogin,
      isAdmin: isAdmin,
      lastEntryWeekKey: null,
      honorScore: 0,
      points: 0,
      badgeGold: 0,
      badgeSilver: 0,
      badgeBronze: 0,
    );
  }

  /// 프로필 정보(성별 또는 채널)가 미설정 상태인지 확인합니다.
  ///
  /// true일 경우 사용자는 추가 정보를 입력해야 앱의 주요 기능을 사용할 수 있습니다.
  bool get isProfileIncomplete => gender == 'NotSet' || channel == 'NotSet';

  /// Firestore 문서 데이터(Map)를 [UserModel] 객체로 변환합니다.
  ///
  /// - [map]: Firestore에서 가져온 데이터 맵
  /// - 기존 사용자의 경우 리워드 필드가 없을 수 있으므로 `?? 0`으로 안전하게 처리합니다.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Firestore Timestamp를 DateTime으로 변환
    final channelTimestamp = map['channelUpdatedAt'];
    DateTime channelDate;

    if (channelTimestamp is Timestamp) {
      channelDate = channelTimestamp.toDate();
    } else {
      // 안전 장치: 만약 Timestamp가 아닌 다른 형태이거나 null인 경우 기본값 설정
      channelDate = DateTime.now().subtract(const Duration(days: 365));
    }

    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      fcmToken: map['fcmToken'] as String?,
      gender: map['gender'] as String,
      channel: map['channel'] as String,
      channelUpdatedAt: channelDate,
      isSocialLogin: map['isSocialLogin'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      lastEntryWeekKey: map['lastEntryWeekKey'] as String?,
      // 💡 신규 필드 매핑 (기존 데이터가 없을 경우 0 처리)
      honorScore: (map['honorScore'] as num?)?.toInt() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      badgeGold: (map['badgeGold'] as num?)?.toInt() ?? 0,
      badgeSilver: (map['badgeSilver'] as num?)?.toInt() ?? 0,
      badgeBronze: (map['badgeBronze'] as num?)?.toInt() ?? 0,
    );
  }

  /// [UserModel] 객체를 Firestore에 저장하기 위한 Map 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fcmToken': fcmToken,
      'gender': gender,
      'channel': channel,
      'channelUpdatedAt': Timestamp.fromDate(channelUpdatedAt),
      'isSocialLogin': isSocialLogin,
      'isAdmin': isAdmin,
      'lastEntryWeekKey': lastEntryWeekKey,
      // 💡 신규 필드 저장
      'honorScore': honorScore,
      'points': points,
      'badgeGold': badgeGold,
      'badgeSilver': badgeSilver,
      'badgeBronze': badgeBronze,
    };
  }

  /// 현재 객체의 값을 유지하면서 특정 필드만 변경된 새로운 [UserModel] 객체를 생성합니다.
  UserModel copyWith({
    String? uid,
    String? email,
    String? fcmToken,
    String? gender,
    String? channel,
    DateTime? channelUpdatedAt,
    bool? isSocialLogin,
    String? lastEntryWeekKey,
    int? honorScore,
    int? points,
    int? badgeGold,
    int? badgeSilver,
    int? badgeBronze,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      gender: gender ?? this.gender,
      channel: channel ?? this.channel,
      channelUpdatedAt: channelUpdatedAt ?? this.channelUpdatedAt,
      isSocialLogin: isSocialLogin ?? this.isSocialLogin,
      isAdmin: isAdmin,
      lastEntryWeekKey: lastEntryWeekKey ?? this.lastEntryWeekKey,
      honorScore: honorScore ?? this.honorScore,
      points: points ?? this.points,
      badgeGold: badgeGold ?? this.badgeGold,
      badgeSilver: badgeSilver ?? this.badgeSilver,
      badgeBronze: badgeBronze ?? this.badgeBronze,
    );
  }

  /// 객체의 문자열 표현을 반환합니다. (디버깅 용도)
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, gender: $gender, channel: $channel, '
        'honor: $honorScore, points: $points, badges: G:$badgeGold/S:$badgeSilver/B:$badgeBronze)';
  }
}