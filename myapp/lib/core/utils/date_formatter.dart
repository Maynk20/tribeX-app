import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats date for activity display, e.g. "Today · 5:30 PM" or "Sat, Oct 10 · 6:00 PM".
  /// Strictly converts [dateTime] to the device's local timezone.
  static String formatWhen(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTom =
        local.year == tomorrow.year &&
        local.month == tomorrow.month &&
        local.day == tomorrow.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;

    final timeStr = DateFormat('h:mm a').format(local);

    if (sameDay) return 'Today · $timeStr';
    if (isTom) return 'Tomorrow · $timeStr';
    if (isYesterday) return 'Yesterday · $timeStr';

    final dateStr = DateFormat('EEE, MMM d').format(local);
    return '$dateStr · $timeStr';
  }

  /// Formats date for conversation list preview:
  /// - Today: "5:30 PM"
  /// - Yesterday: "Yesterday"
  /// - This year: "Oct 9"
  /// - Prior year: "Oct 9, 2025"
  static String formatChatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (sameDay) return DateFormat('h:mm a').format(local);

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;

    if (isYesterday) return 'Yesterday';

    if (local.year == now.year) {
      return DateFormat('MMM d').format(local);
    }
    return DateFormat('MMM d, yyyy').format(local);
  }

  /// Formats time in device's local timezone (e.g. "5:30 PM").
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  /// Formats relative time elapsed (e.g. "just now", "5m ago", "2h ago").
  static String timeAgo(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.isNegative || diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(local);
  }

  /// Formats a full calendar day boundary separator for chat screens:
  /// - "Today"
  /// - "Yesterday"
  /// - "Friday, October 9" (if current year)
  /// - "October 9, 2025" (if previous years)
  static String formatDateSeparator(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(msgDate).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    if (local.year == now.year) {
      return DateFormat('EEEE, MMMM d').format(local);
    }
    return DateFormat('MMMM d, yyyy').format(local);
  }

  /// Determines if two [DateTime] instances occur on the same calendar day in local time.
  static bool isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  /// Safely parses a dynamic server timestamp (ISO-8601 string, millis num) into a UTC [DateTime].
  /// Accepts an optional [fallback] (defaults to current UTC time if null or invalid).
  static DateTime parseServerDateTime(dynamic val, {DateTime? fallback}) {
    final defaultFallback = (fallback ?? DateTime.now()).toUtc();
    if (val == null) return defaultFallback;
    if (val is DateTime) return val.toUtc();
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
    }
    final str = val.toString().trim();
    if (str.isEmpty) return defaultFallback;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return defaultFallback;
    return parsed.toUtc();
  }
}
