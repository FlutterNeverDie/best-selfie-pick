
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/route/go_router.dart';
import 'core/theme/theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();

  static final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey();

}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {

  GlobalKey<NavigatorState> get globalKey => App.globalNavigatorKey;

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
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return ScreenUtilInit(
      designSize: Size(width, height),
      child: MaterialApp.router(
        debugShowMaterialGrid: false,
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: false,
        theme: buildThemeData(context),
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
      ),
    );
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("========= AppLifecycleState.resumed =========");
        break;
      case AppLifecycleState.inactive:
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


}
