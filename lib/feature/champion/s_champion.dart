import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/champion/provider/champion_provider.dart';
import 'package:selfie_pick/feature/champion/provider/state/champion.state.dart';
import 'package:selfie_pick/feature/champion/widget/w_champion_app_bar.dart';

// 💡 분리된 위젯 Import
import 'widget/w_champion_podium.dart';
import 'widget/w_no_champion_message.dart';


class ChampionScreen extends ConsumerWidget {
  const ChampionScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 [수정] ChampionNotifier의 상태를 직접 감시
    final state = ref.watch(championProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 배경색 통일
      appBar: WChampionAppBar(),
      body: _buildBody(state),
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