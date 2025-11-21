import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/my_entry/provider/entry_provider.dart';
import '../../../core/theme/colors/app_color.dart';
import '../../../shared/widget/w_cached_image.dart';
import '../model/m_entry.dart';

class WEntryApprovedView extends ConsumerWidget {
  final EntryModel entry;

  const WEntryApprovedView({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEntryAsync = ref.watch(entryProvider);
    final EntryModel currentEntry = latestEntryAsync.value ?? entry;

    // 상태 확인
    final isVotingActive = currentEntry.status == 'approved';

    // 💡 수정됨: SingleChildScrollView 제거! (부모 위젯이 스크롤을 담당함)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        children: [
          // 1. 🏷️ 상태 배지 & 지역 정보 (카드 헤더)
          _buildHeader(context, isVotingActive, currentEntry),

          SizedBox(height: 24.h),

          // 2. 🖼️ 메인 포토 카드 (그림자 & 라운딩 강화)
          _buildPhotoCard(context, currentEntry),

          SizedBox(height: 32.h),

          // 3. 📊 실시간 득표 대시보드 (디자인 개선)
          _buildVoteDashboard(context, currentEntry),

          SizedBox(height: 40.h),

          // 4. ℹ️ 하단 안내 문구
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColor.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20.w, color: Colors.grey),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "최종 순위는 매주 토요일 자정(00:00)\n챔피언 탭에서 발표됩니다.",
                    style: TextStyle(color: Colors.grey[700], fontSize: 13.sp, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ 헤더: 상태 배지와 지역/주차 정보
  Widget _buildHeader(BuildContext context, bool isVotingActive, EntryModel entry) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.weekKey}차',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              entry.regionCity,
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isVotingActive ? AppColor.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.w),
            border: Border.all(
              color: isVotingActive ? AppColor.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isVotingActive ? Icons.whatshot : Icons.lock,
                size: 18.w,
                color: isVotingActive ? AppColor.primary : Colors.grey,
              ),
              SizedBox(width: 6.w),
              Text(
                isVotingActive ? "투표 진행 중" : "비공개",
                style: TextStyle(
                  color: isVotingActive ? AppColor.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🖼️ 포토 카드: 그림자와 라운딩으로 고급스럽게
// 🖼️ 포토 카드: SizedBox로 높이를 고정하여 Stack 계산 오류 방지
  Widget _buildPhotoCard(BuildContext context, EntryModel entry) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.w),
        child: SizedBox(
          height: 380.h, // 💡 Stack의 높이를 여기서 명시적으로 고정합니다.
          width: double.infinity,
          child: Stack(
            children: [
              // 1. 이미지: Positioned.fill로 꽉 채웁니다.
              Positioned.fill(
                child: WCachedImage(
                  imageUrl: entry.photoUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // 2. 하단 그라데이션: Positioned로 위치 고정
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 100.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                ),
              ),

              // 3. SNS ID 텍스트: Positioned로 위치 고정
              Positioned(
                left: 0,
                right: 0,
                bottom: 20.h,
                child: Center(
                  child: Text(
                    '@${entry.snsId}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 투표 현황 대시보드
  Widget _buildVoteDashboard(BuildContext context, EntryModel entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '실시간 득표 현황',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            _buildStatCard(context, '금메달', '5점', entry.goldVotes, const Color(0xFFFFD700), Icons.emoji_events),
            SizedBox(width: 12.w),
            _buildStatCard(context, '은메달', '3점', entry.silverVotes, const Color(0xFFC0C0C0), Icons.emoji_events),
            SizedBox(width: 12.w),
            _buildStatCard(context, '동메달', '1점', entry.bronzeVotes, const Color(0xFFCD7F32), Icons.emoji_events),
          ],
        ),
      ],
    );
  }

  // 🃏 개별 통계 카드
  Widget _buildStatCard(BuildContext context, String title, String sub, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: AppColor.lightGrey.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.w),
            SizedBox(height: 8.h),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(title, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
            Text('($sub)', style: TextStyle(fontSize: 10.sp, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}