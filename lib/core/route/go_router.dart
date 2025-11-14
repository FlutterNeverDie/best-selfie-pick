import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/route/route.dart';
import 'package:selfie_pick/core/route/route_observer.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/singup/s_signup.dart';

import '../../app.dart';
import '../../feature/auth/provider/auth_notifier.dart';
import '../../feature/singup/s_profile_setup.dart';


const bool shouldShowRedirectDebug = false; // 디버그 출력을 끄려면 false로 변경

final GoRouter router = GoRouter(
  navigatorKey: App.globalNavigatorKey,
  initialLocation: AuthGateScreen.routeName,
  routes: appRoutes,
  observers: [RouteTracker.instance],
  redirect: (context, state) {


    // ⭐️ 디버그 시작 (한국어)
    if (shouldShowRedirectDebug) {
      debugPrint('🚦 [라우터 리디렉션 확인] 목표 경로: ${state.uri.toString()}');
    }


    // 1. Riverpod 컨테이너 읽기 (ProviderScope.containerOf(context) 사용)
    final providerContext = ProviderScope.containerOf(context);

    // 2. AuthState를 읽어옴
    final authState = providerContext.read(authProvider);
    final isLoggedIn = authState.user != null;
    final isProfileIncomplete = authState.user?.isProfileIncomplete == true;

    if (authState.isLoading) {
      if (shouldShowRedirectDebug) {
        debugPrint('   -> 결과: 로딩 중. 리디렉션 대기 (null)');
      }
      return null;
    }

    // 현재 이동하려는 경로 (path)
    final currentPath = state.uri.toString();

    // 비인증 경로 목록 (로그인, 회원가입 관련)
    final isGuestRoute = currentPath.startsWith(SignupScreen.routeName);
    final isSetupRoute = currentPath.startsWith(SocialProfileSetupScreen.routeName);

    // ⭐️ 핵심 디버그: 현재 상태와 플래그 출력 (한국어)
    if (shouldShowRedirectDebug) {
      debugPrint('   - 인증 상태: ${authState.user != null ? '✅ 로그인됨' : '❌ 로그아웃됨'}');
      debugPrint('   - 프로필 미완료: ${isProfileIncomplete ? '⚠️ 예' : '✅ 아니오'}');
      debugPrint('   - 비인증 경로 진입?: $isGuestRoute (경로: ${SignupScreen.routeName})');
      debugPrint('   - 프로필 설정 경로?: $isSetupRoute (경로: ${SocialProfileSetupScreen.routeName})');
    }

    // --- 리디렉션 로직 시작 ---

    // Case 1: 로그아웃 상태일 때 (isLoggedIn == false)
    if (!isLoggedIn) {
      if (isGuestRoute) {
        if (shouldShowRedirectDebug) {
          debugPrint('   -> 결과: 리디렉션 없음 (이미 비인증 경로)');
        }
        return null;
      }
      if (shouldShowRedirectDebug) {
        debugPrint('   -> 결과: ${SignupScreen.routeName}로 리디렉션 (로그인 필요)');
      }
      return SignupScreen.routeName;
    }

    // Case 2: 로그인 상태일 때 (isLoggedIn == true)

    // 2-1: 프로필 미완료 상태일 때 (isProfileIncomplete == true)
    if (isProfileIncomplete) {
      // ⚠️ 수정: 전체 경로(Full Path)를 구성하여 반환해야 합니다.
      final setupPath = '${SignupScreen.routeName}/${SocialProfileSetupScreen.routeName}';

      // 이미 프로필 설정 화면으로 가고 있다면 이동 허용
      if (state.uri.toString().startsWith(setupPath)) {
        if (shouldShowRedirectDebug) {
          debugPrint('   -> 결과: 리디렉션 없음 (이미 프로필 설정 경로)');
        }
        return null;
      }

      // 다른 모든 경로(Home 포함)로 접근 시도 시, 프로필 설정 화면으로 강제 리디렉션
      if (shouldShowRedirectDebug) {
        debugPrint('   -> 결과: $setupPath로 리디렉션 (프로필 미완료)');
      }
      return setupPath;
    }

    // 2-2: 프로필 완료 상태일 때 (isProfileIncomplete == false)
    if (!isProfileIncomplete) {
      if (isGuestRoute || isSetupRoute) {
        if (shouldShowRedirectDebug) {
          debugPrint('   -> 결과: ${HomeScreen.routeName}로 리디렉션 (프로필 완료, 비인증/설정 경로 이탈)');
        }
        return HomeScreen.routeName;
      }
      if (shouldShowRedirectDebug) {
        debugPrint('   -> 결과: 리디렉션 없음 (Home 또는 인증 경로 유지)');
      }
      return null;
    }

    if (shouldShowRedirectDebug) {
      debugPrint('   -> 결과: 리디렉션 없음 (기본 폴백)');
    }
    return null;
  },
  errorPageBuilder: (context, state) {

    debugPrint('*** GoRouter Navigation Error Detected ***');
    debugPrint('Error: ${state.error}');
    debugPrint('Path (uri): ${state.uri}');
    debugPrint('Path Parameters: ${state.pathParameters}');
    debugPrint('Full Path: ${state.path}');
    debugPrint('*******************************************');

    void goHome() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }

    // ❗️ 주의: 이 코드는 GoRouter 설정 파일의 일부입니다.
// Riverpod의 Consumer 위젯을 사용하므로, 이 코드를 포함하는 상위 컨텍스트는
// 반드시 ProviderScope 안에 있어야 하며, authProvider가 올바르게 import되어야 합니다.

    return MaterialPage(
      child: Scaffold(
        // AppColor.white 대신 Colors.white 사용 가정
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Error Page'),
          leading: Builder( // context.pop()을 사용하기 위해 Builder로 감쌈
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  // 수정: 바로 이전 화면으로 복귀
                  onPressed: () {
                    // 이전 화면으로 복귀가 가능하면 pop, 아니면 '/signup'으로 go
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // 뒤로 갈 화면이 없으면 로그인 화면으로 리디렉션 (프로젝트의 초기 경로)
                      context.go('/signup');
                    }
                  },
                );
              }
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('페이지가 삭제되거나 유효하지 않습니다.'),
              Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
              Text(
                '경로(uri): ${state.uri}',
                style: const TextStyle(color: Colors.red),
              ),
              Text('경로 파라미터: ${state.pathParameters}'),
              Text('path: ${state.path}'),
              const SizedBox(height: 20),

              // 수정: Riverpod Consumer를 사용하여 로그아웃 및 재시작 로직 구현
              Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () async {
                        // 1. 로그아웃 수행
                        // authProvider.notifier.signOut() 호출 (import 가정)
                        try {
                          await ref.read(authProvider.notifier).signOut();
                        } catch (e) {
                          debugPrint('Logout failed during restart: $e');
                        }

                        // 2. 로그인 페이지로 이동 (/signup은 이 프로젝트의 초기 진입 경로)
                        context.go(SignupScreen.routeName);
                      },
                      // 수정: 버튼 텍스트 변경
                      child: const Text('재시작'),
                    );
                  }
              ),
            ],
          ),
        ),
      ),
    );
  },
);
