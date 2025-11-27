// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
