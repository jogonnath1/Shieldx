import 'package:intl/intl.dart';

extension BangladeshTimeExtension on DateTime {
  /// Converts the DateTime to Bangladesh Standard Time (UTC+6) by using local timezone.
  DateTime toBangladeshTime() {
    return toLocal();
  }

  /// Converts a local DateTime back to UTC.
  DateTime toUtcFromBangladesh() {
    return toUtc();
  }

  /// Formats the DateTime as local using DateFormat.
  String formatBDT(String pattern) {
    return DateFormat(pattern).format(toLocal());
  }
}
