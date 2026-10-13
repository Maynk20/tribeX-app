import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/create_plan_screen.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp() {
    final authState = AuthState();
    authState.setMockUser(
      UserProfile(
        id: 'test_user_id',
        username: 'test_user',
        fullName: 'Test Host',
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProvider<ActivitiesState>(create: (_) => ActivitiesState()),
      ],
      child: const MaterialApp(
        home: CreatePlanScreen(),
      ),
    );
  }

  testWidgets('Virtual mode Step 2 renders cleanly without RenderFlex overflow on narrow 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Select Online / Virtual
    await tester.tap(find.text('Online / Virtual'));
    await tester.pumpAndSettle();

    // Enter title & description
    final titleField = find.widgetWithText(TextField, 'Box cricket at Turf Arena');
    await tester.enterText(titleField, 'Virtual Gaming Tournament');
    await tester.pump();

    final descField = find.widgetWithText(TextField, 'Chill 6-a-side, all levels welcome. Bring water.');
    await tester.enterText(descField, 'Online Among Us and Valorant session for the community.');
    await tester.pump();

    // Tap Continue to go to Step 2
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3 · Where & who'), findsOneWidget);
    expect(find.text('MEETING LINK'), findsOneWidget);
    expect(find.text('PLATFORM (OPTIONAL)'), findsOneWidget);
    expect(find.text('TOTAL SLOTS'), findsOneWidget);
    expect(find.text('COST / HEAD'), findsOneWidget);
    expect(find.text('SAFETY CONTROLS'), findsOneWidget);

    // Test validation error state in Step 2 without overflow
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please add a valid meeting URL'), findsAtLeastNWidgets(1));
  });

  testWidgets('In-person mode Step 2 renders cleanly without RenderFlex overflow on 360px screen', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Enter title & description
    final titleField = find.widgetWithText(TextField, 'Box cricket at Turf Arena');
    await tester.enterText(titleField, 'Turf Football Match');
    await tester.pump();

    final descField = find.widgetWithText(TextField, 'Chill 6-a-side, all levels welcome. Bring water.');
    await tester.enterText(descField, '5v5 box football match at Indiranagar.');
    await tester.pump();

    // Tap Continue to go to Step 2
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3 · Where & who'), findsOneWidget);
    expect(find.text('VENUE / LOCATION'), findsOneWidget);
  });
}
