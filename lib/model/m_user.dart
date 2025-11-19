import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 정보를 담는 데이터 모델 클래스.
///
/// Firebase Authentication 및 Firestore의 사용자 문서를 매핑합니다.
/// 앱 내에서 사용자의 인증 정보, 프로필, 상태 등을 관리합니다.
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

  /// 사용자 활동 지역 (시/구 단위)
  /// - 투표 권한 제한 및 지역 기반 랭킹에 사용됩니다.
  /// - 'NotSet': 초기 미설정 상태
  final String region;

  /// 지역 정보가 마지막으로 업데이트된 시각
  /// - 지역 변경 빈도를 제한하기 위해 사용됩니다 (예: 월 1회).
  final DateTime regionUpdatedAt;

  /// 소셜 로그인(Google, Apple 등) 여부
  final bool isSocialLogin;

  /// 관리자 권한 여부
  final bool isAdmin;

  /// 마지막으로 참가한 주차(Week)의 키값
  /// - 중복 참가를 방지하거나 참가 기록을 추적하는 데 사용됩니다.
  final String? lastEntryWeekKey;

  /// 기본 생성자
  ///
  /// 모든 필드를 초기화합니다. 불변 객체로 생성됩니다.
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

  /// 회원가입 직후 초기 사용자 객체를 생성하는 팩토리 생성자
  ///
  /// - [uid]: Firebase Auth UID
  /// - [email]: 사용자 이메일
  /// - [isSocialLogin]: 소셜 로그인 여부
  /// - [isAdmin]: 관리자 여부
  ///
  /// 성별과 지역은 'NotSet'으로 초기화되며,
  /// [regionUpdatedAt]은 바로 변경 가능하도록 1년 전으로 설정됩니다.
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

  /// 프로필 정보(성별 또는 지역)가 미설정 상태인지 확인합니다.
  ///
  /// true일 경우 사용자는 추가 정보를 입력해야 앱의 주요 기능을 사용할 수 있습니다.
  bool get isProfileIncomplete => gender == 'NotSet' || region == 'NotSet';

  /// Firestore 문서 데이터(Map)를 [UserModel] 객체로 변환합니다.
  ///
  /// - [map]: Firestore에서 가져온 데이터 맵
  /// - [regionUpdatedAt] 필드는 [Timestamp] 타입으로 처리되며,
  ///   데이터가 없거나 형식이 맞지 않을 경우 기본값(1년 전)으로 설정하여 안전성을 보장합니다.
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

  /// [UserModel] 객체를 Firestore에 저장하기 위한 Map 형태로 변환합니다.
  ///
  /// - [regionUpdatedAt]은 [DateTime]에서 Firestore의 [Timestamp]로 변환되어 저장됩니다.
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

  /// 현재 객체의 값을 유지하면서 특정 필드만 변경된 새로운 [UserModel] 객체를 생성합니다.
  ///
  /// 전달되지 않은 매개변수는 현재 객체의 값을 그대로 유지합니다.
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

  /// 객체의 문자열 표현을 반환합니다. (디버깅 용도)
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, gender: $gender, region: $region, fcmToken: $fcmToken, regionUpdatedAt: $regionUpdatedAt)';
  }
}
