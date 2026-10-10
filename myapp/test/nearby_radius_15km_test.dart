import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:myapp/screens/explore_screen.dart';
import 'package:myapp/widgets/activity/activity_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Reference coordinates: Bengaluru Center
  const centerLat = 12.9716;
  const centerLon = 77.5946;

  /// Helper to generate coordinates at an exact distance North from center
  ({double lat, double lon}) coordAtDistanceKm(double distKm) {
    // 1 deg latitude = (math.pi / 180) * 6371.0088 km
    const degKm = (math.pi / 180.0) * 6371.0088;
    final deltaLat = distKm / degKm;
    return (lat: centerLat + deltaLat, lon: centerLon);
  }

  Activity buildActivity({
    required String id,
    required String title,
    double? lat,
    double? lon,
    String hostId = 'host_1',
    String locationName = 'Bengaluru',
  }) {
    return Activity(
      id: id,
      hostId: hostId,
      title: title,
      description: 'Test activity description for $title',
      category: 'Sports',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      location: locationName,
      totalSlots: 10,
      slotsLeft: 5,
      costPerHead: 0,
      latitude: lat,
      longitude: lon,
    );
  }

  group('1. Default Radius & Haversine Distance Precision Tests', () {
    test('Default radius is exactly 15.0 km in ActivitiesState', () {
      expect(ActivitiesState.defaultRadiusKm, 15.0);
      final state = ActivitiesState();
      expect(state.radiusKm, 15.0);
      state.dispose();
    });

    test('LocationService.haversineKm calculates distance accurately', () {
      final p5 = coordAtDistanceKm(5.0);
      final p14_9 = coordAtDistanceKm(14.9);
      final p15 = coordAtDistanceKm(15.0);
      final p15_1 = coordAtDistanceKm(15.1);

      final d5 = LocationService.haversineKm(
        centerLat,
        centerLon,
        p5.lat,
        p5.lon,
      );
      final d14_9 = LocationService.haversineKm(
        centerLat,
        centerLon,
        p14_9.lat,
        p14_9.lon,
      );
      final d15 = LocationService.haversineKm(
        centerLat,
        centerLon,
        p15.lat,
        p15.lon,
      );
      final d15_1 = LocationService.haversineKm(
        centerLat,
        centerLon,
        p15_1.lat,
        p15_1.lon,
      );

      expect(d5, closeTo(5.0, 0.001));
      expect(d14_9, closeTo(14.9, 0.001));
      expect(d15, closeTo(15.0, 0.001));
      expect(d15_1, closeTo(15.1, 0.001));
    });
  });

  group('2. Discovery Feed 15 KM Filtering (5km, 14.9km, 15km included; 15.1km excluded)', () {
    test('Strict filtering at 15 km boundary: 5km, 14.9km, 15km pass, 15.1km excluded', () {
      final state = ActivitiesState();
      const place = SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      );
      state.setPlace(place);

      final p5 = coordAtDistanceKm(5.0);
      final p14_9 = coordAtDistanceKm(14.9);
      final p15 = coordAtDistanceKm(15.0);
      final p15_1 = coordAtDistanceKm(15.1);
      final p25 = coordAtDistanceKm(25.0);

      final act5 = buildActivity(
        id: 'a_5',
        title: '5 KM Plan',
        lat: p5.lat,
        lon: p5.lon,
      );
      final act14_9 = buildActivity(
        id: 'a_14_9',
        title: '14.9 KM Plan',
        lat: p14_9.lat,
        lon: p14_9.lon,
      );
      final act15 = buildActivity(
        id: 'a_15',
        title: '15.0 KM Plan',
        lat: p15.lat,
        lon: p15.lon,
      );
      final act15_1 = buildActivity(
        id: 'a_15_1',
        title: '15.1 KM Plan',
        lat: p15_1.lat,
        lon: p15_1.lon,
      );
      final act25 = buildActivity(
        id: 'a_25',
        title: '25.0 KM Plan',
        lat: p25.lat,
        lon: p25.lon,
      );
      final actNoCoords = buildActivity(
        id: 'a_no_coords',
        title: 'No Coords Plan',
        lat: null,
        lon: null,
      );

      state.setActivitiesForTesting([
        act5,
        act14_9,
        act15,
        act15_1,
        act25,
        actNoCoords,
      ]);

      final filtered = state.getFilteredActivities(null, {});
      final filteredIds = filtered.map((a) => a.id).toSet();

      // Included
      expect(
        filteredIds.contains('a_5'),
        isTrue,
        reason: '5.0 km must be included',
      );
      expect(
        filteredIds.contains('a_14_9'),
        isTrue,
        reason: '14.9 km must be included',
      );
      expect(
        filteredIds.contains('a_15'),
        isTrue,
        reason: '15.0 km must be included',
      );

      // Excluded
      expect(
        filteredIds.contains('a_15_1'),
        isFalse,
        reason: '15.1 km must be excluded',
      );
      expect(
        filteredIds.contains('a_25'),
        isFalse,
        reason: '25.0 km must be excluded',
      );
      expect(
        filteredIds.contains('a_no_coords'),
        isFalse,
        reason: 'Plan without coords must be excluded from discovery radius',
      );

      expect(filtered.length, 3);
      state.dispose();
    });

    test(
      'Manual location change recalculates radius from selected location',
      () {
        final state = ActivitiesState();

        // Initially set center to Bengaluru
        state.setPlace(
          const SavedPlace(
            displayName: 'Bengaluru Center',
            short: 'Bengaluru',
            lat: 12.9716,
            lon: 77.5946,
          ),
        );

        // Delhi coordinates
        const delhiLat = 28.6139;
        const delhiLon = 77.2090;

        final bangaloreAct = buildActivity(
          id: 'act_blr',
          title: 'Bengaluru Cricket',
          lat: 12.9800,
          lon: 77.6000,
        );
        final delhiAct = buildActivity(
          id: 'act_del',
          title: 'Delhi Badminton',
          lat: 28.6200,
          lon: 77.2150,
        );

        state.setActivitiesForTesting([bangaloreAct, delhiAct]);

        // Under Bengaluru center, only bangaloreAct is within 15 km
        var filtered = state.getFilteredActivities(null, {});
        expect(filtered.map((a) => a.id).toList(), ['act_blr']);

        // User manually selects Delhi
        state.setPlace(
          const SavedPlace(
            displayName: 'Connaught Place, New Delhi',
            short: 'New Delhi',
            lat: delhiLat,
            lon: delhiLon,
          ),
        );

        // Now under Delhi center, only delhiAct is within 15 km
        filtered = state.getFilteredActivities(null, {});
        expect(filtered.map((a) => a.id).toList(), ['act_del']);

        state.dispose();
      },
    );
  });

  group('3. Joining Plans Beyond 15 KM is Not Blocked', () {
    test('Users are not blocked from joining plans beyond 15 km', () async {
      final state = ActivitiesState();
      // Center at Bengaluru
      state.setPlace(
        const SavedPlace(
          displayName: 'Bengaluru',
          short: 'Bengaluru',
          lat: 12.9716,
          lon: 77.5946,
        ),
      );

      // Mysore plan (140 km away from Bengaluru)
      final farPlan = buildActivity(
        id: 'act_mysore',
        title: 'Mysore Palace Walk',
        lat: 12.3051,
        lon: 76.6551,
        hostId: 'other_host',
      );
      state.setActivitiesForTesting([farPlan]);

      final user = UserProfile(
        id: 'user_123',
        fullName: 'Test Joiner',
        username: 'test_joiner',
        city: 'Bengaluru',
        latitude: 12.9716,
        longitude: 77.5946,
      );

      // Verify profile has GPS location
      expect(ActivitiesState.profileHasGpsLocation(user), isTrue);

      // Without a Supabase client connection in unit tests, requestToJoin returns error only if unavailable or checks fail.
      // But notice it does NOT return any "too far" error!
      final err = await state.requestToJoin('act_mysore', user);
      expect(err, isNot(contains('too far')));
      expect(err, isNot(contains('radius')));
      expect(err, isNot(contains('15 km')));

      state.dispose();
    });
  });

  group('4. Location & Error Handling', () {
    test(
      'LocationResult failure does not crash or inject fake coordinates',
      () {
        final failResult = LocationResult.failure(
          LocationService.msgDenied,
          reason: LocationFailure.permissionDenied,
        );
        expect(failResult.isSuccess, isFalse);
        expect(failResult.latitude, isNull);
        expect(failResult.longitude, isNull);
        expect(failResult.error, LocationService.msgDenied);
        expect(failResult.reason, LocationFailure.permissionDenied);
      },
    );

    test('When place is null, discovery feed shows activities without distance claims', () {
      final state = ActivitiesState();
      // Ensure place is null
      state.clearLocation();
      expect(state.place, isNull);

      final act1 = buildActivity(
        id: 'a1',
        title: 'General Plan 1',
        lat: 12.9,
        lon: 77.5,
      );
      final act2 = buildActivity(
        id: 'a2',
        title: 'General Plan 2',
        lat: 28.6,
        lon: 77.2,
      );
      state.setActivitiesForTesting([act1, act2]);

      final filtered = state.getFilteredActivities(null, {});
      // When no place coordinates are specified, activities are not silently hidden
      expect(filtered.length, 2);

      state.dispose();
    });
  });

  group('5. UI Verification Tests', () {
    testWidgets(
      'ActivityCard displays calculated distance when distanceKm is provided',
      (tester) async {
        final act = buildActivity(
          id: 'act_ui_1',
          title: 'Evening Badminton',
          lat: 12.9800,
          lon: 77.6000,
          locationName: 'Indiranagar Club',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activity: act,
                isHost: false,
                distanceKm: 3.5,
                onJoin: () {},
                onChat: () {},
              ),
            ),
          ),
        );

        // Verify "3.5 km away" badge appears next to location
        expect(find.text('3.5 km away'), findsOneWidget);
        expect(find.text('Indiranagar Club'), findsOneWidget);
      },
    );

    testWidgets(
      'ActivityCard does not display distance badge when distanceKm is null',
      (tester) async {
        final act = buildActivity(
          id: 'act_ui_2',
          title: 'Board Game Night',
          locationName: 'Koramangala Cafe',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activity: act,
                isHost: false,
                distanceKm: null,
                onJoin: () {},
                onChat: () {},
              ),
            ),
          ),
        );

        // Verify no "km away" badge appears
        expect(find.textContaining('km away'), findsNothing);
        expect(find.text('Koramangala Cafe'), findsOneWidget);
      },
    );

    testWidgets(
      'ExploreScreen displays "Plans within 15 km" when location coordinates are set',
      (tester) async {
        final actState = ActivitiesState();
        actState.setPlace(
          const SavedPlace(
            displayName: 'Indiranagar, Bengaluru',
            short: 'Indiranagar',
            lat: 12.9784,
            lon: 77.6408,
          ),
        );

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Section Title shows "Plans within 15 km"
        expect(find.text('Plans within 15 km'), findsOneWidget);
        // Verify "15 km radius" badge
        expect(find.text('15 km radius'), findsOneWidget);

        actState.dispose();
        authState.dispose();
      },
    );

    testWidgets(
      'ExploreScreen displays helpful location banner when location is unavailable',
      (tester) async {
        final actState = ActivitiesState();
        actState.clearLocation(); // Ensures place == null

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Title shows "Nearby plans"
        expect(find.text('Nearby plans'), findsOneWidget);
        // Helpful message for unavailable location
        expect(find.text('Location unavailable'), findsOneWidget);
        expect(
          find.text(
            'Enable GPS or select your city to filter plans within 15 km of you.',
          ),
          findsOneWidget,
        );
        expect(find.text('Use GPS'), findsOneWidget);

        actState.dispose();
        authState.dispose();
      },
    );

    testWidgets(
      'ExploreScreen automatically transitions from "Plans within 15 km" to Normal page after 10 seconds',
      (tester) async {
        final actState = ActivitiesState();
        actState.setPlace(
          const SavedPlace(
            displayName: 'Indiranagar, Bengaluru',
            short: 'Indiranagar',
            lat: 12.9784,
            lon: 77.6408,
          ),
        );

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Initial State (<10 seconds): 15km bar is active
        expect(find.text('Plans within 15 km'), findsOneWidget);
        expect(find.text('15 km radius'), findsOneWidget);

        // 2. Advance time by 10 seconds
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        // 3. Normal page: 15km bar is removed, section title is "Nearby plans"
        expect(find.text('Nearby plans'), findsOneWidget);
        expect(find.text('Plans within 15 km'), findsNothing);
        expect(find.text('15 km radius'), findsNothing);

        actState.dispose();
        authState.dispose();
      },
    );

    testWidgets(
      'ExploreScreen hides location unavailable 15km banner after 10 seconds to show clean Normal page',
      (tester) async {
        final actState = ActivitiesState();
        actState.clearLocation();

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Initial State (<10 seconds): Banner is active
        expect(
          find.text(
            'Enable GPS or select your city to filter plans within 15 km of you.',
          ),
          findsOneWidget,
        );

        // Advance time by 10 seconds
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        // Banner disappears on Normal page
        expect(
          find.text(
            'Enable GPS or select your city to filter plans within 15 km of you.',
          ),
          findsNothing,
        );
        actState.dispose();
        authState.dispose();
      },
    );

    testWidgets(
      'ExploreScreen manually dismisses "Plans within 15 km" when user taps cross "X" option',
      (tester) async {
        final actState = ActivitiesState();
        actState.setPlace(
          const SavedPlace(
            displayName: 'Indiranagar, Bengaluru',
            short: 'Indiranagar',
            lat: 12.9784,
            lon: 77.6408,
          ),
        );

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Initial State: "Plans within 15 km" and "15 km radius" badge are active
        expect(find.text('Plans within 15 km'), findsOneWidget);
        expect(find.text('15 km radius'), findsOneWidget);

        // 2. Tap the dismiss cross 'X' on the badge
        final dismissTarget = find.byKey(const Key('dismiss-15km-badge'));
        expect(dismissTarget, findsOneWidget);
        await tester.tap(dismissTarget);
        await tester.pumpAndSettle();

        // 3. 15km bar is immediately dismissed without waiting for 10s timer
        expect(find.text('Nearby plans'), findsOneWidget);
        expect(find.text('Plans within 15 km'), findsNothing);
        expect(find.text('15 km radius'), findsNothing);

        actState.dispose();
        authState.dispose();
      },
    );

    testWidgets(
      'ExploreScreen manually dismisses location unavailable banner when user taps cross "X" button',
      (tester) async {
        final actState = ActivitiesState();
        actState.clearLocation();

        final authState = AuthState();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ActivitiesState>.value(value: actState),
              ChangeNotifierProvider<AuthState>.value(value: authState),
            ],
            child: const MaterialApp(home: ExploreScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Initial State: Location unavailable banner is active
        expect(
          find.text(
            'Enable GPS or select your city to filter plans within 15 km of you.',
          ),
          findsOneWidget,
        );

        // 2. Tap dismiss cross 'X' on the banner
        final dismissBtn = find.bySemanticsLabel('Dismiss banner');
        expect(dismissBtn, findsOneWidget);
        await tester.tap(dismissBtn);
        await tester.pumpAndSettle();

        // 3. Banner is immediately dismissed
        expect(
          find.text(
            'Enable GPS or select your city to filter plans within 15 km of you.',
          ),
          findsNothing,
        );
        expect(find.text('Nearby plans'), findsOneWidget);

        actState.dispose();
        authState.dispose();
      },
    );
  });
}
