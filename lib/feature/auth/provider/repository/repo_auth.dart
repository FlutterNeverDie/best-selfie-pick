import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:selfie_pick/core/data/collection.dart';
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
  // 💡 Functions 인스턴스 (커스텀 토큰 발행용)
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 💡 [유지] GoogleSignIn은 싱글톤 instance를 사용합니다.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthRepo({required this.ref});

  /// 2. 이메일 회원가입 로직
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
    required String region,
    required String gender,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'user-creation-failed', message: '사용자 계정 생성에 실패했습니다.');
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        nickname: nickname,
        gender: gender,
        channel: region,
        channelUpdatedAt: DateTime.now(),
        fcmToken: null,
      );

      await _firestore
          .collection(MyCollection.USERS)
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

      final uid = userCredential.user!.uid;
      final result = await _fetchUserModel(uid);

      if (result == null) {
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

  /// 4. 소셜 로그인 완료 후 데이터 저장 (회원가입 확정)
  Future<UserModel> completeSocialSignUp({
    required String uid,
    required String email,
    required String nickname,
    required String region,
    required String gender,
  }) async {
    try {
      final userModel = UserModel(
          uid: uid,
          email: email,
          nickname: nickname,
          gender: gender,
          channel: region,
          channelUpdatedAt: DateTime.now(),
          fcmToken: null,
          isSocialLogin: true);

      await _firestore
          .collection(MyCollection.USERS)
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) return null; // 사용자가 취소함

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final loadedUser = await _fetchUserModel(user.uid);

      if (loadedUser == null) {
        return UserModel.initial(
            uid: user.uid,
            email: user.email ?? 'social_user_${user.uid}@gmail.com',
            isSocialLogin: true);
      }

      return loadedUser;
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-in exception: ${e.code}');
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google 로그인 중 오류 발생: ${e.code}');
    } catch (e) {
      throw Exception('Google 로그인 중 알 수 없는 오류 발생: $e');
    }
  }

  // --- 10. 소셜 로그인 함수 (Kakao) ---
  Future<UserModel?> signInWithKakao() async {
    try {
      kakao.OAuthToken token;

      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return null;
          }
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final HttpsCallable callable = _functions.httpsCallable('kakaoCustomAuth');
      final result = await callable.call(<String, dynamic>{
        'token': token.accessToken,
      });

      final String firebaseCustomToken = result.data['firebaseToken'];

      final UserCredential userCredential =
      await _auth.signInWithCustomToken(firebaseCustomToken);
      final user = userCredential.user!;

      final loadedUser = await _fetchUserModel(user.uid);

      if (loadedUser == null) {
        return UserModel.initial(
            uid: user.uid,
            email: user.email ?? 'kakao_${user.uid.replaceAll(":", "")}@no.email',
            isSocialLogin: true);
      }

      return loadedUser;

    } catch (e) {
      if (e is PlatformException && e.code == 'CANCELED') {
        return null;
      }
      debugPrint('Kakao Login Error: $e');
      throw Exception('Kakao 로그인 실패: $e');
    }
  }

  // --- 11. 소셜 로그인 함수 (Naver) - 💡 [v2.0.0 대응 완료] ---
  Future<UserModel?> signInWithNaver() async {
    try {
      // 1. 네이버 로그인 시도 (NaverLoginResult 반환)
      final NaverLoginResult result = await FlutterNaverLogin.logIn();

      // 2. 상태 체크
      if (result.status == NaverLoginStatus.cancelledByUser) {
        return null; // 사용자 취소
      }

      if (result.status == NaverLoginStatus.error) {
        throw Exception('Naver Login SDK Error: ${result.errorMessage}');
      }

      // 3. 토큰 추출
      // 💡 NaverLoginResult.accessToken 필드는 NaverAccessToken 객체입니다.
      // 이 객체 안의 'accessToken' 필드가 실제 문자열 토큰입니다.
      final NaverAccessToken tokenObj = result.accessToken;
      final String tokenString = tokenObj.accessToken;

      if (tokenString.isEmpty || tokenString == 'no token') {
        throw Exception('Naver Access Token is invalid.');
      }

      // 4. Cloud Functions 호출 (네이버 토큰 -> 파이어베이스 커스텀 토큰)
      final HttpsCallable callable = _functions.httpsCallable('naverCustomAuth');
      final cfResult = await callable.call(<String, dynamic>{
        'token': tokenString, // 실제 토큰 문자열 전달
      });

      final String firebaseCustomToken = cfResult.data['firebaseToken'];

      // 5. Firebase 로그인
      final UserCredential userCredential =
      await _auth.signInWithCustomToken(firebaseCustomToken);
      final user = userCredential.user!;

      // 6. Firestore 조회
      final loadedUser = await _fetchUserModel(user.uid);

      if (loadedUser == null) {
        // 신규 유저
        return UserModel.initial(
            uid: user.uid,
            email: user.email ?? 'naver_${user.uid}@no.email',
            isSocialLogin: true);
      }

      return loadedUser;

    } catch (e) {
      print('Naver Login Error: $e');
      // 에러 발생 시 상태 초기화를 위해 로그아웃 시도
      try {
        await FlutterNaverLogin.logOut();
      } catch (_) {}
      throw Exception('Naver 로그인 실패: $e');
    }
  }

  // --- 9. 소셜 로그인 함수 (Apple) - 미구현 ---
  Future<UserModel?> signInWithApple() async {
    // TODO: 애플 로그인 구현 필요
    return null;
  }

  /// 4. 로그아웃 로직
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}

    try {
      // 카카오 토큰 삭제 (필요 시 주석 해제)
      // await kakao.UserApi.instance.logout();
    } catch (_) {}

    try {
      // 💡 [추가] 네이버 로그아웃
      await FlutterNaverLogin.logOut();
    } catch (_) {}

    await _auth.signOut();
  }

  /// 5. UserModel 데이터 한 번만 로드하는 헬퍼 함수
  Future<UserModel?> fetchUserModel(String uid) async {
    return _fetchUserModel(uid);
  }

  /// 6. 내부적으로 Firestore에서 UserModel을 가져오는 로직
  Future<UserModel?> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection(MyCollection.USERS).doc(uid).get();

    if (!doc.exists) {
      return null;
    }
    return UserModel.fromMap(doc.data()!);
  }

  /// 11. 이메일 중복 확인
  Future<EmailCheckStatus> checkIfEmailExists(String emailAddress) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection(MyCollection.USERS)
          .where('email', isEqualTo: emailAddress)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        return EmailCheckStatus.available;
      }

      final userData = result.docs.first.data() as Map<String, dynamic>;
      final isSocial = userData['isSocialLogin'] ?? false;

      if (isSocial) {
        return EmailCheckStatus.socialAccountFound;
      } else {
        return EmailCheckStatus.emailAlreadyInUse;
      }
    } catch (e) {
      print('Firestore lookup error: $e');
      throw Exception('Failed to check email existence in Firestore: $e');
    }
  }

  /// 12. 회원 탈퇴 로직
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('현재 인증된 사용자가 유효하지 않습니다.');
    }

    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection(MyCollection.USERS).doc(uid);
      transaction.delete(userRef);

      final entrySnapshot = await _firestore
          .collection(MyCollection.ENTRIES)
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in entrySnapshot.docs) {
        transaction.delete(doc.reference);
      }

      final votesSnapshot = await _firestore
          .collection(MyCollection.VOTES)
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in votesSnapshot.docs) {
        transaction.delete(doc.reference);
      }
    });

    await user.delete();
    await signOut();
  }

  Future<void> updateUserChannel(String uid, String newChannel) async {
    try {
      await _firestore.collection(MyCollection.USERS).doc(uid).update({
        'channel': newChannel,
        'channelUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('채널 정보를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }

  // =========================================================
  // 👥 다수 유저 정보 조회 (차단 목록 표시용)
  // =========================================================
  Future<List<UserModel>> fetchUsersBasicInfo(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final List<UserModel> users = [];

      for (var i = 0; i < userIds.length; i += 10) {
        final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        final chunk = userIds.sublist(i, end);

        final snapshot = await _firestore
            .collection(MyCollection.USERS)
            .where('uid', whereIn: chunk)
            .get();

        final chunkUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();

        users.addAll(chunkUsers);
      }

      return users;
    } catch (e) {
      print('Error fetching users info: $e');
      return [];
    }
  }

  // repo_auth.dart 에 추가될 로직
  Future<bool> checkIfNicknameExists(String nickname) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection(MyCollection.USERS)
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      return result.docs.isNotEmpty; // 존재하면 true (중복)
    } catch (e) {
      throw Exception('닉네임 중복 확인 중 오류 발생: $e');
    }
  }
}