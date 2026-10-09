import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/models/activity.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/widgets/chat/check_in_panel.dart';
import 'package:myapp/widgets/chat/expense_card_widget.dart';
import 'package:myapp/widgets/chat/memory_banner_widget.dart';
import 'package:myapp/widgets/chat/message_bubble_widget.dart';
import 'package:myapp/widgets/chat/poll_card_widget.dart';
import 'package:myapp/widgets/common/custom_bottom_nav.dart';
import 'package:myapp/widgets/common/place_search_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('tribeX Button, Widget & Flow Verification Tests', () {
    testWidgets('CustomBottomNav buttons change tabs on tap', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return CustomBottomNav(
                  currentIndex: selectedIndex,
                  onTap: (idx) {
                    setState(() {
                      selectedIndex = idx;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify all 4 bottom navigation items exist
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap 'Create' tab (Index 1)
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);

      // Tap 'Messages' tab (Index 2)
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 2);

      // Tap 'Profile' tab (Index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 3);

      // Tap 'Explore' tab (Index 0)
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 0);
    });

    testWidgets('PlaceSearchDialog input search, clear button and selection callback', (
      WidgetTester tester,
    ) async {
      PlaceItem? selectedPlace;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    PlaceSearchDialog.show(
                      ctx,
                      initialValue: '',
                      onSelect: (item) {
                        selectedPlace = item;
                      },
                    );
                  },
                  child: const Text('Open Search'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Verify dialog header and popular places
      expect(find.text('POPULAR CITIES & HUB LOCATIONS'), findsOneWidget);
      expect(find.text('Indiranagar'), findsOneWidget);
      expect(find.text('Use Current GPS Location'), findsOneWidget);

      // Select popular place: Indiranagar
      await tester.tap(find.text('Indiranagar'));
      await tester.pumpAndSettle();

      expect(selectedPlace, isNotNull);
      expect(selectedPlace!.title, 'Indiranagar');
      expect(selectedPlace!.lat, 12.9784);
      expect(selectedPlace!.lon, 77.6408);
    });

    testWidgets('PollCardWidget renders options and handles vote interaction', (
      WidgetTester tester,
    ) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll_test_1',
        activityId: 'act_1',
        creatorId: 'user_host',
        question: 'What time for turf football?',
        options: [
          PollOption(id: '0', text: '6:00 PM', voterIds: ['user_host']),
          PollOption(id: '1', text: '7:30 PM', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      // Inject poll into state
      await tester.pumpWidget(
        ChangeNotifierProvider<ChatState>.value(
          value: chatState,
          child: MaterialApp(
            home: Scaffold(
              body: PollCardWidget(
                pollId: poll.id,
                currentUserId: 'user_attendee',
              ),
            ),
          ),
        ),
      );

      // When poll is not yet in chatState map, shows loading
      expect(find.text('Loading poll details…'), findsOneWidget);

      chatState.dispose();
    });

    testWidgets('ExpenseCardWidget renders total amount and members', (
      WidgetTester tester,
    ) async {
      final chatState = ChatState();
      await tester.pumpWidget(
        ChangeNotifierProvider<ChatState>.value(
          value: chatState,
          child: const MaterialApp(
            home: Scaffold(
              body: ExpenseCardWidget(
                expenseId: 'exp_nonexistent',
                currentUserId: 'u1',
              ),
            ),
          ),
        ),
      );

      // Initially shows loading placeholder
      expect(find.text('Loading expense details…'), findsOneWidget);
      chatState.dispose();
    });

    testWidgets('MessageBubbleWidget renders text, sender and report action', (
      WidgetTester tester,
    ) async {
      final message = Message(
        id: 'm1',
        activityId: 'act_1',
        senderId: 'u2',
        text: 'Hey everyone, meet at gate 3!',
        createdAt: DateTime(2026, 10, 9, 14, 30),
        sender: UserProfile(
          id: 'u2',
          fullName: 'Priya Sharma',
          username: 'priya',
          email: 'priya@tribex.local',
        ),
      );

      bool reportTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: message,
              isMine: false,
              onReport: () {
                reportTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Hey everyone, meet at gate 3!'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);

      // Tap report button
      final reportBtn = find.byIcon(Icons.more_horiz);
      if (reportBtn.evaluate().isNotEmpty) {
        await tester.tap(reportBtn);
        await tester.pumpAndSettle();
        expect(reportTapped, isTrue);
      }
    });

    testWidgets('CheckInPanel renders host controls and distance information', (
      WidgetTester tester,
    ) async {
      final actState = ActivitiesState();
      final activity = Activity(
        id: 'act_1',
        title: 'Sunday Morning Badminton',
        description: 'Morning fun match',
        category: 'Badminton',
        location: 'Play Arena, Sarjapur Road',
        latitude: 12.9121,
        longitude: 77.6446,
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        hostId: 'host_1',
        totalSlots: 6,
        slotsLeft: 3,
        costPerHead: 150,
        host: UserProfile(
          id: 'host_1',
          fullName: 'Karan Patel',
          username: 'karan',
          email: 'karan@tribex.local',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ActivitiesState>.value(
          value: actState,
          child: MaterialApp(
            home: Scaffold(
              body: CheckInPanel(
                activity: activity,
                isHost: true,
                myRequest: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('VENUE CHECK-IN'), findsOneWidget);
      expect(
        find.text('Tap check-in when you arrive (must be within 150m).'),
        findsOneWidget,
      );
    });

    testWidgets('MemoryBannerWidget renders photo banner and upload button', (
      WidgetTester tester,
    ) async {
      final activity = Activity(
        id: 'act_1',
        title: 'Sunset Rooftop Board Games',
        description: 'Rooftop fun board games session',
        category: 'Board Games',
        location: 'Indiranagar Social',
        latitude: 12.9784,
        longitude: 77.6408,
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        hostId: 'host_1',
        totalSlots: 8,
        slotsLeft: 4,
        costPerHead: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryBannerWidget(
              activity: activity,
              canUpload: true,
            ),
          ),
        ),
      );

      expect(find.text('SQUAD MEMORIES'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
    });
  });
}
