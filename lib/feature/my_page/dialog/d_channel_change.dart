import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';

import '../../../core/data/area.data.dart';
import '../../../shared/service/ad_service.dart';

class ChannelChangeDialog extends ConsumerStatefulWidget {
  const ChannelChangeDialog({super.key});

  @override
  ConsumerState<ChannelChangeDialog> createState() => _ChannelChangeDialogState();
}

class _ChannelChangeDialogState extends ConsumerState<ChannelChangeDialog> {
  String? _selectedChannel;
  bool _isUpdating = false;
  bool _isAdLoading = true;

  final AdmobService _adService = AdmobService();

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null && currentUser.channel != 'NotSet') {
      _selectedChannel = currentUser.channel;
    }

    // 💡 [수정] 30초 리워드 대신 '스킵 가능한 리워드 전면 광고' 로드
    _adService.loadRewardedInterstitialAd(
        onAdLoaded: () {
          if (mounted) {
            setState(() {
              _isAdLoading = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() {
              _isAdLoading = false;
            });
          }
        }
    );
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  Future<void> _confirmChange() async {
    if (_selectedChannel == null) return;

    setState(() => _isUpdating = true);

    try {
      await ref.read(authProvider.notifier).updateChannel(_selectedChannel!);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채널이 $_selectedChannel(으)로 변경되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _onConfirmPressed() {
    if (_selectedChannel == null) return;

    // 💡 [수정] showRewardedAd -> showRewardedInterstitialAd 사용
    _adService.showRewardedInterstitialAd(
        onRewardEarned: () {
          _confirmChange();
        },
        onAdFailed: () {
          _confirmChange();
        },
        onAdDismissed: () {
          debugPrint('광고 닫힘 (변경 취소)');
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '활동 채널 변경',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '변경 시 5초 내외의 광고가 재생됩니다.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),

            SizedBox(
              height: 300.h,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.w,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 2.2,
                ),
                itemCount: areasGlobalList.length,
                itemBuilder: (context, index) {
                  final region = areasGlobalList[index];
                  final isSelected = _selectedChannel == region;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedChannel = region;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.w),
                        border: Border.all(
                          color: isSelected ? AppColor.primary : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        region,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 24.h),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isUpdating || _isAdLoading || _selectedChannel == null)
                        ? null
                        : _onConfirmPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
                    ),
                    child: _isUpdating
                        ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : _isAdLoading
                        ? SizedBox(
                      height: 20.w,
                      width: 20.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('채널 변경', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}