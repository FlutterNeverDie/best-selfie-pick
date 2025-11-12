import 'package:flutter/material.dart';

class RouteTracker extends NavigatorObserver {
  static final RouteTracker instance = RouteTracker._internal();
  RouteTracker._internal();

  String? _currentRouteName;
  String? get currentRouteName => _currentRouteName;

  /// 메인 화면 콜백 함수
  Function()? _onReturnToMain;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _currentRouteName = route.settings.name;
    print('👉🏻[라우트 PUSH] ==> ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _currentRouteName = newRoute?.settings.name;
    print('👉🏻[라우트 REPLACE]: ==> ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _currentRouteName = previousRoute?.settings.name;
    print('👉🏻[라우트 POP] ==> ${route.settings.name} → ${previousRoute?.settings.name}');
    if (previousRoute?.settings.name == '/main') {
      if (_onReturnToMain != null) {
        print('🔄 RouteTracker: 메인 화면 복귀 감지 (POP) - 콜백 실행');
        _onReturnToMain!();
      } else {
        print('🔄 RouteTracker: 메인 화면 복귀 감지 (POP) - 콜백 없음, 세션만 비활성화');
      }
    }
  }

  /// 메인 화면 콜백 등록
  void setMainScreenCallback(Function() callback) {
    _onReturnToMain = callback;
  }

  /// 메인 화면 콜백 해제
  void clearMainScreenCallback() {
    _onReturnToMain = null;
  }
}