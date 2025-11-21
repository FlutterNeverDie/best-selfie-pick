import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  // 1. 💡 리워드 광고 ID (기존 유지)
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
    }
    throw UnsupportedError("Unsupported platform");
  }

  // 2. 💡 [신규] 배너 광고 ID (테스트용)
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
    }
    throw UnsupportedError("Unsupported platform");
  }

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // ... (기존 loadRewardedAd, showRewardedAd 로직은 그대로 유지) ...

  // 3. 💡 [신규] 배너 광고 생성 함수
  // 배너는 위젯 형태로 사용되므로, 로드된 BannerAd 객체를 반환합니다.
  BannerAd createBannerAd({required Function(Ad) onAdLoaded}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner, // 기본 배너 사이즈 (320x50)
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패: $error');
          ad.dispose();
        },
      ),
    );
  }
}