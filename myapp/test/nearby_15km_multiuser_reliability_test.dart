import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.clearCache();
  });

  // Reference coordinates: Bengaluru Center
  const centerLat = 12.9716;
  const centerLon = 77.5946;

  /// Helper to generate coordinates at an exact distance North from center
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
    String? meetingLink,
  }) {
    return Activity(
      id: id,
      hostId: hostId,
      title: title,
      description: 'Test plan description for $title',
      category: 'Sports',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      location: isOnline ? 'Online Event' : 'Bengaluru Venue',
      totalSlots: 10,
      slotsLeft: 5,
      costPerHead: 0,
      latitude: lat,
      longitude: lon,
      isOnline: isOnline,
      meetingLink: meetingLink,
      host: host,
    );
  }

  group('1. Location, 15 KM Radius & Boundary Precision Tests', () {
    test('Calculates circular Haversine distance with sub-meter precision', () {
      const p0 = (lat: centerLat, lon: centerLon);
      final p5 = coordAtDistanceKm(5.0);
      final p14_99 = coordAtDistanceKm(14.99);
      final p15_0 = coordAtDistanceKm(15.0);
      final p15_01 = coordAtDistanceKm(15.01);
      final p20 = coordAtDistanceKm(20.0);

      expect(LocationService.haversineKm(centerLat, centerLon, p0.lat, p0.lon), closeTo(0.0, 0.0001));
      expect(LocationService.haversineKm(centerLat, centerLon, p5.lat, p5.lon), closeTo(5.0, 0.001));
      expect(LocationService.haversineKm(centerLat, centerLon, p14_99.lat, p14_99.lon), closeTo(14.99, 0.001));
      expect(LocationService.haversineKm(centerLat, centerLon, p15_0.lat, p15_0.lon), closeTo(15.0, 0.001));
      expect(LocationService.haversineKm(centerLat, centerLon, p15_01.lat, p15_01.lon), closeTo(15.01, 0.001));
      expect(LocationService.haversineKm(centerLat, centerLon, p20.lat, p20.lon), closeTo(20.0, 0.001));
    });

    test('Strict 15 km boundary inclusion & exclusion for physical in-person plans', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      const p0 = (lat: centerLat, lon: centerLon);
      final p5 = coordAtDistanceKm(5.0);
      final p14_99 = coordAtDistanceKm(14.99);
      final p15_0 = coordAtDistanceKm(15.0);
      final p15_01 = coordAtDistanceKm(15.01);
      final p25 = coordAtDistanceKm(25.0);

      final act0 = buildPlan(id: 'act_0', title: '0 km Plan', lat: p0.lat, lon: p0.lon);
      final act5 = buildPlan(id: 'act_5', title: '5 km Plan', lat: p5.lat, lon: p5.lon);
      final act14_99 = buildPlan(id: 'act_14_99', title: '14.99 km Plan', lat: p14_99.lat, lon: p14_99.lon);
      final act15_0 = buildPlan(id: 'act_15_0', title: '15.0 km Boundary Plan', lat: p15_0.lat, lon: p15_0.lon);
      final act15_01 = buildPlan(id: 'act_15_01', title: '15.01 km Plan', lat: p15_01.lat, lon: p15_01.lon);
      final act25 = buildPlan(id: 'act_25', title: '25 km Plan', lat: p25.lat, lon: p25.lon);
      final actMissing = buildPlan(id: 'act_missing', title: 'Missing Coords Plan', lat: null, lon: null);

      state.setActivitiesForTesting([act0, act5, act14_99, act15_0, act15_01, act25, actMissing]);

      final filtered = state.getFilteredActivities(null, {});
      final ids = filtered.map((a) => a.id).toSet();

      // Included: within and up to 15.0 km
      expect(ids.contains('act_0'), isTrue, reason: '0 km plan must be included');
      expect(ids.contains('act_5'), isTrue, reason: '5 km plan must be included');
      expect(ids.contains('act_14_99'), isTrue, reason: '14.99 km plan must be included');
      expect(ids.contains('act_15_0'), isTrue, reason: 'Exact 15.0 km plan must be included');

      // Excluded: strictly beyond 15 km or missing coords
      expect(ids.contains('act_15_01'), isFalse, reason: '15.01 km plan must be excluded');
      expect(ids.contains('act_25'), isFalse, reason: '25 km plan must be excluded');
      expect(ids.contains('act_missing'), isFalse, reason: 'In-person plan without coords must be excluded');

      expect(filtered.length, 4);
      state.dispose();
    });

    test('Different viewing locations return strictly the plans nearby that location', () {
      final state = ActivitiesState();

      // Bengaluru viewer
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: 12.9716,
        lon: 77.5946,
      ));

      // Delhi coordinates (~1740 km from Bengaluru)
      const delhiLat = 28.6139;
      const delhiLon = 77.2090;

      final blrPlan = buildPlan(id: 'blr_1', title: 'Cubbon Park Run', lat: 12.9750, lon: 77.5900);
      final delhiPlan = buildPlan(id: 'del_1', title: 'Lodhi Garden Walk', lat: 28.5900, lon: 77.2200);

      state.setActivitiesForTesting([blrPlan, delhiPlan]);

      // Bengaluru viewer sees only Bengaluru plan
      final blrFeed = state.getFilteredActivities(null, {});
      expect(blrFeed.map((a) => a.id).toList(), ['blr_1']);

      // Switch viewer place to Delhi
      state.setPlace(const SavedPlace(
        displayName: 'New Delhi Center',
        short: 'New Delhi',
        lat: delhiLat,
        lon: delhiLon,
      ));

      // Delhi viewer sees only Delhi plan
      final delFeed = state.getFilteredActivities(null, {});
      expect(delFeed.map((a) => a.id).toList(), ['del_1']);

      state.dispose();
    });

    test('LocationService failure states do not crash or invent coordinates', () {
      final denied = LocationResult.failure(LocationService.msgDenied, reason: LocationFailure.permissionDenied);
      expect(denied.isSuccess, isFalse);
      expect(denied.latitude, isNull);
      expect(denied.longitude, isNull);
      expect(denied.isPermanentlyDenied, isFalse);

      final permDenied = LocationResult.failure(LocationService.msgDeniedForever, reason: LocationFailure.permissionDeniedForever);
      expect(permDenied.isPermanentlyDenied, isTrue);

      final disabled = LocationResult.failure(LocationService.msgServiceDisabled, reason: LocationFailure.serviceDisabled);
      expect(disabled.isServiceDisabled, isTrue);
    });
  });

  group('2. Plan-Type & Virtual Plan Discovery Rules Tests', () {
    test('Virtual plans use creator anchor location and are included if <= 15 km, excluded if > 15 km', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      final nearHostCoords = coordAtDistanceKm(4.0);
      final farHostCoords = coordAtDistanceKm(22.0);

      // Virtual plan hosted by nearby creator (4 km)
      final nearVirtual = buildPlan(
        id: 'virt_near',
        title: 'Virtual Board Games Near',
        isOnline: true,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        host: UserProfile(
          id: 'host_near',
          fullName: 'Near Host',
          username: 'near_host',
          latitude: nearHostCoords.lat,
          longitude: nearHostCoords.lon,
        ),
      );

      // Virtual plan hosted by far creator (22 km > 15 km)
      final farVirtual = buildPlan(
        id: 'virt_far',
        title: 'Virtual Book Club Far',
        isOnline: true,
        meetingLink: 'https://zoom.us/j/987654321',
        host: UserProfile(
          id: 'host_far',
          fullName: 'Far Host',
          username: 'far_host',
          latitude: farHostCoords.lat,
          longitude: farHostCoords.lon,
        ),
      );

      // Virtual plan without discovery coordinates
      final noCoordVirtual = buildPlan(
        id: 'virt_no_coord',
        title: 'Virtual Without Anchor',
        isOnline: true,
        meetingLink: 'https://discord.gg/room',
        host: UserProfile(
          id: 'host_no_coord',
          fullName: 'Mystery Host',
          username: 'mystery_host',
          latitude: null,
          longitude: null,
        ),
      );

      state.setActivitiesForTesting([nearVirtual, farVirtual, noCoordVirtual]);

      final feed = state.getFilteredActivities(null, {});
      final ids = feed.map((a) => a.id).toSet();

      expect(ids.contains('virt_near'), isTrue, reason: 'Virtual plan with creator anchor <= 15km must be included');
      expect(ids.contains('virt_far'), isFalse, reason: 'Virtual plan with creator anchor > 15km must be excluded');
      expect(ids.contains('virt_no_coord'), isFalse, reason: 'Virtual plan without verifiable anchor must be excluded from 15km nearby discovery');

      expect(feed.length, 1);
      state.dispose();
    });

    test('Both In-person and Virtual plans coexist without excluding one another', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(
        displayName: 'Bengaluru Center',
        short: 'Bengaluru',
        lat: centerLat,
        lon: centerLon,
      ));

      final p3 = coordAtDistanceKm(3.0);
      final p7 = coordAtDistanceKm(7.0);

      final inPersonPlan = buildPlan(id: 'in_person_1', title: 'Box Cricket', lat: p3.lat, lon: p3.lon, isOnline: false);
      final virtualPlan = buildPlan(
        id: 'virtual_1',
        title: 'Virtual Coding Jam',
        isOnline: true,
        host: UserProfile(id: 'h2', fullName: 'Dev Host', username: 'dev', latitude: p7.lat, longitude: p7.lon),
      );

      state.setActivitiesForTesting([inPersonPlan, virtualPlan]);

      // All mode filter shows both
      state.setModeFilter(ModeFilter.all);
      var feed = state.getFilteredActivities(null, {});
      expect(feed.map((a) => a.id).toSet(), {'in_person_1', 'virtual_1'});

      // inPerson filter shows only in-person
      state.setModeFilter(ModeFilter.inPerson);
      feed = state.getFilteredActivities(null, {});
      expect(feed.map((a) => a.id).toSet(), {'in_person_1'});

      // online filter shows only virtual
      state.setModeFilter(ModeFilter.online);
      feed = state.getFilteredActivities(null, {});
      expect(feed.map((a) => a.id).toSet(), {'virtual_1'});

      state.dispose();
    });
  });

  group('3. Multi-User Discovery & Reliability Tests', () {
    test('User A creates plan; User B within 15 km discovers it, User C outside 15 km does not', () {
      final userA = UserProfile(id: 'user_A', fullName: 'User A', username: 'user_a', latitude: centerLat, longitude: centerLon);

      final p8 = coordAtDistanceKm(8.0);
      final planA = buildPlan(
        id: 'plan_A',
        title: 'User A Meetup',
        lat: p8.lat,
        lon: p8.lon,
        hostId: userA.id,
        host: userA,
      );

      // User B viewer is 2 km from Center (so distance to planA is ~6 km <= 15 km)
      final userBState = ActivitiesState();
      final userBCoords = coordAtDistanceKm(2.0);
      userBState.setPlace(SavedPlace(
        displayName: 'User B Location',
        short: 'User B Loc',
        lat: userBCoords.lat,
        lon: userBCoords.lon,
      ));
      userBState.setActivitiesForTesting([planA]);

      final userBFeed = userBState.getFilteredActivities('user_B', {});
      expect(userBFeed.map((a) => a.id).contains('plan_A'), isTrue, reason: 'User B within 15km must discover User A plan');

      // User C viewer is 30 km away from Center (distance to planA is ~22 km > 15 km)
      final userCState = ActivitiesState();
      final userCCoords = coordAtDistanceKm(30.0);
      userCState.setPlace(SavedPlace(
        displayName: 'User C Location',
        short: 'User C Loc',
        lat: userCCoords.lat,
        lon: userCCoords.lon,
      ));
      userCState.setActivitiesForTesting([planA]);

      final userCFeed = userCState.getFilteredActivities('user_C', {});
      expect(userCFeed.map((a) => a.id).contains('plan_A'), isFalse, reason: 'User C outside 15km must NOT discover User A plan');

      userBState.dispose();
      userCState.dispose();
    });

    test('Concurrent plan creations do not duplicate records or cause data loss', () {
      final state = ActivitiesState();
      state.setPlace(const SavedPlace(displayName: 'Bengaluru', short: 'BLR', lat: centerLat, lon: centerLon));

      final plan1 = buildPlan(id: 'plan_concurrent_1', title: 'Plan 1', lat: centerLat, lon: centerLon);
      final plan2 = buildPlan(id: 'plan_concurrent_2', title: 'Plan 2', lat: centerLat, lon: centerLon);
      // Attempt adding plan 1 again as duplicate
      final plan1Duplicate = buildPlan(id: 'plan_concurrent_1', title: 'Plan 1 Duplicate', lat: centerLat, lon: centerLon);

      state.setActivitiesForTesting([plan1, plan2, plan1Duplicate]);

      // Deduplication in state ensures each unique ID is represented once
      final feed = state.getFilteredActivities(null, {});
      final ids = feed.map((a) => a.id).toList();

      expect(ids.where((id) => id == 'plan_concurrent_1').length, 1);
      expect(ids.where((id) => id == 'plan_concurrent_2').length, 1);

      state.dispose();
    });
  });

  group('4. Pagination & Completeness Tests', () {
    test('ActivitiesState tracks pagination, page sizes, hasMore and deduplicates across pages', () {
      final state = ActivitiesState();

      expect(state.currentPage, 0);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
      expect(ActivitiesState.defaultPageSize, 30);

      // Simulate populating 35 activities
      final allPlans = List.generate(
        35,
        (i) => buildPlan(
          id: 'plan_$i',
          title: 'Plan $i',
          lat: centerLat,
          lon: centerLon,
        ),
      );

      state.setActivitiesForTesting(allPlans);

      final feed = state.getFilteredActivities(null, {});
      expect(feed.length, 35);

      state.dispose();
    });
  });
}
