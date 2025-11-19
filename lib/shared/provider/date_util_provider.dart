import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/shared/interface/i_date_util.dart';

final dateUtilProvider = Provider<IDateUtil>((ref) {
  return DateUtilImpl();
});
