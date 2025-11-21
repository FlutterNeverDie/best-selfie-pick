import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/auth/s_auth_gate.dart';
import 'package:selfie_pick/feature/notice/s_notice.dart';
import 'package:selfie_pick/feature/singup/s_login.dart';

import '../../feature/inquiry/s_inquiry.dart';
import '../../feature/my_entry/s_entry_submission_screen.dart';
import '../../feature/notification/s_notification_settings.dart';
import '../../feature/singup/s_email.dart';
import '../../feature/singup/s_profile_setup.dart';
import '../../feature/singup/s_welcome.dart';



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
      GoRoute(
        path: 'submit_entry',
        name: EntrySubmissionScreen.routeName,
        builder: (context, state) =>  EntrySubmissionScreen(),
      ),
      GoRoute(
        path: 'notifications',
        name: NotificationSettingsScreen.routeName, // '/notifications'
        builder: (context, state) => const NotificationSettingsScreen(),
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