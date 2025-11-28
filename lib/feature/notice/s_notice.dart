import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/colors/app_color.dart';

class NoticeScreen extends ConsumerWidget {
  static const String routeName = '/notice';
  const NoticeScreen({super.key});

  // 💡 데이터 구조를 확장하여 아이콘(icon) 정보도 함께 관리합니다.
  final List<Map<String, dynamic>> notices = const [
    {
      'icon': Icons.timer_outlined, // 운영 주기 아이콘
      'title': '앱 핵심 컨셉 및 운영 주기',
      'content': '''
💡 채널별 독립 콘테스트
사용자는 현재 마이페이지에 설정된 채의 콘테스트에만 참가 및 투표가 가능합니다.

📅 주간 운영 사이클
• 시작: 매주 토요일 00:00 (자정)에 새로운 회차가 시작됩니다.
• 마감: 다음 주 금요일 23:59:59에 투표가 마감됩니다.
• 결과 발표: 마감 직후 정산되어 토요일 00:00에 챔피언 탭에서 우승자가 공개됩니다.
'''
    },
    {
      'icon': Icons.how_to_reg_outlined, // 참가/승인 아이콘
      'title': '참가 등록 및 승인 절차',
      'content': '''
👤 참가 자격
누구나 참가 가능하며, 여러 채널에 참가할 수 있습니다. 참가 신청 시, 사진은 즉시 '승인 대기중' 상태가 됩니다.
  
✅ 관리자 승인
등록된 사진은 관리자의 수동 승인을 거쳐야 투표 대상이 됩니다. 승인 완료 시 현재 진행 중인 회차의 투표 목록에 즉시 노출됩니다.
'''
    },
    {
      'icon': Icons.how_to_vote_outlined, // 투표 규칙 아이콘
      'title': '투표 규칙 및 점수 산정',
      'content': '''
🗳️ 투표 제한
사용자는 해당 주차에 채널당 1회 투표만 가능합니다. (채널을 변경하면 다른 채널에도 투표 가능)

🏆 점수 부여 방식
투표는 금, 은, 동 세 개의 순위 픽을 선택합니다.
• 🥇 금(Gold): 5점
• 🥈 은(Silver): 3점
• 🥉 동(Bronze): 1점

투표 종료 후, 이 점수를 합산하여 총점이 가장 높은 순서로 베스트 픽을 선정합니다.
'''
    },
    {
      'icon': Icons.map_outlined, // 채널/데이터 아이콘
      'title': '채널 변경 및 데이터 처리',
      'content': '''
🔄 채널 변경
채널 설정은 마이페이지에서만 변경 가능합니다. 채널을 변경하면 챔피언, 랭킹, 참가 탭의 모든 조회 기준이 즉시 변경됩니다.

🧹 마감 후 처리
지난 회차에 참가했던 기록은 새로운 회차가 시작되는 순간 자동으로 초기화되어, 다음 회차에 다시 신청할 수 있습니다.
'''
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 전체 배경 연한 회색
      appBar: AppBar(
        title: const Text('이용 안내 및 공지', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀 섹션
            Text(
              '앱 사용 전\n꼭 확인해주세요! 🧐',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '즐겁고 공정한 베스트픽을 위한 규칙입니다.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24.h),

            // 공지사항 리스트 (ExpansionTile 사용)
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // 스크롤은 부모에게 위임
              shrinkWrap: true,
              itemCount: notices.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final notice = notices[index];
                return _buildNoticeCard(notice);
              },
            ),

            SizedBox(height: 40.h),

            // 하단 문의 안내
            Center(
              child: Text(
                '더 궁금한 점이 있으신가요?\n[마이페이지 > 1:1 문의]를 이용해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400, height: 1.5),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // 🎨 아코디언 스타일의 공지사항 카드 위젯
  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ExpansionTile의 위아래 경계선을 없애기 위해 Theme 사용
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notice['icon'] as IconData,
              color: AppColor.primary,
              size: 20.w,
            ),
          ),
          title: Text(
            notice['title'] as String,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          iconColor: Colors.grey, // 펼쳐졌을 때 화살표 색상
          collapsedIconColor: Colors.grey, // 접혔을 때 화살표 색상
          children: [
            // 내용 텍스트
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Text(
                notice['content'] as String,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  height: 1.6, // 줄간격 여유있게
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}