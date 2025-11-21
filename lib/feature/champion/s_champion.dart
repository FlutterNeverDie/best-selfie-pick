import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/champion/provider/champion_provider.dart';
import 'package:selfie_pick/feature/champion/provider/state/champion.state.dart';

// 💡 분리된 위젯 Import
import 'widget/w_champion_podium.dart';
import 'widget/w_no_champion_message.dart';


class ChampionScreen extends ConsumerWidget {
  const ChampionScreen({super.key});

  // 💡 [수정] 새로고침 로직: Notifier의 로드 함수를 직접 호출
  Future<void> _onRefresh(WidgetRef ref) async {
    // build 내부에서 이미 필요한 인자를 가져오고 있으므로,
    // 여기서는 Notifier를 invalidate하고 재빌드하여 로드를 트리거합니다.
    ref.invalidate(championProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 [수정] ChampionNotifier의 상태를 직접 감시
    final state = ref.watch(championProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 배경색 통일
      appBar: AppBar(
        title: const Text('챔피언', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      // 💡 [수정] RefreshIndicator는 ChampionScreen 전체를 감싸는 것이 더 적절합니다.
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        color: AppColor.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // 스크롤 뷰가 화면을 꽉 채우도록 설정 (당겨서 새로고침을 위해 필수)
              minHeight: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: _buildBody(state),
          ),
        ),
      ),
    );
  }

  // 💡 [신규] 상태별 UI 분기 메서드
  Widget _buildBody(ChampionState state) {
    // 1. 로딩 상태
    if (state.isLoading) {
      return Center(
          child: Padding(
              padding: EdgeInsets.only(top: 100.h), // 상단에서 너무 붙지 않게 여백
              child: CircularProgressIndicator(color: AppColor.primary)
          )
      );
    }

    // 2. 에러 상태
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Text(
            state.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16.sp),
          ),
        ),
      );
    }

    // 3. 데이터 없음 상태 (Empty State)
    if (state.champions.isEmpty) {
      return const WNoChampionMessage();
    }

    // 4. 데이터 있음 상태 (Podium)
    return Padding(
      padding: EdgeInsets.only(bottom: 50.h),
      child: WChampionPodium(champions: state.champions),
    );
  }
}