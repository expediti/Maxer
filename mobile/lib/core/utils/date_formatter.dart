import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _standardDate = DateFormat('dd MMM yyyy');
  static final DateFormat _fullDateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');

  static String formatDate(DateTime? date) {
    if (date == null) return 'Not announced';
    return _standardDate.format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _fullDateTime.format(dateTime);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return 'N/A';
    return _monthYear.format(date);
  }

  /// Calculates days remaining to a deadline
  static String daysRemaining(DateTime? deadline) {
    if (deadline == null) return 'No deadline';
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      final hours = deadline.difference(now).inHours;
      if (hours <= 0) return 'Closes today';
      return '$hours hours left';
    } else if (difference == 1) {
      return '1 day left';
    } else {
      return '$difference days left';
    }
  }

  static String formatDeadline(DateTime? deadline) => daysRemaining(deadline);

  static bool isClosingSoon(DateTime? deadline, {int thresholdDays = 7}) {
    if (deadline == null) return false;
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff >= 0 && diff <= thresholdDays;
  }
}
