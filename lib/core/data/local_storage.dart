import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  late SharedPreferences _prefs;

  // 비공개 생성자
  LocalStorage._internal();

  // 싱글턴 인스턴스 접근자
  static LocalStorage get instance => _instance;

  // SharedPreferences 초기화 메소드
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // SharedPreferences에 문자열 쓰기 메소드
  Future<void> writeString({required String key, required String value}) async {
    await _prefs.setString(key, value);
  }

  // int
  Future<void> writeInt({required String key, required int value}) async {
    await _prefs.setInt(key, value);
  }

  //int read
  Future<int?> readInt({required String key}) async {
    return _prefs.getInt(key);
  }

  // SharedPreferences에서 문자열 읽기 메소드
  Future<String?> readString({required String key}) async {
    return _prefs.getString(key);
  }

  // SharedPreferences에 불리언 쓰기 메소드
  Future<void> writeBool({required String key, required bool value}) async {
    await _prefs.setBool(key, value);
  }

  // SharedPreferences에서 불리언 읽기 메소드
  Future<bool?> readBool({required String key}) async {
    return _prefs.getBool(key);
  }

  // SharedPreferences에서 특정 키 삭제 메소드
  Future<void> delete({required String key}) async {
    await _prefs.remove(key);
  }

  // SharedPreferences에서 모든 데이터 삭제 메소드
  Future<void> clear() async {
    await _prefs.clear();
  }

  // SharedPreferences에 여러 문자열 값을 쓰기 메소드
  Future<void> writeMultiple(Map<String, String> data) async {
    for (var entry in data.entries) {
      await _prefs.setString(entry.key, entry.value);
    }
  }

}

// 싱글턴이 사용되기 전에 초기화되도록 보장하는 함수
Future<void> initializeLocalStorage() async {
  await LocalStorage.instance.init();
}
