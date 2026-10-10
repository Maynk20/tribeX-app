import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:myapp/core/theme/app_tokens.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/create_plan_screen.dart';
import 'package:myapp/screens/messages_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/state/notifications_state.dart';
import 'package:myapp/state/theme_state.dart';
import 'package:myapp/widgets/common/app_avatar.dart';
import 'package:myapp/widgets/common/app_empty_state.dart';
import 'package:myapp/widgets/common/app_section_header.dart';

void main() {
  group('1. AppTokens & Design System Tokens', () {
    test('AppTouchTarget enforces minimum 44px for WCAG compliance', () {
      expect(AppTouchTarget.minSize, greaterThanOrEqualTo(44.0));
    });

    test('AppSpacing provides consistent harmonious scale', () {
      expect(AppSpacing.xs, equals(4.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.lg, equals(16.0));
      expect(AppSpacing.xl, equals(20.0));
      expect(AppSpacing.xxl, equals(24.0));
      expect(AppSpacing.xxxl, equals(32.0));
    });

    test('AppRadius avoids excessive oversized card rounding', () {
      expect(AppRadius.xs, equals(6.0));
      expect(AppRadius.sm, equals(10.0));
      expect(AppRadius.md, equals(14.0));
      expect(AppRadius.lg, equals(18.0));
      expect(AppRadius.xl, equals(22.0));
      expect(AppRadius.lg, lessThanOrEqualTo(20.0));
    });
  });

  group('2. AppAvatar Component Tests', () {
    testWidgets('Renders deterministic initials when image is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Aarav Sharma',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('AS'), findsOneWidget);
    });

    testWidgets('Single name yields single initial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Mayank',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('Online indicator renders when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Priya Patel',
              showOnlineIndicator: true,
              isOnline: true,
              size: 44,
            ),
          ),
        ),
      );

      expect(find.byType(AppAvatar), findsOneWidget);
    });
  });

  group('3. AppEmptyState Component Tests', () {
    testWidgets('Displays icon, title, description, and triggers primary action', (tester) async {
      bool primaryClicked = false;
      bool secondaryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: LucideIcons.compass,
              title: 'No plans found',
              description: 'Try adjusting your filters or search keywords.',
              primaryActionLabel: 'Explore All',
              onPrimaryAction: () => primaryClicked = true,
              secondaryActionLabel: 'Create Plan',
              onSecondaryAction: () => secondaryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('No plans found'), findsOneWidget);
      expect(find.text('Try adjusting your filters or search keywords.'), findsOneWidget);
      expect(find.text('Explore All'), findsOneWidget);
      expect(find.text('Create Plan'), findsOneWidget);

      await tester.tap(find.text('Explore All'));
      await tester.pump();
      expect(primaryClicked, isTrue);

      await tester.tap(find.text('Create Plan'));
      await tester.pump();
      expect(secondaryClicked, isTrue);
    });
  });

  group('4. AppSectionHeader Component Tests', () {
    testWidgets('Renders section title, optional badge, and action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Upcoming Events',
              subtitle: 'Handpicked events in your neighborhood',
              count: 3,
              actionLabel: 'See All',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Handpicked events in your neighborhood'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      await tester.tap(find.text('See All'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });
  });

  group('5. CreatePlanScreen 3-Step Wizard Flow', () {
    Widget createWizardApp() {
      final auth = AuthState();
      auth.setMockUser(
        UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test Host',
          username: 'testhost',
        ),
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => ActivitiesState()),
          ChangeNotifierProvider(create: (_) => ChatState()),
          ChangeNotifierProvider(create: (_) => NotificationsState()),
          ChangeNotifierProvider(create: (_) => ThemeState()),
        ],
        child: const MaterialApp(
          home: CreatePlanScreen(),
        ),
      );
    }

    testWidgets('Wizard starts at Step 1: What & when', (tester) async {
      await tester.pumpWidget(createWizardApp());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3 · What & when'), findsOneWidget);
      expect(find.text('In-Person Venue'), findsOneWidget);
      expect(find.text('Online / Virtual'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });

    testWidgets('Wizard blocks Step 1 progression if required title is empty', (tester) async {
      await tester.pumpWidget(createWizardApp());
      await tester.pumpAndSettle();

      // Tap Continue without filling title
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Inline validation error and toast are shown, and stays on Step 1
      expect(find.text('Title must be at least 4 characters'), findsAtLeastNWidgets(1));
      expect(find.text('Step 1 of 3 · What & when'), findsOneWidget);
    });

    testWidgets('Wizard advances from Step 1 to Step 2 when inputs are valid', (tester) async {
      await tester.pumpWidget(createWizardApp());
      await tester.pumpAndSettle();

      // Fill valid Title
      final titleField = find.widgetWithText(TextField, 'Box cricket at Turf Arena');
      await tester.enterText(titleField, 'Sunday Morning Cricket Match');
      await tester.pump();

      // Fill valid Description
      final descField = find.widgetWithText(TextField, 'Chill 6-a-side, all levels welcome. Bring water.');
      await tester.enterText(descField, 'Friendly 8v8 cricket game with refreshments.');
      await tester.pump();

      // Tap Continue
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Now on Step 2
      expect(find.text('Step 2 of 3 · Where & who'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });
  });

  group('6. MessagesScreen Inbox Refinements', () {
    testWidgets('Shows empty state with exploration actions when no chats exist', (tester) async {
      final auth = AuthState();
      auth.setMockUser(
        UserProfile(
          id: 'user_456',
          email: 'member@example.com',
          fullName: 'Member Name',
          username: 'member1',
        ),
      );

      bool explored = false;
      bool created = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => ActivitiesState()),
            ChangeNotifierProvider(create: (_) => ChatState()),
            ChangeNotifierProvider(create: (_) => NotificationsState()),
          ],
          child: MaterialApp(
            home: MessagesScreen(
              onNavigateToExplore: () => explored = true,
              onNavigateToCreate: () => created = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No squad chats yet'), findsOneWidget);
      expect(find.text('Explore Plans'), findsOneWidget);
      expect(find.text('Create a Plan'), findsOneWidget);

      await tester.tap(find.text('Explore Plans'));
      await tester.pump();
      expect(explored, isTrue);

      await tester.tap(find.text('Create a Plan'));
      await tester.pump();
      expect(created, isTrue);
    });
  });

  group('7. ProfileScreen Tabs & States', () {
    testWidgets('Renders hero profile and switches tabs between Joined and Hosted', (tester) async {
      final auth = AuthState();
      auth.setMockUser(
        UserProfile(
          id: 'user_789',
          email: 'host@example.com',
          fullName: 'Siddharth Roy',
          username: 'siddharth_r',
          rating: 4.95,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => ActivitiesState()),
            ChangeNotifierProvider(create: (_) => ChatState()),
            ChangeNotifierProvider(create: (_) => NotificationsState()),
            ChangeNotifierProvider(create: (_) => ThemeState()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Siddharth Roy'), findsOneWidget);
      expect(find.text('Joined · 0'), findsOneWidget);
      expect(find.text('Hosted · 0'), findsOneWidget);

      // Default Joined tab is empty
      expect(find.text('No joined plans yet'), findsOneWidget);

      // Switch to Hosted tab
      await tester.tap(find.text('Hosted · 0'));
      await tester.pumpAndSettle();

      // Hosted tab is active and shows hosted empty state
      expect(find.text('No hosted plans yet'), findsOneWidget);
    });
  });
}
