import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // I. 인증 및 시스템 필수 필드
  final String uid; // Firebase Authentication 고유 식별자
  final String email; // 로그인 이메일
  final String? fcmToken; // 푸시 알림 발송을 위한 FCM 토큰

  // II. 핵심 앱 로직 필수 필드
  final String gender; // 'Female' 또는 'Male'. 남자는 투표 및 참가 불가.
  final String region; // 시/구 단위 지역 (투표 권한 제한용)
  final DateTime regionUpdatedAt; // 지역 변경 제한 규칙 강제용 타임스탬프

  final bool isSocialLogin;
  final bool isAdmin;

  final String? lastEntryWeekKey;

  // ----------------------------------------------------
  // 1. 생성자 (Constructor)
  // ----------------------------------------------------
  const UserModel({
    required this.uid,
    required this.email,
    this.fcmToken,
    required this.gender,
    required this.region,
    required this.regionUpdatedAt,
    this.isSocialLogin = false,
    this.isAdmin = false,
    this.lastEntryWeekKey,
  });

  // ----------------------------------------------------
  // 2. 초기 사용자 생성을 위한 팩토리 (Initial Factory)
  // ----------------------------------------------------
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
      region: 'NotSet',
      // 초기에는 변경 가능하도록 1년 전으로 설정 (월 1회 제한을 바로 통과하기 위함)
      regionUpdatedAt: DateTime.now().subtract(const Duration(days: 365)),
      isSocialLogin: isSocialLogin,
      isAdmin: isAdmin,
      lastEntryWeekKey: null,
    );
  }

  bool get isProfileIncomplete => gender == 'NotSet' || region == 'NotSet';

  // ----------------------------------------------------
  // 3. Firestore 데이터 역직렬화 (fromMap Factory)
  // ----------------------------------------------------
  // 필드명은 소문자 카멜 케이스를 사용합니다.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Firestore Timestamp를 DateTime으로 변환
    final regionTimestamp = map['regionUpdatedAt'];
    DateTime regionDate;

    if (regionTimestamp is Timestamp) {
      regionDate = regionTimestamp.toDate();
    } else {
      // 안전 장치: 만약 Timestamp가 아닌 다른 형태이거나 null인 경우 기본값 설정
      regionDate = DateTime.now().subtract(const Duration(days: 365));
    }

    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      fcmToken: map['fcmToken'] as String?,
      gender: map['gender'] as String,
      region: map['region'] as String,
      regionUpdatedAt: regionDate,
      isSocialLogin: map['isSocialLogin'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      lastEntryWeekKey: map['lastEntryWeekKey'] as String?,
    );
  }

  // ----------------------------------------------------
  // 4. Firestore 데이터 직렬화 (toMap Method)
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fcmToken': fcmToken,
      'gender': gender,
      'region': region,
      // DateTime을 Firestore Timestamp로 변환하여 저장
      'regionUpdatedAt': Timestamp.fromDate(regionUpdatedAt),
      'isSocialLogin': isSocialLogin,
      'isAdmin': isAdmin,
      'lastEntryWeekKey': lastEntryWeekKey,
    };
  }

  // ----------------------------------------------------
  // 5. 복사 메서드 (copyWith)
  // ----------------------------------------------------
  UserModel copyWith({
    String? uid,
    String? email,
    String? fcmToken,
    String? gender,
    String? region,
    DateTime? regionUpdatedAt,
    bool? isSocialLogin,
    String? lastEntryWeekKey,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      gender: gender ?? this.gender,
      region: region ?? this.region,
      regionUpdatedAt: regionUpdatedAt ?? this.regionUpdatedAt,
      isSocialLogin: isSocialLogin ?? this.isSocialLogin,
      isAdmin: isAdmin,
      lastEntryWeekKey: lastEntryWeekKey ?? this.lastEntryWeekKey,
    );
  }

  // ----------------------------------------------------
  // 6. 디버깅용 toString
  // ----------------------------------------------------
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, gender: $gender, region: $region, fcmToken: $fcmToken, regionUpdatedAt: $regionUpdatedAt)';
  }
}