import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/shared/admob/w_banner_ad.dart';

import '../champion/s_champion.dart';
import '../my_entry/s_my_entry.dart';
import '../my_page/s_my_page.dart';
import '../rank/s_ranking.dart';

// 페이지 인덱스 상태 관리
final pageIndexProvider = StateProvider<int>((ref) => 1); // 초기값 랭킹(1)

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static final routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<Widget> _widgetOptions = <Widget>[
    ChampionScreen(), // 0: 챔피언
    RankingScreen(), // 1: 랭킹/투표
    MyEntryScreen(), // 2: 내 참가
    MyPageScreen(), // 3: 마이페이지
  ];

  @override
  Widget build(BuildContext context) {
    final pageIndex = ref.watch(pageIndexProvider);

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.emoji_events_rounded, 'label': '챔피언'},
      {'icon': Icons.bar_chart_rounded, 'label': '랭킹'},
      {'icon': Icons.add_a_photo_rounded, 'label': '내 참가'},
      {'icon': Icons.person_rounded, 'label': '마이페이지'},
    ];

    return Scaffold(
      // 바디 색상을 탭바와 자연스럽게 어우러지도록 설정
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(
        index: pageIndex,
        children: _widgetOptions,
      ),

      // 💡 [디자인 업그레이드] 바텀 네비게이션 + 광고 영역
      bottomNavigationBar: Container(
        // 전체 컨테이너 장식 (그림자 + 라운딩)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // 은은한 그림자
              blurRadius: 20, // 부드럽게 퍼짐
              offset: const Offset(0, -5), // 위쪽으로 그림자
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 탭바 (ClipRRect로 상단 둥글게 잘라줌)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true, // 하단 패딩 제거 (광고와 밀착)
                child: BottomNavigationBar(
                  items: items.map((item) => BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.h), // 아이콘과 라벨 간격
                      child: Icon(item['icon'], size: 26.w), // 아이콘 크기 살짝 키움
                    ),
                    label: item['label'],
                  )).toList(),

                  currentIndex: pageIndex,

                  // 🎨 색상 및 스타일
                  selectedItemColor: AppColor.primary, // 선택 시 테마 컬러
                  unselectedItemColor: Colors.grey.shade400, // 비선택 시 연한 회색
                  backgroundColor: Colors.white, // 배경은 깔끔한 흰색

                  // 폰트 스타일
                  selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),

                  type: BottomNavigationBarType.fixed,
                  elevation: 0, // 자체 그림자 제거 (Container 그림자 사용)

                  onTap: (int index) {
                    ref.read(pageIndexProvider.notifier).state = index;
                  },
                ),
              ),
            ),

            // 2. 구분선 (아주 연하게)
            Container(height: 1, color: Colors.grey.shade100),

            // 3. 📺 배너 광고 영역
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                // 광고 배경을 아주 연한 회색으로 주어 탭바와 구분감 형성 (선택 사항)
                color: Colors.grey.shade50,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: const WBannerAd(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}