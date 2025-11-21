import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../service/ad_service.dart';

class WBannerAd extends StatefulWidget {
  const WBannerAd({super.key});

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
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
    )..load(); // 생성 후 바로 로드 시작
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 💡 메모리 누수 방지 (필수)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고가 로드되지 않았으면 공간을 차지하지 않음 (또는 빈 박스)
    if (!_isLoaded || _bannerAd == null) {
      return SizedBox(height: 50.h); // 로딩 중일 때 빈 공간 유지 (레이아웃 덜컥거림 방지)
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}