import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:selfie_pick/core/theme/colors/app_color.dart';
import '../../../core/data/area.data.dart';

class RegionSelectionDialog extends StatefulWidget {
  final String? initialRegion;

  const RegionSelectionDialog({super.key, this.initialRegion});

  @override
  State<RegionSelectionDialog> createState() => _RegionSelectionDialogState();
}

class _RegionSelectionDialogState extends State<RegionSelectionDialog> {
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '거주 지역 선택',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '현재 거주하고 계신 지역을 선택해주세요.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),

            // 지역 그리드
            SizedBox(
              height: 300.h,
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

            // 버튼 영역
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(), // 그냥 닫기 (null 반환)
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
                    onPressed: _selectedRegion == null
                        ? null
                        : () {
                      // 💡 선택한 지역을 가지고 돌아감
                      context.pop(_selectedRegion);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
                    ),
                    child: const Text('선택 완료', style: TextStyle(fontWeight: FontWeight.bold)),
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