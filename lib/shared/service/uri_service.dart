// shared/util/url_launcher_util.dart
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtil {
  static Future<void> launch(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    // http나 https가 없으면 붙여주는 센스 (사용자가 그냥 www... 만 입력했을 경우 대비)
    String finalUrl = urlString;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    final Uri uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication); // 외부 브라우저로 열기
    } else {
      // 에러 처리 (토스트 메시지 등)
      print('Could not launch $finalUrl');
    }
  }
}