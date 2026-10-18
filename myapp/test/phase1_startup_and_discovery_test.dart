import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/main_shell.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/state/notifications_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.clearCache();
  });

  const centerLat = 12.9716;
  const centerLon = 77.5946;

  ({double lat, double lon}) coordAtDistanceKm(double distKm) {
    const degKm = (math.pi / 180.0) * 6371.0088;
    final deltaLat = distKm / degKm;
    return (lat: centerLat + deltaLat, lon: centerLon);
  }

  Activity buildPlan({
    required String id,
    required String title,
    double? lat,
    double? lon,
    bool isOnline = false,
    String hostId = 'user_host',
    UserProfile? host,
  }) {
    return Activity(
      id: id,
      hostId: hostId,
      title: title,
      description: 'Description for $title',
      category: 'Sports',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      location: isOnline ? 'Online Event' : 'Bengaluru Venue',
      totalSlots: 10,
      slotsLeft: 5,
      costPerHead: 0,
      latitude: lat,
      longitude: lon,
      isOnline: isOnline,
      host: host,
    );
  }

  group('Phase 1 - 1. Asynchronous Location Restoration Race in ActivitiesState', () {
    test('restoreLocation() retrieves stored place and updates _place and _location', () async {
      const savedPlace = SavedPlace(
        displayName: 'Indiranagar, Bengaluru',
        short: 'Indiranagar',
        lat: 12.9784,
        lon: 77.6408,
      );
      SharedPreferences.setMockInitialValues({
        ActivitiesState.locationPrefsKey: 'Indiranagar',
        ActivitiesState.placePrefsKey: jsonEncode(savedPlace.toJson()),
      });

      final state = ActivitiesState();
      await state.restoreLocation();

      expect(state.location, 'Indiranagar');
      expect(state.place, isNotNull);
      expect(state.place!.lat, closeTo(12.9784, 0.0001));
      expect(state.place!.lon, closeTo(77.6408, 0.0001));
      expect(state.place!.short, 'Indiranagar');

      state.dispose();
    });

    test('Multiple concurrent callers to restoreLocation() share the same completer without race', () async {
      const savedPlace = SavedPlace(
        displayName: 'Koramangala, Bengaluru',
        short: 'Koramangala',
        lat: 12.9352,
        lon: 77.6245,
      );
      SharedPreferences.setMockInitialValues({
        ActivitiesState.locationPrefsKey: 'Koramangala',
        ActivitiesState.placePrefsKey: jsonEncode(savedPlace.toJson()),
      });

      final state = ActivitiesState();
      final future1 = state.restoreLocation();
      final future2 = state.restoreLocation();
      final future3 = state.restoreLocation();

      await Future.wait([future1, future2, future3]);

      expect(state.location, 'Koramangala');
      expect(state.place?.lat, closeTo(12.9352, 0.0001));

      state.dispose();
    });

    test('User manual location touch prevents async restore from overwriting user choice', () async {
      const savedPlace = SavedPlace(
        displayName: 'Old Persisted Place',
        short: 'Old',
        lat: 10.0,
        lon: 70.0,
      );
      SharedPreferences.setMockInitialValues({
        ActivitiesState.locationPrefsKey: 'Old',
        ActivitiesState.placePrefsKey: jsonEncode(savedPlace.toJson()),
      });

      final state = ActivitiesState();
      // User immediately picks a location manually before restore completes
      state.setPlace(const SavedPlace(
        displayName: 'User Chosen Place',
        short: 'Chosen',
        lat: 12.9716,
        lon: 77.5946,
      ));

      await state.restoreLocation();

      expect(state.location, 'Chosen');
      expect(state.place?.lat, 12.9716);
      expect(state.place?.lon, 77.5946);

      state.dispose();
    });
  });

  group('Phase 1 - 2. Location Permission Flow and Recovery Behavior', () {
    test('LocationService failure states return typed LocationFailure and safe null coordinates', () {
      final denied = LocationResult.failure(LocationService.msgDenied, reason: LocationFailure.permissionDenied);
      expect(denied.isSuccess, isFalse);
      expect(denied.latitude, isNull);
      expect(denied.longitude, isNull);
      expect(denied.reason, LocationFailure.permissionDenied);
      expect(denied.isPermanentlyDenied, isFalse);

      final permDenied = LocationResult.failure(LocationService.msgDeniedForever, reason: LocationFailure.permissionDeniedForever);
      expect(permDenied.isPermanentlyDenied, isTrue);

      final disabled = LocationResult.failure(LocationService.msgServiceDisabled, reason: LocationFailure.serviceDisabled);
      expect(disabled.isServiceDisabled, isTrue);
    });

    test('LocationService.firstNonEmpty correctly resolves address fallbacks', () {
      expect(LocationService.firstNonEmpty(['', '   ', 'Indiranagar', 'Bengaluru']), 'Indiranagar');
      expect(LocationService.firstNonEmpty(['', null, '']), '');
      expect(LocationService.coordinateFallbackLabel(12.9716, 77.5946), 'Near 12.97, 77.59');
    });
  });

  group('Phase 1 - 3. GPS Coordinate Propagation & Discovery State Bridge', () {
    testWidgets('MainShell bridges resolved user GPS coordinates from AuthState into ActivitiesState', (tester) async {
      final authState = AuthState();
      final actState = ActivitiesState();
      final notifState = NotificationsState();
      final chatState = ChatState();

      final userWithoutCoords = UserProfile(
        id: 'u_test_1',
        fullName: 'Test User',
        username: 'testuser',
        hasCompletedProfile: true,
        hasCompletedOnboarding: true,
        latitude: null,
        longitude: null,
      );

      authState.setMockUser(userWithoutCoords);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: authState),
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
            ChangeNotifierProvider<NotificationsState>.value(value: notifState),
            ChangeNotifierProvider<ChatState>.value(value: chatState),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(actState.place, isNull);

      // Simulate GPS resolution completing on AuthState (e.g. from background GPS refresh)
      final userWithCoords = userWithoutCoords.copyWith(
        city: 'Indiranagar',
        latitude: 12.9784,
        longitude: 77.6408,
      );
      authState.setMockUser(userWithCoords);

      await tester.pumpAndSettle();

      // Verified: ActivitiesState has been reactively updated with the resolved coordinates
      expect(actState.place, isNotNull);
      expect(actState.place!.lat, 12.9784);
      expect(actState.place!.lon, 77.6408);
      expect(actState.place!.short, 'Indiranagar');

      actState.dispose();
      authState.dispose();
      notifState.dispose();
      chatState.dispose();
    });
  });

  group('Phase 1 - 4. Stale Location Cleared on Sign-Out & Account Switching', () {
    test('clearLocation() resets location to default city, clears coordinates, and resets spatial flags', () async {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Indiranagar',
        short: 'Indiranagar',
        lat: 12.9784,
        lon: 77.6408,
      ));

      expect(state.place, isNotNull);
      expect(state.location, 'Indiranagar');

      state.clearLocation();

      expect(state.place, isNull);
      expect(state.location, ActivitiesState.defaultCity);

      state.dispose();
    });

    testWidgets('MainShell purges location when user signs out or switches accounts', (tester) async {
      final authState = AuthState();
      final actState = ActivitiesState();
      final notifState = NotificationsState();
      final chatState = ChatState();

      final userA = UserProfile(
        id: 'user_a',
        fullName: 'User A',
        username: 'usera',
        hasCompletedProfile: true,
        hasCompletedOnboarding: true,
        city: 'Bengaluru South',
        latitude: 12.9100,
        longitude: 77.5800,
      );

      authState.setMockUser(userA);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: authState),
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
            ChangeNotifierProvider<NotificationsState>.value(value: notifState),
            ChangeNotifierProvider<ChatState>.value(value: chatState),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(actState.place?.lat, 12.9100);

      // Sign out
      authState.setMockUser(null);
      await tester.pumpAndSettle();

      // Verified: Location is cleared and reset to default
      expect(actState.place, isNull);
      expect(actState.location, ActivitiesState.defaultCity);

      // Switch to User B (in Mumbai)
      final userB = UserProfile(
        id: 'user_b',
        fullName: 'User B',
        username: 'userb',
        hasCompletedProfile: true,
        hasCompletedOnboarding: true,
        city: 'Mumbai',
        latitude: 19.0760,
        longitude: 72.8777,
      );
      authState.setMockUser(userB);
      await tester.pumpAndSettle();

      // Verified: Coordinates switch cleanly to User B without retaining User A's stale state
      expect(actState.place?.lat, 19.0760);
      expect(actState.place?.lon, 72.8777);
      expect(actState.place?.short, 'Mumbai');

      actState.dispose();
      authState.dispose();
      notifState.dispose();
      chatState.dispose();
    });
  });

  group('Phase 1 - 5. 15 KM Boundaries, In-Person & Virtual Discovery', () {
    test('15 km boundary strictly enforced for physical in-person plans', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      const p0 = (lat: centerLat, lon: centerLon);
      final p14_99 = coordAtDistanceKm(14.99);
      final p15_0 = coordAtDistanceKm(15.0);
      final p15_01 = coordAtDistanceKm(15.01);
      final p30 = coordAtDistanceKm(30.0);

      final act0 = buildPlan(id: 'in_0', title: '0 km Plan', lat: p0.lat, lon: p0.lon);
      final act14 = buildPlan(id: 'in_14', title: '14.99 km Plan', lat: p14_99.lat, lon: p14_99.lon);
      final act15 = buildPlan(id: 'in_15', title: '15.0 km Boundary Plan', lat: p15_0.lat, lon: p15_0.lon);
      final act15_01 = buildPlan(id: 'in_15_01', title: '15.01 km Plan', lat: p15_01.lat, lon: p15_01.lon);
      final act30 = buildPlan(id: 'in_30', title: '30 km Plan', lat: p30.lat, lon: p30.lon);
      final actNoCoords = buildPlan(id: 'in_none', title: 'Missing Coords Plan', lat: null, lon: null);

      state.setActivitiesForTesting([act0, act14, act15, act15_01, act30, actNoCoords]);

      final filtered = state.getFilteredActivities(null, {});
      final ids = filtered.map((a) => a.id).toSet();

      expect(ids.contains('in_0'), isTrue);
      expect(ids.contains('in_14'), isTrue);
      expect(ids.contains('in_15'), isTrue);
      expect(ids.contains('in_15_01'), isFalse);
      expect(ids.contains('in_30'), isFalse);
      expect(ids.contains('in_none'), isFalse);
      expect(filtered.length, 3);

      state.dispose();
    });

    test('Virtual plans: creator location within 15 km included, > 15 km excluded', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      final nearHostCoords = coordAtDistanceKm(5.0);
      final farHostCoords = coordAtDistanceKm(25.0);

      final nearVirtual = buildPlan(
        id: 'v_near',
        title: 'Virtual Gaming 5km',
        isOnline: true,
        host: UserProfile(
          id: 'host_near',
          fullName: 'Near Host',
          username: 'near_host',
          latitude: nearHostCoords.lat,
          longitude: nearHostCoords.lon,
        ),
      );

      final farVirtual = buildPlan(
        id: 'v_far',
        title: 'Virtual Talk 25km',
        isOnline: true,
        host: UserProfile(
          id: 'host_far',
          fullName: 'Far Host',
          username: 'far_host',
          latitude: farHostCoords.lat,
          longitude: farHostCoords.lon,
        ),
      );

      state.setActivitiesForTesting([nearVirtual, farVirtual]);

      final filtered = state.getFilteredActivities(null, {});
      final ids = filtered.map((a) => a.id).toSet();

      expect(ids.contains('v_near'), isTrue);
      expect(ids.contains('v_far'), isFalse);
      expect(filtered.length, 1);

      state.dispose();
    });

    test('Virtual plans without direct coordinates on model trust spatial server verification', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      // Virtual plan where server verified location, but model has null coords for privacy
      final verifiedVirtual = buildPlan(
        id: 'v_verified',
        title: 'Spatially Verified Virtual Plan',
        isOnline: true,
        lat: null,
        lon: null,
      );

      final unverifiedVirtual = buildPlan(
        id: 'v_unverified',
        title: 'Unverified Virtual Plan',
        isOnline: true,
        lat: null,
        lon: null,
      );

      // When isSpatial is false, neither passes without coordinates
      state.setActivitiesForTesting([verifiedVirtual, unverifiedVirtual], isSpatial: false);
      expect(state.getFilteredActivities(null, {}), isEmpty);

      // When isSpatial is true, verifiedVirtual is included via spatiallyVerifiedIds
      state.setActivitiesForTesting([verifiedVirtual], isSpatial: true);
      final filtered = state.getFilteredActivities(null, {});
      expect(filtered.map((a) => a.id).toList(), ['v_verified']);

      state.dispose();
    });
  });

  group('Phase 1 - 6. Pagination & Deduplication', () {
    test('Deduplicates plans by stable ID and preserves pagination boundaries', () {
      final state = ActivitiesState();
      final act1 = buildPlan(id: 'act_1', title: 'Plan 1', lat: centerLat, lon: centerLon);
      final act2 = buildPlan(id: 'act_2', title: 'Plan 2', lat: centerLat, lon: centerLon);
      final act1Duplicate = buildPlan(id: 'act_1', title: 'Plan 1 Duplicate', lat: centerLat, lon: centerLon);

      state.setActivitiesForTesting([act1, act2, act1Duplicate]);

      expect(state.activities.length, 2);
      expect(state.activities.map((a) => a.id).toList(), ['act_1', 'act_2']);

      state.dispose();
    });
  });
}
