import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/colors/app_color.dart';

class NoticeScreen extends ConsumerWidget {
  static const String routeName = '/notice';
  const NoticeScreen({super.key});
  // 하드코딩된 공지사항 데이터
  final List<Map<String, String>> notices = const [
    {
      'title': '앱 핵심 컨셉 및 운영 주기 안내',
      'content': '''
앱은 지역별 독립 콘테스트로 운영됩니다. 사용자는 현재 마이페이지에 설정된 지역의 콘테스트에만 참가 및 투표가 가능합니다.

1. 주간 운영 사이클
- 시작: 매주 토요일 00:00 (자정)에 새로운 회차가 시작됩니다.
- 마감: 다음 주 금요일 23:59:59에 투표가 마감됩니다.
- 정산/결과 발표: 해당 주차 마감 직후 자동 정산되며, 토요일 00:00에 챔피언 탭에서 우승자가 발표됩니다.
'''
    },
    {
      'title': '참가 등록 및 승인 절차',
      'content': '''
1. 참가 자격 및 제한: 누구나 참가 가능하며, 오직 하나의 지역에만 참가할 수 있습니다.
- 참가 신청 시, 등록된 사진은 즉시 '승인 대기중' 상태로 반영됩니다.

2. 관리자 승인: 등록된 사진은 관리자 수동 승인을 거쳐야 투표 대상이 됩니다.
- 승인 완료 시 현재 진행 중인 회차의 투표 대상 목록에 즉시 노출됩니다.
'''
    },
    {
      'title': '투표 규칙 및 제약 사항',
      'content': '''
1. 투표 제한: 사용자는 해당 주차에 지역당 1회 투표만 가능합니다.
- 예: 이번 주차에 성남시에 투표했다면, 지역을 바꾸어 안양시에도 별도로 1회 투표가 가능합니다.

2. 투표 방식 및 점수 부여:
- 투표는 금, 은, 동 세 개의 순위 픽을 선택합니다.
- 금(Gold) 선택 시: 5점 부여
- 은(Silver) 선택 시: 3점 부여
- 동(Bronze) 선택 시: 1점 부여

3. 랭킹 기준: 
- 투표 종료 후, 이 가중치 점수를 합산하여 총 점수가 가장 높은 순서로 베스트 픽을 선정합니다.
'''
    },
    {
      'title': '지역 변경 및 데이터 종속성',
      'content': '''
1. 지역 변경: 지역 설정은 마이페이지에서만 변경 가능합니다.
- 지역을 변경하면 챔피언 탭, 랭킹 탭, 참가 탭의 모든 조회 기준이 즉시 변경됩니다.

2. 마감 후 처리: 지난 회차에 참가했던 기록은 새로운 회차가 시작되는 순간 자동으로 '미참가 상태'로 초기화되어, 사용자는 다음 회차 신청을 할 수 있습니다..
'''
    },
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 이용 안내 및 공지사항'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱 사용 전 꼭 확인해주세요',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColor.primary),
            ),
            SizedBox(height: 20.h),

            // 공지사항 목록 렌더링
            ...notices.map((notice) {
              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${notice['title']}',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColor.black),
                    ),
                    Divider(height: 10.h, color: AppColor.lightGrey),
                    Text(
                      '${notice['content']}',
                      style: TextStyle(fontSize: 14.sp, height: 1.6),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}