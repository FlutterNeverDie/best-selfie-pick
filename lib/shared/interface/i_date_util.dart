// i_date_util.dart
abstract class IDateUtil {
  // 현재 시간을 기준으로 Contest Week Key를 반환합니다.
  String getContestWeekKey(DateTime date);

  String getLastWeekKey(DateTime date);
}

// date_util_impl.dart
class DateUtilImpl implements IDateUtil {
  // 매년 1월 1일을 기준으로 현재 날짜가 몇 번째 연간 누적 회차에 속하는지 계산합니다.
  @override
  String getContestWeekKey(DateTime date) {
    // 1. 해당 연도의 첫 번째 날 (1월 1일)을 구합니다.
    final startOfYear = DateTime(date.year, 1, 1);

    // 2. 현재 날짜와 연초와의 차이를 일(Day) 단위로 구합니다.
    final daysSinceYearStart = date.difference(startOfYear).inDays;

    // 3. 주차 번호를 계산합니다. (일 수 / 7 + 1)
    // 저희의 콘테스트는 토요일 00:00에 시작하는 '주간' 대회이므로,
    // 일 수 기반으로 연간 누적 회차를 사용합니다.
    final weekNumber = (daysSinceYearStart / 7).floor() + 1;

    // YYYY-회차 형태로 반환합니다 (예: 2025-15)
    return '${date.year}-$weekNumber';
  }

  @override

  String getLastWeekKey(DateTime date) {
    // 7일을 뺀 날짜를 기준으로 회차 키를 계산합니다.
    final lastWeekDate = date.subtract(const Duration(days: 7));
    return getContestWeekKey(lastWeekDate);
  }
}