import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatWhen(DateTime dateTime) {
    final now = DateTime.now();
    final sameDay =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTom =
        dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;

    final timeStr = DateFormat('h:mm a').format(dateTime);

    if (sameDay) return 'Today · $timeStr';
    if (isTom) return 'Tomorrow · $timeStr';

    final dateStr = DateFormat('EEE, MMM d').format(dateTime);
    return '$dateStr · $timeStr';
  }

  static String formatChatDate(DateTime dateTime) {
    final now = DateTime.now();
    final sameDay =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    if (sameDay) return DateFormat('h:mm a').format(dateTime);
    return DateFormat('MMM d').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
