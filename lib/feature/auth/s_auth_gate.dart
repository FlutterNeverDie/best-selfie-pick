// lib/features/splash/s_auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/home/s_home.dart';
import 'package:selfie_pick/feature/singup/s_welcome.dart';

import '../../core/theme/colors/app_color.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});
  static final routeName = '/auth_gate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. AuthNotifier의 상태(user, isLoading)를 구독합니다.
    final authState = ref.watch(authProvider);

    // 2. 로딩 완료 및 인증 확인 후 리디렉션 로직
    // WidgetsBinding.instance.addPostFrameCallback을 사용하여
    // 위젯 트리가 빌드된 후 GoRouter 이동을 수행합니다.
    if (!authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.user == null) {

          // 로그아웃 상태: 회원가입/로그인 화면으로 이동 (경로: /signup)
          context.go(WelcomeScreen.routeName);

        } else {

          debugPrint('로그인 성공 user: ${authState.user}');

          // 로그인 상태: 메인 홈 화면으로 이동 (경로: /home)
          context.go(HomeScreen.routeName);
        }
      });
    }

    // 3. 로딩 중 UI (로딩이 완료되거나 리디렉션이 발생할 때까지 표시)
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColor.primary),
          ],
        ),
      ),
    );
  }
}