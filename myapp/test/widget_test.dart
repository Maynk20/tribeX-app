import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/constants/categories.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/report_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/widgets/common/welcome_splash.dart';

void main() {
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
        ExpenseMember(userId: "u1", name: "Mayank", amount: 250.0, isPaid: true),
        ExpenseMember(userId: "u2", name: "Rahul", amount: 250.0, isPaid: false),
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

      final pendingCount = reqs.where((r) => r.status == JoinStatus.pending).length;
      final acceptedCount = reqs.where((r) => r.status == JoinStatus.accepted).length;

      expect(pendingCount, 1);
      expect(acceptedCount, 1);
    });

    test('ReportReason enum mapping to DB strings', () {
      expect(ReportReason.harassment.dbValue, 'harassment');
      expect(ReportReason.unsafeBehavior.dbValue, 'unsafe_behavior');
      expect(ReportReason.fakeProfile.dbValue, 'fake_profile');
      expect(ReportReason.spam.dbValue, 'spam');
    });

    test('ActivitiesState initial state and filtering', () {
      final state = ActivitiesState();
      expect(state.activities, isEmpty);

      state.setSearchQuery("Cricket");
      final filtered = state.getFilteredActivities(null, {});
      expect(filtered, isEmpty);
    });

    test('ChatState messages initialization', () {
      final chat = ChatState();
      final actId = "act_cricket";
      final initialMsgs = chat.getMessagesForActivity(actId);
      expect(initialMsgs, isEmpty);
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
