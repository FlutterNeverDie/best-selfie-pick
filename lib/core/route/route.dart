import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';

import '../../feature/singup/s_email.dart';
import '../../feature/singup/s_profile_setup.dart';
import '../../feature/singup/s_signup.dart';
import '../../feature/splash/s_splash.dart';



final List<GoRoute> appRoutes = [
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
/*      GoRoute(
        path: 'notifications', // 알림 화면 경로 유지 및 FRD 반영
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),*/
      // SearchScreen 경로는 MVP에서 제외하고 삭제
    ],
  ),

  // 3. 비인증 경로
  GoRoute(
    name: 'signup_screen',
    path: SignupScreen.routeName,
    builder: (context, state) => const SignupScreen(),
    routes: [
      GoRoute(
        name: 'email_signup_screen',
        path: EmailSignupScreen.routeName, // email_signup
        builder: (context, state) => const EmailSignupScreen(),
      ),
      GoRoute(
        name: 'login_screen',
        path: LoginScreen.routeName, // email_signup
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: SocialProfileSetupScreen.routeName,
        name: SocialProfileSetupScreen.routeName,
        builder: (context, state) => const SocialProfileSetupScreen(),
      ),
    ],
  ),
];