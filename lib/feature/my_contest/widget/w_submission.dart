import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/provider/auth_notifier.dart';
import '../provider/entry_provider.dart';

// 참가 신청 폼: 사진 선택 및 SNS ID 입력을 처리하고 EntryNotifier에 제출합니다.
class EntrySubmissionForm extends ConsumerStatefulWidget {
  const EntrySubmissionForm({super.key});

  @override
  ConsumerState<EntrySubmissionForm> createState() => _EntrySubmissionFormState();
}

class _EntrySubmissionFormState extends ConsumerState<EntrySubmissionForm> {
  final TextEditingController _snsController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _snsController.dispose();
    super.dispose();
  }

  // 갤러리에서 이미지 선택 (광고 미구현 상태)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // 💡 참고: 사진 수정 시 광고 시청 조건은 추후 구현 필요
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 참가 신청 제출 로직
  Future<void> _submitEntry() async {
    if (_selectedImage == null) {
      _showSnackbar('사진을 선택해 주세요.');
      return;
    }
    if (_snsController.text.isEmpty) {
      _showSnackbar('홍보용 SNS ID를 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(entryProvider.notifier).submitNewEntry(
        photo: _selectedImage!,
        snsId: _snsController.text.trim(),
      );
      // 성공 시 EntryNotifier가 상태를 업데이트하여 MyEntryScreen이 자동으로 전환됨
      _showSnackbar('참가 신청이 완료되었습니다! 관리자 승인을 기다려주세요.');
    } catch (e) {
      _showSnackbar('신청 실패: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 정보 (지역 설정 확인용)
    final user = ref.watch(authProvider).user;
    final isRegionSet = user != null && user.region != 'NotSet';

    if (!isRegionSet) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            '참가 신청을 위해 마이페이지에서 지역 설정을 완료해 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '이번 주차 베스트 픽에 도전하세요!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 1. 사진 선택 영역
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('셀카 선택 (갤러리)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. SNS ID 입력
          TextFormField(
            controller: _snsController,
            decoration: const InputDecoration(
              labelText: '홍보용 SNS ID (필수)',
              hintText: '@instagram_id 또는 my_blog',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
          ),
          const SizedBox(height: 30),

          // 3. 신청 버튼
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitEntry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              '참가 신청 제출하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '* 등록된 사진은 관리자 수동 승인을 거쳐야 투표 대상에 노출됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}