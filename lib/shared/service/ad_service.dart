import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  // 1. 리워드 광고 ID (테스트용)
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
    }
    throw UnsupportedError("Unsupported platform");
  }

  // 2. 배너 광고 ID (테스트용)
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

  // --- 리워드 광고 관련 로직 ---

  void loadRewardedAd({VoidCallback? onAdLoaded}) {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('🎉 리워드 광고 로드 성공!');
          _rewardedAd = ad;
          _isAdLoading = false;
          if (onAdLoaded != null) onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('💥 리워드 광고 로드 실패: $error');
          _rewardedAd = null;
          _isAdLoading = false;
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
      debugPrint('⚠️ 준비된 광고가 없습니다.');
      // 광고 로드 실패 시에도 기능은 동작하도록 처리 (선택 사항)
      onRewardEarned();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('📺 광고 표시됨');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('👋 광고 닫힘');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // 다음을 위해 미리 로드
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('💥 광고 표시 실패: $error');
        ad.dispose();
        _rewardedAd = null;
        onRewardEarned(); // 실패 시에도 보상 지급 처리
      },
    );

    _rewardedAd!.setImmersiveMode(true);

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('💰 보상 지급 완료!');
        onRewardEarned();
      },
    );
  }

  // --- 배너 광고 관련 로직 ---

  // 3. 배너 광고 생성 함수 (사이즈를 인자로 받음)
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    AdSize size = AdSize.banner, // 기본값: 일반 배너
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size, // 전달받은 사이즈 사용 (LargeBanner 등)
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

  void dispose() {
    _rewardedAd?.dispose();
  }
}