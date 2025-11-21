import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

class AdService {
  // ===========================================================================
  // 🆔 테스트용 광고 단위 ID (배포 시 실제 ID로 교체 필수)
  // ===========================================================================

  // 1. 전면 광고 (Interstitial) ID
  final String _interstitialId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  // 2. 보상형 광고 (Rewarded) ID
  final String _rewardedId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  // (참고) 배너 ID는 여기서 관리하지 않고 Widget에서 관리하거나 getter로 제공
  String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';


  // ===========================================================================
  // ⚙️ 상태 변수
  // ===========================================================================
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  // ===========================================================================
  // 🚀 초기화 및 로드
  // ===========================================================================
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd(); // 보상형도 미리 로드
  }

  // ---------------------------------------------------------------------------
  // A. 전면 광고 (Interstitial) - 특정 시점(API 호출 전후)
  // ---------------------------------------------------------------------------
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          // 닫히면 자동으로 다음 광고 로드 설정
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialLoaded = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isInterstitialLoaded = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('❌ 전면 광고 로드 실패: $err');
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  /// [onAdClosed]: 광고를 닫은 후(또는 실패 후) 실행할 로직 (API 호출, 화면 이동 등)
  void showInterstitialAd({required VoidCallback onAdClosed}) {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      // 콜백을 일시적으로 오버라이드하여 사용자 로직 주입
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialLoaded = false;
          loadInterstitialAd(); // 다음 광고 준비
          onAdClosed(); // ✅ 사용자가 원하는 동작 실행
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _isInterstitialLoaded = false;
          loadInterstitialAd();
          onAdClosed(); // 실패해도 동작은 실행
        },
      );
      _interstitialAd!.show();
    } else {
      onAdClosed(); // 광고 없으면 그냥 통과
      loadInterstitialAd();
    }
  }

  // ---------------------------------------------------------------------------
  // B. 보상형 광고 (Rewarded) - 기능 해금용
  // ---------------------------------------------------------------------------
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          // 닫힘 이벤트 처리
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedLoaded = false;
              loadRewardedAd(); // 다음 광고 준비
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isRewardedLoaded = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('❌ 보상형 광고 로드 실패: $err');
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  /// [onRewardGranted]: 사용자가 광고를 끝까지 봐서 보상을 받아야 할 때 실행
  void showRewardedAd({required VoidCallback onRewardGranted}) {
    if (_isRewardedLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // ✅ 사용자가 광고 시청 완료! 보상 로직 실행
          debugPrint('🎉 보상 획득: ${reward.amount} ${reward.type}');
          onRewardGranted();
        },
      );
      // 주의: show() 호출 후 ad 객체는 재사용 불가하므로 dismissed 콜백에서 재로드됨
      _rewardedAd = null;
      _isRewardedLoaded = false;
    } else {
      // 광고가 준비 안 됐을 때 (안내 메시지 등을 띄우거나, 그냥 보상을 줄 수도 있음)
      debugPrint('⚠️ 보상형 광고가 아직 준비되지 않았습니다.');
      // 선택 사항: 광고 로드 실패 시 그냥 기능을 열어줄지, 아니면 기다리게 할지 결정
      // 여기서는 엄격하게 "광고 안 보면 보상 없음"으로 처리
      loadRewardedAd();
    }
  }
}