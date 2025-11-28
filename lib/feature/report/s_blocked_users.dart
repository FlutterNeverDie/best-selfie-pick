import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';
import 'package:selfie_pick/feature/report/provider/report_provider.dart';
import 'package:selfie_pick/shared/dialog/w_custom_confirm_dialog.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용

// 💡 차단 내역 모델 (이 파일 내부에서만 사용)
class BlockedHistoryItem {
  final String uid;
  final String snsId;
  final String channel;
  final String weekKey;
  final DateTime? blockedAt;

  BlockedHistoryItem({
    required this.uid,
    required this.snsId,
    required this.channel,
    required this.weekKey,
    this.blockedAt,
  });

  factory BlockedHistoryItem.fromMap(Map<String, dynamic> map) {
    return BlockedHistoryItem(
      uid: map['uid'] as String? ?? '',
      snsId: map['snsId'] as String? ?? '알 수 없음',
      channel: map['channel'] as String? ?? '',
      weekKey: map['weekKey'] as String? ?? '',
      blockedAt: (map['blockedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// 💡 차단 내역(서브 컬렉션)을 가져오는 Provider
final blockedHistoryProvider = FutureProvider.autoDispose<List<BlockedHistoryItem>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  try {
    // users/{uid}/blocked_history 컬렉션 조회
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('blocked_history')
        .orderBy('blockedAt', descending: true) // 최신순 정렬
        .get();

    return snapshot.docs.map((doc) => BlockedHistoryItem.fromMap(doc.data())).toList();
  } catch (e) {
    return [];
  }
}, name: 'blockedHistoryProvider');

class BlockedUsersScreen extends ConsumerWidget {
  static const String routeName = '/blocked_users_screen';

  const BlockedUsersScreen({super.key});

  // 차단 해제 핸들러
  void _handleUnblock(BuildContext context, WidgetRef ref, BlockedHistoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => WCustomConfirmDialog(
        title: '차단 해제',
        content: '@${item.snsId} 님을 차단 해제하시겠습니까?\n이제 랭킹에서 이 분의 사진이 다시 보입니다.',
        confirmText: '해제하기',
        cancelText: '취소',
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(reportProvider.notifier).unblockUser(item.uid);

        // 💡 리스트 새로고침
        ref.invalidate(blockedHistoryProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('차단이 해제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(blockedHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('차단 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('정보를 불러오는데 실패했습니다.')),
        data: (blockedItems) {
          if (blockedItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            itemCount: blockedItems.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return _buildBlockedUserItem(context, ref, blockedItems[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 60.w, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            '차단한 사용자가 없습니다.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserItem(BuildContext context, WidgetRef ref, BlockedHistoryItem item) {
    // 날짜 포맷팅 (예: 2025.11.28)
    final dateStr = item.blockedAt != null
        ? DateFormat('yyyy.MM.dd').format(item.blockedAt!)
        : '차단일 정보 없음';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 프로필 아바타 (회색조 처리)
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.person_off_rounded, color: Colors.grey.shade400, size: 24.w),
          ),
          SizedBox(width: 16.w),

          // 2. 유저 정보 (스냅샷 기반)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SNS ID
                Text(
                  '@${item.snsId}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                // 채널 & 주차 & 차단일
                Wrap(
                  spacing: 6.w,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildTag(item.channel, Colors.blue.shade50, Colors.blue.shade700),
                    Text(
                      '|',
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 10.sp),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. 차단 해제 버튼
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () => _handleUnblock(context, ref, item),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.w),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
              ),
            ),
            child: Text(
              '차단 해제',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}