import '../models/activity.dart';
import '../models/expense.dart';
import '../models/join_request.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/poll.dart';
import '../models/user_profile.dart';

/// Clean static configuration constants (no fake backend data).
class MockData {
  MockData._();

  static UserProfile? get currentUser => null;

  static List<Activity> getInitialActivities() => [];
  static List<JoinRequest> getInitialJoinRequests() => [];
  static List<Message> getInitialMessages() => [];
  static List<Expense> getInitialExpenses() => [];
  static List<Poll> getInitialPolls() => [];
  static List<NotificationItem> getInitialNotifications() => [];
}
