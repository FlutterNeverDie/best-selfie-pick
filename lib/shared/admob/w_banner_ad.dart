import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../service/ad_service.dart';

class WBannerAd extends StatefulWidget {
  final AdSize adSize; // 💡 사이즈 파라미터 추가

  const WBannerAd({
    super.key,
    this.adSize = AdSize.banner, // 기본값
  });

  @override
  State<WBannerAd> createState() => _WBannerAdState();
}

class _WBannerAdState extends State<WBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  final AdmobService _adService = AdmobService();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = _adService.createBannerAd(
      size: widget.adSize, // 💡 전달받은 사이즈 사용
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // 로딩 중일 때 자리 차지하지 않도록
      return SizedBox(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
      );
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}