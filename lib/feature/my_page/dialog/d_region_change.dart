import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import 'package:selfie_pick/feature/auth/provider/auth_notifier.dart';

import '../../../core/data/area.data.dart';

class RegionChangeDialog extends ConsumerStatefulWidget {
  const RegionChangeDialog({super.key});

  @override
  ConsumerState<RegionChangeDialog> createState() => _RegionChangeDialogState();
}

class _RegionChangeDialogState extends ConsumerState<RegionChangeDialog> {
  String? _selectedRegion;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // 현재 설정된 지역을 초기 선택값으로
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null && currentUser.region != 'NotSet') {
      _selectedRegion = currentUser.region;
    }
  }

  Future<void> _confirmChange() async {
    if (_selectedRegion == null) return;

    // -------------------------------------------------------
    // TODO: 여기에 나중에 보상형 광고 로직 추가
    // -------------------------------------------------------

    setState(() => _isUpdating = true);

    try {
      await ref.read(authProvider.notifier).updateRegion(_selectedRegion!);

      if (mounted) {
        context.pop(); // 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지역이 $_selectedRegion(으)로 변경되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
          children: [
            // 1. 타이틀
            Text(
              '활동 지역 변경',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '변경 시 각 탭을 새로고침 해주세요.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),

            // 2. 지역 그리드 (높이 제한)
            SizedBox(
              height: 300.h, // 다이얼로그가 너무 길어지지 않게 고정 높이 사용
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.w,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 2.2,
                ),
                itemCount: areasGlobalList.length,
                itemBuilder: (context, index) {
                  final region = areasGlobalList[index];
                  final isSelected = _selectedRegion == region;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.w),
                        border: Border.all(
                          color: isSelected ? AppColor.primary : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        region,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 24.h),

            // 3. 버튼 영역
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isUpdating || _selectedRegion == null)
                        ? null
                        : _confirmChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
                    ),
                    child: _isUpdating
                        ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('변경 완료', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}