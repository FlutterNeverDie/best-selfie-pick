// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';

import '../champion/s_champion.dart';
import '../my_contest/s_my_contest.dart';
import '../my_page/s_my_page.dart';
import '../rank/s_ranking.dart';
// TODO: 실제 화면 파일 import

final pageIndexProvider = StateProvider<int>((ref) => 2);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static final routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 바텀 네비게이션 바에 매핑될 화면 리스트 (인덱스 순서 0, 1, 2, 3)
  static const List<Widget> _widgetOptions = <Widget>[
    ChampionScreen(), // 0: 챔피언
    RankingScreen(), // 1: 랭킹/투표 (초기 화면)
    MyEntryScreen(), // 2: 내 참가
    MyPageScreen(), // 3: 마이페이지
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Riverpod을 통해 현재 선택된 인덱스를 watch
    final pageIndex = ref.watch(pageIndexProvider);

    // 2. MainScreen처럼 List<TabItem> 구조로 바텀바 항목 정의 (AppBarTitle 용도)
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.emoji_events, 'label': '챔피언'},
      {'icon': Icons.show_chart, 'label': '랭킹'},
      {'icon': Icons.image, 'label': '내 참가'},
      {'icon': Icons.person, 'label': '마이페이지'},
    ];

    return Scaffold(
      // IndexedStack을 사용하여 상태가 유지되는 화면 전환 구현
      body: IndexedStack(
        index: pageIndex,
        children: _widgetOptions,
      ),

      // BottomNavigationBar를 사용하여 인덱스 변경 처리
      bottomNavigationBar: BottomNavigationBar(
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item['icon']),
                  label: item['label'],
                ))
            .toList(),

        currentIndex: pageIndex,
        // Riverpod이 제공하는 인덱스 사용
        selectedItemColor: AppColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        // 3. 탭 클릭 시 Riverpod StateProvider의 값을 변경
        onTap: (int index) {
          // notifier를 사용하여 pageIndexProvider의 상태를 업데이트
          ref.read(pageIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
