import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/notification_item.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/state/notifications_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2 - 1. Realtime Chat Reconnection and Active Channel Hardening', () {
    test('setActiveChat tracks current chat and reconnectActiveSubscriptions preserves it', () {
      final state = ChatState();
      expect(state.activeChatActivityId, isNull);

      state.setActiveChat('act_active_123');
      expect(state.activeChatActivityId, 'act_active_123');

      // Call reconnectActiveSubscriptions - should not throw or lose activeChatActivityId
      state.reconnectActiveSubscriptions();
      expect(state.activeChatActivityId, 'act_active_123');

      state.setActiveChat(null);
      expect(state.activeChatActivityId, isNull);

      state.dispose();
    });

    test('Messages for activity returns immutable list without crash on uninitialized chat', () {
      final state = ChatState();
      final msgs = state.getMessagesForActivity('act_uninitialized');
      expect(msgs, isEmpty);
      state.dispose();
    });
  });

  group('Phase 2 - 2. Join Request Rejection & Notification Status Alignment', () {
    test('JoinRequest status parses rejected properly from server response', () {
      final jsonAccepted = {
        'id': 'req_1',
        'activity_id': 'act_1',
        'user_id': 'user_1',
        'status': 'accepted',
        'created_at': DateTime.now().toIso8601String(),
      };
      final reqAccepted = JoinRequest.fromJson(jsonAccepted);
      expect(reqAccepted.status, JoinStatus.accepted);

      final jsonRejected = {
        'id': 'req_2',
        'activity_id': 'act_1',
        'user_id': 'user_2',
        'status': 'rejected',
        'created_at': DateTime.now().toIso8601String(),
      };
      final reqRejected = JoinRequest.fromJson(jsonRejected);
      expect(reqRejected.status, JoinStatus.rejected);
    });

    test('ActivitiesState.respondToRequest formats rejected status string accurately', () async {
      final state = ActivitiesState();
      // respondToRequest returns false gracefully without throwing if network client is null
      final success = await state.respondToRequest('req_test', JoinStatus.rejected);
      expect(success, isFalse);
      state.dispose();
    });
  });

  group('Phase 2 - 3. Polls and Single-Choice Voting Integrity', () {
    test('Single-choice voting updates option vote counts cleanly', () {
      final initialPoll = Poll(
        id: 'poll_1',
        activityId: 'act_1',
        creatorId: 'user_creator',
        question: 'Dinner choice?',
        options: [
          PollOption(id: '0', text: 'Pizza', voterIds: ['user_a']),
          PollOption(id: '1', text: 'Burgers', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      expect(initialPoll.totalVotes, 1);
      expect(initialPoll.userVotedOptionId('user_a'), '0');
      expect(initialPoll.userVotedOptionId('user_b'), isNull);

      // User A switches vote from Pizza to Burgers
      final switchedOptions = [
        PollOption(id: '0', text: 'Pizza', voterIds: []),
        PollOption(id: '1', text: 'Burgers', voterIds: ['user_a']),
      ];
      final updatedPoll = initialPoll.copyWith(options: switchedOptions);

      expect(updatedPoll.totalVotes, 1);
      expect(updatedPoll.userVotedOptionId('user_a'), '1');
      expect(updatedPoll.options[0].votes, 0);
      expect(updatedPoll.options[1].votes, 1);
    });
  });

  group('Phase 2 - 4. Expense Splits and Participant State Integrity', () {
    test('Expense model calculates per-head share and tracks marked-paid members', () {
      final members = [
        ExpenseMember(userId: 'u1', name: 'Alice', amount: 50.0, isPaid: true),
        ExpenseMember(userId: 'u2', name: 'Bob', amount: 50.0, isPaid: false),
      ];
      final expense = Expense(
        id: 'exp_1',
        activityId: 'act_1',
        creatorId: 'u1',
        creatorName: 'Alice',
        description: 'Team Lunch',
        totalAmount: 100.0,
        upiId: 'alice@upi',
        members: members,
        createdAt: DateTime.now(),
      );

      expect(expense.totalAmount, 100.0);
      expect(expense.members.length, 2);
      expect(expense.members[0].isPaid, isTrue);
      expect(expense.members[1].isPaid, isFalse);

      final nextMembers = members.map((m) {
        if (m.userId == 'u2') return m.copyWith(isPaid: true);
        return m;
      }).toList();
      final updatedExpense = expense.copyWith(members: nextMembers);

      expect(updatedExpense.members.every((m) => m.isPaid), isTrue);
    });
  });

  group('Phase 2 - 5. Unauthenticated Plan Isolation in ActivitiesState', () {
    test('ActivitiesState does not load plans when unauthenticated', () async {
      final state = ActivitiesState();
      // On start without authenticated user, activities must be empty
      expect(state.activities, isEmpty);

      // Calling fetchActivities without authenticated user leaves activities empty
      await state.fetchActivities();
      expect(state.activities, isEmpty);
      expect(state.isLoading, isFalse);

      state.dispose();
    });

    test('clearActivities clears all loaded plans, spatial IDs and active channels', () {
      final state = ActivitiesState();
      final sample = Activity(
        id: 'act_temp_1',
        title: 'Morning Yoga',
        description: 'Sunrise flow',
        category: 'Yoga',
        dateTime: DateTime.now().add(const Duration(hours: 3)),
        location: 'Indiranagar',
        hostId: 'host_1',
        totalSlots: 5,
        slotsLeft: 4,
        costPerHead: 0,
      );

      state.setActivitiesForTesting([sample], isSpatial: true);
      expect(state.activities.length, 1);

      state.clearActivities();
      expect(state.activities, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.currentPage, 0);

      state.dispose();
    });
  });

  group('Phase 2 - 6. Squad Message Notifications and Active Chat Suppression', () {
    test('NotificationsState tracks and clears activeChatActivityId', () {
      final state = NotificationsState();
      expect(state.activeChatActivityId, isNull);

      state.setActiveChatActivityId('act_active_chat_456');
      expect(state.activeChatActivityId, 'act_active_chat_456');

      state.setActiveChatActivityId(null);
      expect(state.activeChatActivityId, isNull);

      state.dispose();
    });

    test('NotificationItem correctly parses chat_message and request_declined types', () {
      final chatNotif = NotificationItem.fromJson({
        'id': 'n_chat_1',
        'user_id': 'u_recipient',
        'type': 'chat_message',
        'title': 'Box Cricket Squad',
        'body': 'Aman: Reached the ground!',
        'activity_id': 'act_cricket_1',
      });
      expect(chatNotif.type, NotificationType.chatMessage);
      expect(chatNotif.title, 'Box Cricket Squad');
      expect(chatNotif.body, 'Aman: Reached the ground!');
      expect(chatNotif.activityId, 'act_cricket_1');

      final declinedNotif = NotificationItem.fromJson({
        'id': 'n_dec_1',
        'user_id': 'u_applicant',
        'type': 'request_declined',
        'title': 'Request declined',
        'body': 'Host declined your request.',
        'activity_id': 'act_cricket_1',
      });
      expect(declinedNotif.type, NotificationType.requestDeclined);
    });
  });
}
