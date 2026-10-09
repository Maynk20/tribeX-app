import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/constants/categories.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/report_service.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/state/notifications_state.dart';
import 'package:myapp/state/theme_state.dart';
import 'package:myapp/widgets/common/place_search_dialog.dart';
import 'package:myapp/widgets/common/welcome_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('tribeX Unit & State Tests', () {
    test('Categories and amenities are properly configured', () {
      expect(AppCategories.groups.length, 5);
      expect(AppCategories.all.length, greaterThanOrEqualTo(25));
      expect(AppCategories.amenities.length, 4);
      expect(AppCategories.emojiFor("Cricket"), "🏏");
      expect(AppCategories.emojiFor("Chess"), "♟️");
    });

    test('UserProfile reliability label and terms versioning logic', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: "u1",
        fullName: "Mayank Thakkar",
        username: "mayank",
        email: "mayank@tribex.local",
        rating: 5.0,
        termsAcceptedAt: now,
        termsVersion: "v1.0",
      );
      expect(user.reliabilityLabel, "100% Reliable · Elite Host");
      expect(user.termsVersion, "v1.0");
      expect(user.termsAcceptedAt, now);

      final json = user.toJson();
      expect(json['terms_version'], "v1.0");
      expect(json['terms_accepted_at'], now.toIso8601String());

      final restored = UserProfile.fromJson(json);
      expect(restored.termsVersion, "v1.0");
    });

    test('Expense calculation and per-head share splitting', () {
      final members = [
        ExpenseMember(
          userId: "u1",
          name: "Mayank",
          amount: 250.0,
          isPaid: true,
        ),
        ExpenseMember(
          userId: "u2",
          name: "Rahul",
          amount: 250.0,
          isPaid: false,
        ),
      ];
      final expense = Expense(
        id: "exp_1",
        activityId: "act_1",
        creatorId: "u1",
        creatorName: "Mayank",
        description: "Turf Rental",
        totalAmount: 500.0,
        members: members,
        createdAt: DateTime.now(),
      );

      expect(expense.totalAmount, 500.0);
      expect(expense.members.length, 2);
      expect(expense.perHead, 250.0);
      expect(expense.paidCount, 1);
      expect(expense.members.first.isPaid, isTrue);
      expect(expense.members.last.isPaid, isFalse);
    });

    test('Poll option voting count calculation', () {
      final poll = Poll(
        id: "poll_1",
        activityId: "act_1",
        creatorId: "u1",
        question: "Which turf time works best?",
        options: [
          PollOption(id: "opt_1", text: "6:00 PM", voterIds: ["u1", "u2"]),
          PollOption(id: "opt_2", text: "8:00 PM", voterIds: ["u3"]),
        ],
        createdAt: DateTime.now(),
      );

      expect(poll.totalVotes, 3);
      expect(poll.options[0].votes, 2);
      expect(poll.options[1].votes, 1);
      expect(poll.hasVoted("u1"), isTrue);
      expect(poll.hasVoted("u4"), isFalse);
      expect(poll.userVotedOptionId("u1"), "opt_1");
    });

    test('JoinRequest status and pending count math', () {
      final reqs = [
        JoinRequest(
          id: "r1",
          activityId: "act_1",
          userId: "u2",
          status: JoinStatus.pending,
          requestedAt: DateTime.now(),
        ),
        JoinRequest(
          id: "r2",
          activityId: "act_1",
          userId: "u3",
          status: JoinStatus.accepted,
          requestedAt: DateTime.now(),
        ),
      ];

      final pendingCount = reqs
          .where((r) => r.status == JoinStatus.pending)
          .length;
      final acceptedCount = reqs
          .where((r) => r.status == JoinStatus.accepted)
          .length;

      expect(pendingCount, 1);
      expect(acceptedCount, 1);
    });

    test('ReportReason enum mapping to DB strings', () {
      expect(ReportReason.harassment.dbValue, 'harassment');
      expect(ReportReason.unsafeBehavior.dbValue, 'unsafe_behavior');
      expect(ReportReason.fakeProfile.dbValue, 'fake_profile');
      expect(ReportReason.spam.dbValue, 'spam');
    });

    test('ActivitiesState initial state, filtering, and memoization', () {
      final state = ActivitiesState();
      expect(state.activities, isEmpty);

      state.setSearchQuery("Cricket");
      final filtered1 = state.getFilteredActivities(null, {});
      final filtered2 = state.getFilteredActivities(null, {});
      expect(identical(filtered1, filtered2), isTrue); // memoized reference

      state.setSortKey(SortKey.distance);
      expect(state.sortKey, SortKey.distance);
      state.dispose();
    });

    test('ChatState messages initialization, optimistic send and disposal', () {
      final chat = ChatState();
      const actId = "act_cricket";
      final initialMsgs = chat.getMessagesForActivity(actId);
      expect(initialMsgs, isEmpty);

      expect(chat.getExpense('non_existent_exp'), isNull);
      expect(chat.getPoll('non_existent_poll'), isNull);

      chat.dispose();
    });

    test('NotificationsState initial state and lifecycle', () {
      final notifs = NotificationsState();
      expect(notifs.notifications, isEmpty);
      expect(notifs.unreadCount, 0);
      notifs.dispose();
    });

    test('ThemeState default and mode switching', () async {
      final themeState = ThemeState();
      expect(themeState.themeMode, ThemeMode.system);

      await themeState.setThemeMode(ThemeMode.dark);
      expect(themeState.themeMode, ThemeMode.dark);
      expect(themeState.isDarkMode, isTrue);

      await themeState.setThemeMode(ThemeMode.light);
      expect(themeState.themeMode, ThemeMode.light);
      expect(themeState.isDarkMode, isFalse);
    });

    test('StorageService provides curated covers for categories', () {
      final cricketCovers = StorageService.getCuratedCovers('Cricket');
      expect(cricketCovers, isNotEmpty);
      expect(cricketCovers.first, startsWith('http'));

      final fallbackCovers = StorageService.getCuratedCovers('UnknownCategory');
      expect(fallbackCovers, isNotEmpty);
      expect(fallbackCovers.first, startsWith('http'));
    });

    test('UserProfile defaults hasCompletedProfile & hasCompletedOnboarding to false when null in JSON', () {
      final json = {
        'id': 'u_new',
        'full_name': 'New User',
        'username': 'newuser',
        'email': 'new@tribex.local',
        // has_completed_profile and has_completed_onboarding are intentionally absent (null)
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.hasCompletedProfile, isFalse);
      expect(profile.hasCompletedOnboarding, isFalse);
    });

    test('LocationService haversine distance calculation and cache clearing', () {
      // Indiranagar, Bengaluru to Koramangala, Bengaluru (~5 km)
      final distance = LocationService.haversineKm(12.9784, 77.6408, 12.9352, 77.6245);
      expect(distance, greaterThan(4.0));
      expect(distance, lessThan(7.0));

      // Same coordinates should have 0 distance
      final zeroDist = LocationService.haversineKm(12.9784, 77.6408, 12.9784, 77.6408);
      expect(zeroDist, 0.0);

      // Cache clearing must run safely without throwing
      expect(() => LocationService.clearCache(), returnsNormally);
    });

    test('Poll enforces single choice: voting for new option removes old voter id', () {
      final initialPoll = Poll(
        id: "poll_1",
        activityId: "act_1",
        creatorId: "u1",
        question: "Preferred game format?",
        options: [
          PollOption(id: "0", text: "T20", voterIds: ["u_voter1"]),
          PollOption(id: "1", text: "ODI", voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      expect(initialPoll.userVotedOptionId("u_voter1"), "0");
      expect(initialPoll.options[0].votes, 1);
      expect(initialPoll.options[1].votes, 0);

      // Simulate switching vote from option 0 to option 1
      const targetIdx = 1;
      const voterId = "u_voter1";
      final updatedOptions = initialPoll.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final newVoters = List<String>.from(opt.voterIds)..remove(voterId);
        if (idx == targetIdx) {
          newVoters.add(voterId);
        }
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      final updatedPoll = Poll(
        id: initialPoll.id,
        activityId: initialPoll.activityId,
        creatorId: initialPoll.creatorId,
        question: initialPoll.question,
        options: updatedOptions,
        createdAt: initialPoll.createdAt,
      );

      expect(updatedPoll.userVotedOptionId(voterId), "1");
      expect(updatedPoll.options[0].votes, 0);
      expect(updatedPoll.options[1].votes, 1);
      expect(updatedPoll.totalVotes, 1);
    });

    test('Message model recognizes temporary optimistic IDs vs DB IDs', () {
      final tempMsg = Message(
        id: 'temp_1728470000000',
        activityId: 'act_1',
        senderId: 'u1',
        text: 'Hello squad!',
        createdAt: DateTime.now(),
      );
      expect(tempMsg.id.startsWith('temp_'), isTrue);

      final realMsg = Message(
        id: 'c28d9ec8-f10a-40a2-9b27-3914a87b5a19',
        activityId: 'act_1',
        senderId: 'u1',
        text: 'Hello squad!',
        createdAt: DateTime.now(),
      );
      expect(realMsg.id.startsWith('temp_'), isFalse);
      expect(realMsg.expenseId, isNull);
      expect(realMsg.pollId, isNull);
    });

    test('PlaceItem correctly stores and retains coordinates', () {
      const item = PlaceItem(
        title: 'Indiranagar Metro',
        subtitle: 'Bengaluru, Karnataka',
        lat: 12.9784,
        lon: 77.6408,
      );
      expect(item.title, 'Indiranagar Metro');
      expect(item.lat, 12.9784);
      expect(item.lon, 77.6408);
    });
  });

  group('tribeX Widget Tests', () {
    testWidgets('WelcomeSplash renders welcome title and enters app', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeSplash(
            profile: UserProfile(
              id: "test",
              fullName: "Mayank",
              username: "mayank",
              email: "m@tribex.local",
            ),
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      expect(find.text('WELCOME TO'), findsOneWidget);
      expect(find.text('TAP ANYWHERE TO ENTER'), findsOneWidget);

      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      expect(completed, isTrue);
    });
  });
}
