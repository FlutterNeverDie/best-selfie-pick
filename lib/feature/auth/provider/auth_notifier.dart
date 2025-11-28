import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/feature/auth/provider/repository/auth_repo.dart';
import 'package:selfie_pick/feature/auth/provider/state/auth.state.dart';

import '../../../model/m_user.dart';


final authProvider = NotifierProvider<AuthNotifier, AuthState>(
        () => AuthNotifier(), name: 'authProvider[인증]');

class AuthNotifier extends Notifier<AuthState> {
  // AuthRepo를 읽어옵니다. (Repository 패턴)
  AuthRepo get _repository => ref.read(authRepoProvider);

  @override
  AuthState build() {
    // ❗️ 중요: build()가 완료된 후 초기화 로직을 시작하도록 Future.microtask으로 감쌉니다.
    // 이는 'Tried to read the state of an uninitialized provider' 오류를 방지합니다.
    Future.microtask(_initializeAuthStatus);

    // build()는 즉시 초기 로딩 상태를 반환합니다.
    return AuthState(isLoading: true);
  }

  // 초기 인증 및 데이터 로드 로직 (일회성)
  Future<void> _initializeAuthStatus() async {
    // 이 시점에서는 state가 이미 {isLoading: true}로 초기화되어 안전합니다.
    state = state.copyWith(isLoading: true, error: null);

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {

      debugPrint('auth에 사용자가 없음');
      // 로그아웃 상태 확정
      state = AuthState(isLoading: false);
      return;
    }

    // 로그인 상태: Firestore 데이터 로드 시도
    try {
      final userModel = await _repository.fetchUserModel(currentUser.uid);

      // Firebase Auth에는 유저가 있지만 Firestore 데이터(UserModel)가 없는 경우 처리
      if (userModel == null) {
        await _repository.signOut();
        state = AuthState(isLoading: false, error: '사용자 데이터베이스 기록이 유효하지 않습니다.');
      } else {
        state = state.copyWith(user: userModel, isLoading: false);
      }
    } catch (e) {
      // 로그인 데이터 로드 실패 (네트워크 오류 등)
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 3. 이메일 로그인 함수 (UI에서 호출)
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _repository.signIn(email: email, password: password);
      state = state.copyWith(user: userModel, isLoading: false);
      return true; // 🎯 로그인 성공
    } on FirebaseAuthException catch (e) {

      print('e : ${e.toString()}');

      // 🎯 FirebaseAuthException 발생 시 코드를 분석하여 메시지 변환
      String message = '로그인에 실패했습니다. 다시 시도해 주세요.';

      switch (e.code) {
        case 'user-not-found':
        case 'user-data-missing':
          message = '가입되지 않은 이메일이거나 사용자 정보를 찾을 수 없습니다.';
          break;
        case 'wrong-password':
        case 'INVALID_LOGIN_CREDENTIALS':
        case 'invalid-credential':
          message = '비밀번호가 일치하지 않습니다. 다시 확인해 주세요.';
          break;
        case 'invalid-email':
          message = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'user-disabled':
          message = '사용이 정지된 계정입니다. 관리자에게 문의하세요.';
          break;
        case 'too-many-requests':
          message = '로그인 시도 횟수가 너무 많습니다. 잠시 후 다시 시도해 주세요.';
          break;
        case 'network-request-failed':
          message = '네트워크 연결 상태를 확인해 주세요.';
          break;
        default:
          message = '로그인 실패: ${e.message ?? e.code}';
          break;
      }

      // AuthState에 사용자 친화적인 에러 메시지 저장
      state = state.copyWith(isLoading: false, error: message);
      return false; // 🎯 로그인 실패 (예외 처리 완료)
    } catch (e) {
      // 기타 알 수 없는 오류 처리
      state = state.copyWith(isLoading: false, error: '로그인 중 알 수 없는 오류가 발생했습니다.');
      return false; // 🎯 로그인 실패
    }
  }

  /// 4. 이메일 회원가입 함수 (UI에서 호출)
  Future<void> signUp(String email, String password, String region, String gender) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final UserModel userModel = await _repository.signUp(
          email: email,
          password: password,
          region: region,
          gender: gender
      );

