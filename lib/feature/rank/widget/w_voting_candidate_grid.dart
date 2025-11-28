import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:selfie_pick/feature/rank/widget/w_candidate_item.dart';
import '../../../shared/admob/w_banner_ad.dart';
import '../provider/vote_provider.dart';

const double _bottomPadding = 140.0;
const int _adFrequency = 3;

class WVotingCandidateGrid extends ConsumerWidget {
  const WVotingCandidateGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voteProvider);
    final notifier = ref.read(voteProvider.notifier);
    final candidates = status.candidates;

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
                  // 광고 자리인지 확인
                  if ((index + 1) % (_adFrequency + 1) == 0) {
                    // 💡 [수정] KeepAlive 래퍼로 감싸서 리턴 (Key 추가)
                    return const _AdItemWrapper(
                      key: ValueKey('ad_item'),
                    );
                  }

                  final int realIndex = index - (index ~/ (_adFrequency + 1));

                  if (realIndex >= candidates.length) return null;

                  // 후보자 아이템 (Key 추가 권장)
                  return WCandidateItem(
                    key: ValueKey(candidates[realIndex].entryId),
                    candidate: candidates[realIndex],
                  );
                },
                childCount: totalItemCount,
              ),
            ),
          ),

          if (status.isLoadingNextPage)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          SliverPadding(padding: EdgeInsets.only(bottom: _bottomPadding.h)),
        ],
      ),
    );
  }
}

// 💡 [신규 추가] 광고 위젯의 상태를 보존하기 위한 래퍼 클래스
class _AdItemWrapper extends StatefulWidget {
  const _AdItemWrapper({super.key});

  @override
  State<_AdItemWrapper> createState() => _AdItemWrapperState();
}

// AutomaticKeepAliveClientMixin을 사용하여 스크롤이 되어도 뷰를 파괴하지 않음
class _AdItemWrapperState extends State<_AdItemWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // true를 반환하면 메모리에 유지됨

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용 시 필수 호출
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
          Text(
            'Sponsored',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
          ),
          SizedBox(height: 8.h),
          const WBannerAd(adSize: AdSize.largeBanner),
        ],
      ),
    );
  }
}