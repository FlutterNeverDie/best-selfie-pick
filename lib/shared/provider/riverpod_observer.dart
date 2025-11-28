import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class RiverpodObserver extends ProviderObserver {
  /// 로그를 무시할 Provider 이름 목록 (Set으로 관리)


  static Logger logger = Logger();

  static const Set<String> _ignoredProviders = {
    //참가
    'EntryProvider',
    'voteProvider',

    // 차단
    'blockedUsersInfoProvider',
    'blockedHistoryProvider',


    // 인증
    'authRepoProvider',
    'authProvider[인증]',


  };

  /// Provider 로그 출력 여부 확인
  bool _shouldLogProvider(String? providerName) {
    return providerName != null && !_ignoredProviders.contains(providerName);
  }

  /// 공통 로그 출력 메서드
  void _log(String message) {
    logger.d(' LOG : $message');
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (_shouldLogProvider(provider.name)) {
      _log('Provider ${provider.name} 추가 => ${value.toString()}');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (provider.name == null) {
      _log('Provider에 이름을 부여하세요! 이름 지정이 안되어 있습니다. 타입: ${provider.runtimeType}');
    } else if (_shouldLogProvider(provider.name!)) {
      _log('Provider ${provider.name} 소멸');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (_shouldLogProvider(provider.name)) {
      _log('''
[기존 값] Provider ${provider.name} 업데이트
$previousValue
To
[변경 값]
$newValue
''');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint(
      'Provider ${provider.name} threw $error at $stackTrace',
    );
  }
}
