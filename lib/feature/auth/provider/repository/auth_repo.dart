import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthRepo({required this.ref});

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
        channel: region,
        channelUpdatedAt: DateTime.now(),
        fcmToken: null, // 초기 가입 시에는 null
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
          channel: region,
          channelUpdatedAt: DateTime.now(),
          fcmToken: null,
          isSocialLogin: true);

      // 2. Firestore 저장 (최종 문서 생성)
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
      // 🎯 수정 완료: authenticate() 메서드 사용 (v7+ 버전)
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) return null; // 사용자가 취소함

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
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
            email: user.email ?? 'social_user_${user.uid}@gmail.com',
            isSocialLogin: true);
      }

      return loadedUser;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google 로그인 중 오류 발생: ${e.code}');
    } catch (e) {
      throw Exception('Google 로그인 중 알 수 없는 오류 발생: $e');
    }
  }

  // --- 9. 소셜 로그인 함수 (Apple) - 미구현 상태 유지 ---
  Future<UserModel?> signInWithApple() async {
    // TODO: 애플 로그인 구현 필요
    return null;
  }

  // --- 10. 소셜 로그인 함수 (Kakao) - 미구현 상태 유지 ---
  Future<UserModel?> signInWithKakao() async {
    // TODO: 카카오 로그인 구현 필요
    return null;
  }

  /// 4. 로그아웃 로직 (Firebase Auth + 소셜 SDK 세션 종료)
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}

    // 카카오 로그아웃 로직 (추후 구현 시 주석 해제)
    // try { await kakao.UserApi.instance.logout(); } catch (_) {}

    await _auth.signOut();
  }

  /// 5. UserModel 데이터 한 번만 로드하는 헬퍼 함수
  Future<UserModel?> fetchUserModel(String uid) async {
    return _fetchUserModel(uid);
  }

  /// 6. 내부적으로 Firestore에서 UserModel을 가져오는 로직 (공통 사용)
  Future<UserModel?> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection(MyCollection.USERS).doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  /// 11. 특정 이메일 주소로 등록된 인증 방법이 있는지 확인 (중복 확인)
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

  /// 12. 회원 탈퇴 로직 (계정 삭제 및 DB 데이터 삭제)
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('현재 인증된 사용자가 유효하지 않습니다.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Firestore에서 UserModel 문서 삭제
      final userRef = _firestore.collection(MyCollection.USERS).doc(uid);
      transaction.delete(userRef);

      // 2. contest_entries (본인의 참가 기록) 삭제
      final entrySnapshot = await _firestore
          .collection(MyCollection.ENTRIES)
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in entrySnapshot.docs) {
        transaction.delete(doc.reference);
      }

      // 3. votes (본인의 투표 기록) 삭제
      final votesSnapshot = await _firestore
          .collection(MyCollection.VOTES)
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in votesSnapshot.docs) {
        transaction.delete(doc.reference);
      }
    });

    // 4. Firebase Auth 계정 삭제
    await user.delete();

    // 5. 소셜 SDK 세션 정리
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
  // 👥 [신규 추가] 다수 유저 정보 조회 (차단 목록 표시용)
  // =========================================================
  Future<List<UserModel>> fetchUsersBasicInfo(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final List<UserModel> users = [];

      // Firestore 'whereIn' 쿼리는 최대 10개까지만 지원하므로 10개씩 끊어서 조회
      for (var i = 0; i < userIds.length; i += 10) {
        final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        final chunk = userIds.sublist(i, end);

        final snapshot = await _firestore
            .collection(MyCollection.USERS) // MyCollection 상수 사용
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
}