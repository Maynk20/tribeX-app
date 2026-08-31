import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/constants/categories.dart';
import 'package:myapp/models/user_profile.dart';
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

      // Tap to dismiss
      await tester.tap(find.text('TAP ANYWHERE TO ENTER'));
      expect(completed, isTrue);
    });
  });
}
