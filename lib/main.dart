// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:selfie_pick/shared/provider/riverpod_observer.dart';

import 'app.dart';
import 'core/data/local_storage.dart';
import 'firebase_options.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/config/.env");

  //  Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. 🟡 카카오 SDK 초기화 (.env에서 키 가져오기)
  // 키가 없을 경우를 대비해 빈 문자열 처리 (실제로는 .env에 꼭 있어야 함)
  final String kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';

  // 🔍 [디버그] 키 로드 확인 (로그캣에서 확인하세요)
  if (kakaoNativeAppKey.isEmpty) {
    debugPrint('🚨 [Main] 오류: .env에서 KAKAO_NATIVE_APP_KEY를 찾을 수 없습니다!');
  } else {
    debugPrint('✅ [Main] 카카오 키 로드 성공: ${kakaoNativeAppKey.substring(0, 5)}...');
  }

  KakaoSdk.init(
    nativeAppKey: kakaoNativeAppKey,
  );

  MobileAds.instance.initialize();

  // 로컬 스토리지 초기화
  await initializeLocalStorage();

  runApp(
    ProviderScope(
      observers: [RiverpodObserver()],
      child: App(),
    ),
  );
}

Future<void> initializeLocalStorage() async {
  await LocalStorage.instance.init();
}
