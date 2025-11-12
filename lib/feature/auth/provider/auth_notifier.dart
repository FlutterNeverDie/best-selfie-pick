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
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _repository.signIn(email: email, password: password);
      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
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


}