import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../service/ad_service.dart'; // LoadAdError 사용을 위해


/// 🎨 공용 확인/취소 SimpleDialog 스타일 위젯
/// 제목, 내용, 버튼 텍스트를 외부에서 받아 깔끔한 디자인으로 노출합니다.
/// requiresAd: true로 설정하면 확인 버튼을 눌렀을 때 보상형 광고를 보여줍니다.
class WCustomConfirmDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool requiresAd; // 💡 광고 시청 필요 여부

  const WCustomConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.requiresAd = false, // 기본값은 false (광고 없음)
  });

  @override
  State<WCustomConfirmDialog> createState() => _WCustomConfirmDialogState();
}

class _WCustomConfirmDialogState extends State<WCustomConfirmDialog> {
  final AdmobService _adService = AdmobService();
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    // 💡 광고가 필요한 경우에만 미리 로드 (Preload)
    if (widget.requiresAd) {
      _isAdLoading = true;
      _adService.loadRewardedInterstitialAd(
          onAdLoaded: () {
            if (mounted) {
              setState(() => _isAdLoading = false);
            }
          },
          onAdFailedToLoad: (error) {
            if (mounted) {
              // 실패하더라도 버튼은 활성화시켜서 기능 수행은 가능하게 함
              setState(() => _isAdLoading = false);
            }
          }
      );
    }
  }

  @override
  void dispose() {
    // 광고가 필요했던 경우에만 dispose 호출
    if (widget.requiresAd) {
      _adService.dispose();
    }
    super.dispose();
  }

  // 🎯 확인 버튼 클릭 핸들러
  void _onConfirmPressed() {
    // 1. 광고가 필요 없는 경우 -> 바로 true 반환
    if (!widget.requiresAd) {
      Navigator.of(context).pop(true);
      return;
    }

    // 2. 광고가 필요한 경우 -> 광고 보여주기
    _adService.showRewardedInterstitialAd(
        onRewardEarned: () {
          // 보상 획득 (광고 시청 완료) -> true 반환
          Navigator.of(context).pop(true);
        },
        onAdFailed: () {
          // 광고 실패 시 -> 유저 경험을 위해 그냥 통과 (true 반환)
          Navigator.of(context).pop(true);
        },
        onAdDismissed: () {
          // 광고를 도중에 닫음 -> 아무 동작 안 함 (다이얼로그 유지)
          debugPrint('광고 닫힘 (작업 취소)');
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.w)),
      contentPadding: EdgeInsets.zero,
      children: [
        // 1. 다이얼로그 제목 및 내용 영역
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                widget.content,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              // 💡 광고 안내 문구 추가 (선택 사항)
              if (widget.requiresAd) ...[
                SizedBox(height: 8.h),
                Text(
                  '* 진행 시 광고가 재생됩니다.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.redAccent),
                ),
              ]
            ],
          ),
        ),

        // 2. 액션 버튼 영역
        Divider(height: 1.0, color: Colors.grey.shade200),

        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 취소 버튼
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    widget.cancelText,
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              VerticalDivider(width: 1.0, thickness: 1.0, color: Colors.grey.shade200),

              // 확인 버튼
              Expanded(
                child: TextButton(
                  // 💡 로딩 중이면 클릭 방지
                  onPressed: (widget.requiresAd && _isAdLoading)
                      ? null
                      : _onConfirmPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: (widget.requiresAd && _isAdLoading)
                  // 💡 광고 로딩 중이면 인디케이터 표시
                      ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent)
                  )
                      : Text(
                    widget.confirmText,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}