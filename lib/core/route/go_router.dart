import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/route/route_observer.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/singup/s_welcome.dart';

import '../../app.dart';
import '../../feature/auth/provider/auth_notifier.dart';
import '../../feature/singup/s_profile_setup.dart';
import '../../feature/inquiry/s_inquiry.dart';
import '../../feature/my_entry/s_entry_submission_screen.dart';
import '../../feature/notification/s_notification_settings.dart';
import '../../feature/report/s_blocked_users.dart';
import '../../feature/singup/s_email.dart';
import '../../feature/singup/s_login.dart';
import '../../feature/notice/s_notice.dart';


const bool shouldShowRedirectDebug = true; // 디버그 로그 확인용

/// 💡 [신규] AuthProvider 상태 변화를 감지하여 GoRouter에 알리는 클래스
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // authProvider의 상태가 변하면(=로그인/로그아웃/프로필완료 등)
    // notifyListeners()를 호출하여 GoRouter의 redirect를 재실행시킵니다.
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// 💡 [수정] 전역 변수 router를 Provider로 변경
final routerProvider = Provider<GoRouter>((ref) {
  // 상태 감지기 인스턴스 생성
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: App.globalNavigatorKey,
    initialLocation: AuthGateScreen.routeName,

    // ⭐️ [핵심] 이 설정이 있어야 로그인 상태 변경 시 redirect가 자동 실행됩니다.
    refreshListenable: notifier,

    routes: [
      // 1. 초기 진입점
      GoRoute(
        name: 'auth_gate_screen',
        path: AuthGateScreen.routeName,
        builder: (context, state) => const AuthGateScreen(),
      ),

      // 2. 인증 후 메인 앱 경로
      GoRoute(
        name: 'home_screen',
        path: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'submit_entry',
            name: EntrySubmissionScreen.routeName,
            builder: (context, state) => EntrySubmissionScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: NotificationSettingsScreen.routeName,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'blocked_users',
            name: BlockedUsersScreen.routeName,
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          GoRoute(
            path: 'notice',
            name: NoticeScreen.routeName,
            builder: (context, state) => const NoticeScreen(),
          ),
          GoRoute(
            path: 'inquiry',
            name: InquiryScreen.routeName,
            builder: (context, state) => const InquiryScreen(),
          ),
        ],
      ),

      // 3. 비인증 경로
      GoRoute(
        name: 'welcome_screen',
        path: WelcomeScreen.routeName,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            name: 'email_signup_screen',
            path: EmailSignupScreen.routeName,
            builder: (context, state) => const EmailSignupScreen(),
          ),
          GoRoute(
            name: 'login_screen',
            path: LoginScreen.routeName,
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: SocialProfileSetupScreen.routeName,
            name: SocialProfileSetupScreen.routeName,
            builder: (context, state) => const SocialProfileSetupScreen(),
          ),
        ],
      ),
    ],

    observers: [RouteTracker.instance],

    redirect: (context, state) {
      // ⭐️ 디버그 로그
      if (shouldShowRedirectDebug) {
        debugPrint('🚦 [라우터 리디렉션 확인] 목표 경로: ${state.uri.toString()}');
      }

      // 1. ProviderScope.containerOf 대신 ref를 직접 사용 (훨씬 안전함)
      final authState = ref.read(authProvider);

      // 로딩 중이면 현재 상태 유지 (또는 스플래시에서 대기)
      if (authState.isLoading) {
        if (shouldShowRedirectDebug) {
          debugPrint('   -> 결과: 로딩 중. 리디렉션 대기 (null)');
        }
        return null;
      }

      final isLoggedIn = authState.user != null;
      final isProfileIncomplete = authState.user?.isProfileIncomplete == true;

      // 현재 이동하려는 경로
      final currentPath = state.uri.toString();

      // 경로 판단
      final isGuestRoute = currentPath.startsWith(WelcomeScreen.routeName);
      final isSetupRoute = currentPath.startsWith(SocialProfileSetupScreen.routeName);

      if (shouldShowRedirectDebug) {
        debugPrint('   - 인증 상태: ${isLoggedIn ? '✅ 로그인됨' : '❌ 로그아웃됨'}');
        debugPrint('   - 프로필 미완료: ${isProfileIncomplete ? '⚠️ 예' : '✅ 아니오'}');
      }

      // --- 리디렉션 로직 시작 ---

      // Case 1: 로그아웃 상태일 때
      if (!isLoggedIn) {
        // 이미 비인증 경로(웰컴, 로그인 등)에 있다면 통과
        if (isGuestRoute) {
          return null;
        }
        // 아니면 웰컴 화면으로 강제 이동
        return WelcomeScreen.routeName;
      }

      // Case 2: 로그인 상태일 때

      // 2-1: 프로필 미완료 상태 (소셜 로그인 직후 등)
      if (isProfileIncomplete) {
        // 프로필 설정 화면 경로는: /welcome/social_profile_setup
        final setupPath = '${WelcomeScreen.routeName}/${SocialProfileSetupScreen.routeName}';

        // 이미 설정 화면으로 가고 있다면 통과
        if (state.uri.toString() == setupPath) {
          return null;
        }

        // 다른 어디를 가려고 하든 설정 화면으로 보냄
        return setupPath;
      }

      // 2-2: 프로필 완료 상태 (정상 회원)
      if (!isProfileIncomplete) {
        // 로그인 관련 화면이나 설정 화면에 있다면 홈으로 이동
        if (isGuestRoute || isSetupRoute) {
          return HomeScreen.routeName;
        }
      }

      // 그 외에는 원래 가려던 곳으로 이동 허용
      return null;
    },

    errorPageBuilder: (context, state) {
      debugPrint('*** GoRouter Navigation Error ***');
      debugPrint('Error: ${state.error}');
      debugPrint('Path: ${state.uri}');

      return MaterialPage(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Error Page'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(WelcomeScreen.routeName);
                }
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('페이지를 찾을 수 없습니다.'),
                Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go(WelcomeScreen.routeName);
                        },
                        child: const Text('재시작 (로그아웃)'),
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
});