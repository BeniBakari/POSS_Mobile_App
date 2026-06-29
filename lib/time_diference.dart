import 'package:intl/intl.dart';

class TimeDifference {
  static int hours(String date) {
    final now = DateTime.now();
    final formattedDate = DateTime.parse(date);
    return now.difference(formattedDate).inHours;
  }

  static String getDate(String date) {
    final now = DateTime.now();
    final formattedDate = DateTime.parse(date);

    // Check if it's the same calendar day
    final isToday = now.year == formattedDate.year &&
        now.month == formattedDate.month &&
        now.day == formattedDate.day;

    final difference = now.difference(formattedDate).inDays;
    final timeString =
        "${formattedDate.hour}:${formattedDate.minute.toString().padLeft(2, '0')}";

    if (isToday) {
      return "$timeString , today";
    } else if (difference == 1) {
      return "One day ago, $timeString";
    } else {
      final dateString = DateFormat('dd-MM-yyyy').format(formattedDate);
      return "$timeString , $dateString";
    }
  }
}

