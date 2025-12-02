import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/route/go_router.dart';
import 'core/route/route.dart'; // routerProvider import
import 'core/theme/theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  // route.dart에서 이 키를 참조하므로 static으로 유지해야 합니다.
  static final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("========= AppLifecycleState.resumed =========");
        break;
      case AppLifecycleState.paused:
        debugPrint("========= AppLifecycleState.paused =========");
        break;
      case AppLifecycleState.detached:
        debugPrint("========= AppLifecycleState.detached =========");
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      // (일반적인 모바일 기준: 375 x 812)
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Best Pick',
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(context),
          routerConfig: router,
        );
      },
    );
  }
}