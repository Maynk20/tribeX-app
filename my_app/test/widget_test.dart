import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/constants/categories.dart';
import 'package:my_app/models/user_profile.dart';
import 'package:my_app/state/activities_state.dart';
import 'package:my_app/state/chat_state.dart';
import 'package:my_app/widgets/common/welcome_splash.dart';

void main() {
  group('tribeX Unit & State Tests', () {
    test('Categories and amenities are properly configured', () {
      expect(AppCategories.groups.length, 5);
      expect(AppCategories.all.length, greaterThanOrEqualTo(25));
      expect(AppCategories.amenities.length, 4);
      expect(AppCategories.emojiFor("Cricket"), "🏏");
      expect(AppCategories.emojiFor("Chess"), "♟️");
    });

    test('UserProfile reliability label and rating logic', () {
      final user = UserProfile(
        id: "u1",
        fullName: "Mayank Thakkar",
        username: "mayank",
        email: "mayank@tribex.local",
        rating: 5.0,
      );
      expect(user.reliabilityLabel, "100% Reliable · Elite Host");
    });

    test('ActivitiesState filtering and urgent toggle', () {
      final state = ActivitiesState();
      expect(state.activities.length, greaterThanOrEqualTo(5));

      final actId = state.activities.first.id;
      final initialUrgent = state.activities.first.isUrgentActive;
      state.toggleUrgent(actId);
      final updated = state.activities.firstWhere((a) => a.id == actId);
      expect(updated.isUrgentActive, !initialUrgent);

      state.setSearchQuery("Cricket");
      final filtered = state.getFilteredActivities(null, {});
      expect(
        filtered.every(
          (a) =>
              a.title.toLowerCase().contains("cricket") ||
              a.category.toLowerCase().contains("cricket"),
        ),
        isTrue,
      );
    });

    test('ChatState messages, polls and expense tracking', () {
      final chat = ChatState();
      final actId = "act_cricket";
      final initialMsgs = chat.getMessagesForActivity(actId);
      final count = initialMsgs.length;

      chat.sendMessage(
        activityId: actId,
        senderId: "u_mayank",
        text: "See you all at the turf!",
      );

      final nextMsgs = chat.getMessagesForActivity(actId);
      expect(nextMsgs.length, count + 1);
      expect(nextMsgs.last.text, "See you all at the turf!");
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

      // Tap to dismiss
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      expect(completed, isTrue);
    });
  });
}
