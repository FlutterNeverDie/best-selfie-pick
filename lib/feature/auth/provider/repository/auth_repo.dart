import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:selfie_pick/model/m_user.dart';

enum EmailCheckStatus {
  available, // 사용 가능
  emailAlreadyInUse, // 이메일/비밀번호 가입 계정 중복
  socialAccountFound, // 소셜 로그인 계정 발견
}

// 1. AuthRepo Provider 정의
final authRepoProvider = Provider.autoDispose((ref) {
  return AuthRepo(ref: ref);
}, name: 'authRepoProvider');

class AuthRepo {
  final Ref ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🎯 GoogleSignIn 싱글톤 인스턴스를 필드로 참조 (정상 코드)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthRepo({required this.ref});

  static const String _usersCollection = 'users';

  /// 2. 이메일 회원가입 로직 (Firebase Auth & Firestore 데이터 저장)
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String region,
    required String gender,
  }) async {
    try {
      // 1. Firebase Auth 사용자 생성
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'user-creation-failed', message: '사용자 계정 생성에 실패했습니다.');
      }

      // 2. UserModel 생성 및 Firestore 저장 (필수 정보 포함)
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        gender: gender,
        region: region,
        regionUpdatedAt: DateTime.now(),
        fcmToken: null, // 초기 가입 시에는 null
      );

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('회원가입 중 알 수 없는 오류 발생: $e');
    }
  }

  /// 3. 이메일 로그인 로직
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('userCredential : $userCredential');

      final uid = userCredential.user!.uid;
      // 소셜 로그인과 달리 이메일 가입은 signUp 단계에서 UserModel이 생성되므로,
      // 여기서는 Firestore에서 로드만 시도합니다.
      final result = await _fetchUserModel(uid);

      if (result == null) {
        // Auth에는 있지만 Firestore에 없는 경우 (보안 규칙 문제나 데이터 누락)
        throw FirebaseAuthException(
            code: 'user-data-missing', message: '사용자 데이터를 찾을 수 없습니다.');
      } else {
        return result;
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

// 🎯 신규 추가: 소셜 로그인 완료 후 필수 정보를 Firestore에 저장하는 함수
  Future<UserModel> completeSocialSignUp({
    required String uid,
    required String email,
    required String region,
    required String gender,
  }) async {
    try {
      // 1. UserModel 생성 (완전한 데이터)
      final userModel = UserModel(
          uid: uid,
          email: email,
          gender: gender,
          region: region,
          regionUpdatedAt: DateTime.now(),
          fcmToken: null,
          isSocialLogin: true);

      // 2. Firestore 저장 (최종 문서 생성)
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userModel.toMap());

      return userModel;
    } catch (e) {
      throw Exception('소셜 회원가입 완료 중 오류 발생: $e');
    }
  }

// --- 8. 소셜 로그인 함수 (Google) ---
  Future<UserModel?> signInWithGoogle() async {
    try {
      // 🎯 수정 완료: authenticate() 메서드 사용 (v7+ 버전)
      // authenticate()는 성공하면 GoogleSignInAccount를 반환, 실패하면 null (또는 예외)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final loadedUser = await _fetchUserModel(user.uid);

      if (loadedUser == null) {
        // 🎯 핵심 변경: Firestore에 데이터가 없는 경우,
        // Firebase Auth 정보만 포함한 '프로필 불완전(NotSet)' 상태의 UserModel을 반환합니다.
        return UserModel.initial(
            uid: user.uid,
            email: user.email ?? 'social_user_${user.uid}@gmail.com');
      }

      return loadedUser;
    } on FirebaseAuthException catch (e) {
      // Firebase Auth 관련 오류 처리
      throw Exception('Google 로그인 중 오류 발생: ${e.code}');
    } catch (e) {
      // 기타 오류 (SDK 관련 등) 처리
      throw Exception('Google 로그인 중 알 수 없는 오류 발생: $e');
    }
  }

// --- 9. 소셜 로그인 함수 (Apple) ---
  Future<UserModel?> signInWithApple() async {
    // 구현 예정
    return null;
  }

// --- 10. 소셜 로그인 함수 (Kakao) ---
  Future<UserModel?> signInWithKakao() async {
    // 구현 예정
    return null;
  }

  /// 4. 로그아웃 로직 (Firebase Auth + 소셜 SDK 세션 종료)
  Future<void> signOut() async {
    // 1. Google Sign-In 세션 종료 (만약 Google로 로그인했었다면)
    try {
      // 🎯 _googleSignIn 필드를 사용하여 signOut() 메서드 호출
      await _googleSignIn.disconnect();
    } catch (_) {
      // Google Sign-in으로 로그인하지 않았을 경우 무시
    }

    // 2. Kakao SDK 세션 종료 (만약 Kakao로 로그인했었다면)
    try {
      // 카카오 토큰이 있으면 로그아웃 시도
      // await kakao.UserApi.instance.logout();
    } catch (_) {
      // 카카오 로그인이 아니거나 토큰이 없으면 무시
    }

    // 3. Firebase Authentication 세션 종료 (필수)
    await _auth.signOut();
  }

  /// 5. UserModel 데이터 한 번만 로드하는 헬퍼 함수
  Future<UserModel?> fetchUserModel(String uid) async {
    return _fetchUserModel(uid);
  }

  /// 6. 내부적으로 Firestore에서 UserModel을 가져오는 로직 (공통 사용)
  Future<UserModel?> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();

    debugPrint('doc ${doc}');

    if (!doc.exists) {
      // Firestore 데이터가 없으면 Firebase Auth는 있지만 앱 데이터가 없는 경우
      return null;
    }

    final UserModel result = UserModel.fromMap(doc.data()!);

    print('result : $result');

    return result;
  }

  /// 11. 특정 이메일 주소로 등록된 인증 방법이 있는지 확인 (중복 확인)

// AuthRepo 클래스 내부의 checkIfEmailExists 메서드 수정
  Future<EmailCheckStatus> checkIfEmailExists(String emailAddress) async {
    try {
      // 1. Firestore에서 이메일 일치 문서 조회
      final QuerySnapshot result = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: emailAddress)
          .limit(1)
          .get();

      // 2. 문서가 없으면 사용 가능
      if (result.docs.isEmpty) {
        return EmailCheckStatus.available;
      }

      // 3. 문서가 발견된 경우, isSocialLogin 필드 확인
      final userData = result.docs.first.data() as Map<String, dynamic>;
      // Firestore에 해당 필드가 없으면 기본적으로 false로 간주
      final isSocial = userData['isSocialLogin'] ?? false;

      if (isSocial) {
        return EmailCheckStatus.socialAccountFound;
      } else {
        return EmailCheckStatus.emailAlreadyInUse;
      }
    } catch (e) {
      // 조회 중 오류 발생 (권한/네트워크 등)
      print('Firestore lookup error: $e');
      throw Exception('Failed to check email existence in Firestore: $e');
    }
  }
}
