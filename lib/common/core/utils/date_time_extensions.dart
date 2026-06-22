import 'package:intl/intl.dart';

extension BangladeshTimeExtension on DateTime {
  DateTime toBangladeshTime() {
    return toLocal();
  }

  DateTime toUtcFromBangladesh() {
    return toUtc();
  }

  String formatBDT(String pattern) {
    return DateFormat(pattern).format(toLocal());
  }
}
