import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';



/// 버튼 연타 제어용 프로바이더
class DebounceNotifier extends StateNotifier<bool> {
  DebounceNotifier() : super(false);

  // 1000 milliseconds = 1 second
  void startDebounce(int milliseconds) {
    state = true;
    Timer( Duration(milliseconds: milliseconds), () {
      state = false;
    });
  }
}

final debounceProvider = StateNotifierProvider<DebounceNotifier, bool>((ref) {
  return DebounceNotifier();
}, name: 'DebounceProvider');