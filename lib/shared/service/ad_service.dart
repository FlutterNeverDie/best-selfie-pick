import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  // 1. [기존] 리워드 광고 ID (30초 시청용)
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError("Unsupported platform");
  }

  // 2. [신규] 보상형 전면 광고 ID (5초 스킵 가능용)
  static String get _rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5354046379'; // Android Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866'; // iOS Test ID
    }
    throw UnsupportedError("Unsupported platform");
  }

  // 3. [기존] 배너 광고 ID
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError("Unsupported platform");
  }

  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd; // 💡 신규 변수
  bool _isAdLoading = false;

  // --- A. 기존 리워드 광고 (30초) ---
  void loadRewardedAd({
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad
  }) {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('🎉 30초 리워드 광고 로드 성공!');
          _rewardedAd = ad;
          _isAdLoading = false;
          if (onAdLoaded != null) onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('💥 30초 리워드 광고 로드 실패: $error');
          _rewardedAd = null;
          _isAdLoading = false;
          if (onAdFailedToLoad != null) onAdFailedToLoad(error);
        },
      ),
    );
  }

  void showRewardedAd({
    required Function onRewardEarned,
    Function? onAdDismissed,
    Function? onAdFailed,
  }) {
    if (_rewardedAd == null) {
      onRewardEarned();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        onRewardEarned();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onRewardEarned();
      },
    );
  }

  // --- B. 💡 [신규] 보상형 전면 광고 (5초 스킵 가능) ---
  void loadRewardedInterstitialAd({
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad
  }) {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          debugPrint('🎉 스킵 가능 리워드 광고 로드 성공!');
          _rewardedInterstitialAd = ad;
          _isAdLoading = false;
          if (onAdLoaded != null) onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('💥 스킵 가능 리워드 광고 로드 실패: $error');
          _rewardedInterstitialAd = null;
          _isAdLoading = false;
          if (onAdFailedToLoad != null) onAdFailedToLoad(error);
        },
      ),
    );
  }

  void showRewardedInterstitialAd({
    required Function onRewardEarned,
    Function? onAdDismissed,
    Function? onAdFailed,
  }) {
    if (_rewardedInterstitialAd == null) {
      debugPrint('⚠️ 준비된 스킵형 광고가 없습니다.');
      onRewardEarned();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        debugPrint('👋 스킵형 광고 닫힘');
        ad.dispose();
        _rewardedInterstitialAd = null;
        // 다음을 위해 미리 로드
        loadRewardedInterstitialAd();
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        debugPrint('💥 스킵형 광고 표시 실패: $error');
        ad.dispose();
        _rewardedInterstitialAd = null;
        onRewardEarned();
      },
    );

    _rewardedInterstitialAd!.setImmersiveMode(true);

    // 보상형 전면 광고 보여주기
    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('💰 스킵형 보상 지급 완료!');
        onRewardEarned();
      },
    );
  }

  // --- C. 배너 광고 (기존) ---
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}