      print('userModel : $userModel');

      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }


  // 🎯 신규 추가: 소셜 로그인 완료 후 프로필 업데이트 및 상태 변경
  Future<void> completeSocialSignUp(String region, String gender) async {
    if (state.user == null || !state.user!.isProfileIncomplete) {
      throw Exception('프로필을 완료할 수 없는 상태입니다. 다시 로그인해주세요.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(authRepoProvider);

      // 현재 state.user는 ProfileIncomplete 상태의 UserModel입니다.
      final updatedUser = await repo.completeSocialSignUp(
        uid: state.user!.uid,
        email: state.user!.email,
        region: region,
        gender: gender,

      );

      // 상태 업데이트 -> isProfileIncomplete = false가 되면서 AuthGate가 /home으로 리디렉션
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString()
      );
      rethrow;
    }
  }

  /// 5. 구글 로그인 함수 (UI에서 호출)
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _repository.signInWithGoogle();

      // 구글 로그인은 성공했으나, UserModel 생성/로드 과정에서 문제가 생길 수 있음
      if (userModel == null) {
        state = state.copyWith(isLoading: false, error: '구글 로그인에 성공했으나 사용자 데이터를 가져올 수 없습니다.');
        return;
      }
      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 6. 애플 로그인 함수 (UI에서 호출)
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _repository.signInWithApple();

      if (userModel == null) {
        state = state.copyWith(isLoading: false, error: '애플 로그인에 성공했으나 사용자 데이터를 가져올 수 없습니다.');
        return;
      }
      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 7. 카카오 로그인 함수 (UI에서 호출)
  Future<void> signInWithKakao() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _repository.signInWithKakao();

      if (userModel == null) {
        state = state.copyWith(isLoading: false, error: '카카오 로그인에 성공했으나 사용자 데이터를 가져올 수 없습니다.');
        return;
      }
      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 8. 로그아웃 함수
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signOut();
      // 로그아웃 성공 후 상태 초기화 (user: null)
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 9. error 리셋
  void resetError() {
    state = state.copyWith(error: null);
  }



  /// 10. 이메일 중복 확인 함수 (Repository 위임 및 상태 처리)
  Future<bool> checkEmailAvailability(String email) async {
    // 중복 확인 전에 에러를 리셋합니다.
    state = state.copyWith(error: null);

    try {
      // AuthRepo의 새로운 checkIfEmailExists 호출
      final status = await _repository.checkIfEmailExists(email);

      switch (status) {
        case EmailCheckStatus.available:
          return true; // 사용 가능 (중복 아님)

        case EmailCheckStatus.emailAlreadyInUse:
        // 일반 이메일 계정 중복
        // AuthState에 에러 메시지 설정
          state = state.copyWith(error: '이미 해당 이메일로 가입된 계정이 존재합니다.');
          return false; // 사용 불가 (중복)

        case EmailCheckStatus.socialAccountFound:
        // 💡 소셜 로그인 계정 중복
        // AuthState에 소셜 계정임을 안내하는 에러 메시지 설정
          state = state.copyWith(error: '해당 이메일은 소셜 로그인으로 가입된 계정입니다.\n해당 소셜 로그인 버튼으로 진행해 주세요.');
          return false; // 사용 불가 (소셜 계정 중복)
      }
    } catch (e) {
      // 중복 확인 자체에서 오류가 발생했을 경우 (네트워크 등)
      state = state.copyWith(error: '이메일 중복 확인 중 오류 발생: ${e.toString()}');
      rethrow;
    }
  }

  /// 11. 회원 탈퇴 함수 (Auth/DB 계정 영구 삭제)
  Future<void> withdraw() async {
    final uid = state.user?.uid;
    if (uid == null) {
      // 이미 로그아웃되었거나 유효하지 않은 상태
      state = AuthState(isLoading: false, error: '유효한 사용자 정보가 없습니다.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Repository를 통해 Auth 계정 삭제 및 DB 문서 삭제를 시도합니다.
      await _repository.deleteAccount(uid);

      // 탈퇴 성공 후 상태 초기화 (user: null)
      state = AuthState(isLoading: false);

    } on FirebaseAuthException catch (e) {
      // 재인증 필요 오류 등 FirebaseAuth 관련 오류 처리
      String message = '탈퇴 실패: 인증 정보가 만료되었습니다. 다시 로그인 후 시도해 주세요.';
      if (e.code == 'requires-recent-login') {
        message = '보안을 위해 다시 로그인 후 시도해 주세요.';
      } else {
        message = '탈퇴 처리 중 오류 발생: ${e.message ?? e.code}';
      }

      state = state.copyWith(isLoading: false, error: message);
      rethrow;
    } catch (e) {
      // 기타 알 수 없는 오류 처리
      state = state.copyWith(isLoading: false, error: '회원 탈퇴 중 알 수 없는 오류가 발생했습니다.');
      rethrow;
    }
  }

  /// 12. 🎯 [신규] 채널 변경 함수
  Future<void> updateChannel(String newChannel) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    // 로딩 시작 (UI에서 로딩 인디케이터를 띄우고 싶다면)
    state = state.copyWith(isLoading: true, error: null);

    // 이미 같은 채이면 업데이트할 필요 없음
    if (currentUser.channel == newChannel) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // 1. Repository를 통해 DB 업데이트
      await _repository.updateUserChannel(currentUser.uid, newChannel);

      // 2. 💡 로컬 상태(state) 즉시 업데이트 (새로고침 불필요하게 만듦)
      // currentUser.copyWith는 UserModel에 copyWith가 구현되어 있어야 합니다.
      final updatedUser = currentUser.copyWith(
        channel: newChannel,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // UI에서 스낵바 등을 띄우기 위해 에러를 다시 던짐
    }
  }

  void updateUserLocally(UserModel updatedUser) {
    state = state.copyWith(user: updatedUser);
  }


}