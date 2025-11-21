import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdSize 사용을 위해 추가
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/rank/widget/w_candidate_item.dart';
import '../../../shared/admob/w_banner_ad.dart';
import '../provider/vote_provider.dart';

const double _bottomPadding = 140.0;
/// 그리드 내 광고 삽입 빈도
const int _adFrequency = 4; // 4개마다 광고 1개

class WVotingCandidateGrid extends ConsumerWidget {
  const WVotingCandidateGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final notifier = ref.read(voteProvider.notifier);
    final candidates = status.candidates;

    // 💡 총 아이템 개수 계산 (후보자 수 + 중간에 끼어들 광고 수)
    // 예: 후보 10명이면 -> 광고는 2개(4번째, 9번째) -> 총 12개 셀 필요
    final int adCount = candidates.isNotEmpty ? candidates.length ~/ _adFrequency : 0;
    final int totalItemCount = candidates.length + adCount;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
            status.hasMorePages &&
            !status.isLoadingNextPage) {
          notifier.loadCandidates();
          return true;
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  // 💡 [핵심] 인덱스 패턴 분석: (index + 1) % 5 == 0 이면 광고 자리
                  // 패턴: 0,1,2,3(후보), 4(광고), 5,6,7,8(후보), 9(광고)...
                  if ((index + 1) % (_adFrequency + 1) == 0) {
                    return _buildAdCard();
                  }

                  // 💡 광고 자리를 뺀 실제 데이터 인덱스 계산
                  final int realIndex = index - (index ~/ (_adFrequency + 1));

                  if (realIndex >= candidates.length) return null;
                  return WCandidateItem(candidate: candidates[realIndex]);
                },
                childCount: totalItemCount,
              ),
            ),
          ),

          // 로딩 인디케이터
          if (status.isLoadingNextPage)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          // 하단 여백
          SliverPadding(padding: EdgeInsets.only(bottom: _bottomPadding.h)),
        ],
      ),
    );
  }

  // 💡 [광고 카드 디자인] 후보자 카드와 똑같은 스타일 적용
  Widget _buildAdCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 'Sponsored' 라벨
          Text(
            'Sponsored',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
          ),
          SizedBox(height: 8.h),

          // 광고 위젯
          // 2열 그리드 폭(약 160px)에 맞는 광고 사이즈는 표준에 없음.
          // 300x250은 너무 커서 잘림.
          // 따라서 320x50 배너나 320x100 라지 배너를 사용하여 깔끔하게 배치.
          const WBannerAd(adSize: AdSize.largeBanner),
        ],
      ),
    );
  }
}