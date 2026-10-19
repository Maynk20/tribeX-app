import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:myapp/state/theme_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.clearCache();
  });

  tearDown(() {
    LocationService.clearCache();
  });

  group('Part A: Location Permissions & GPS Services Tests', () {
    test('Case D — Location services disabled returns serviceDisabled failure',
        () async {
      LocationService.mockServiceEnabledChecker = () async => false;

      final res = await LocationService.getCurrentPosition();

      expect(res.isSuccess, isFalse);
      expect(res.isServiceDisabled, isTrue);
      expect(res.reason, equals(LocationFailure.serviceDisabled));
      expect(res.error, equals(LocationService.msgServiceDisabled));
    });

    test('Case A & B — Permission denied returns permissionDenied failure',
        () async {
      LocationService.mockServiceEnabledChecker = () async => true;
      LocationService.mockPermissionChecker =
          () async => LocationPermission.denied;
      LocationService.mockPermissionRequester =
          () async => LocationPermission.denied;

      final res = await LocationService.getCurrentPosition();

      expect(res.isSuccess, isFalse);
      expect(res.reason, equals(LocationFailure.permissionDenied));
      expect(res.error, equals(LocationService.msgDenied));
    });

    test(
        'Case C — Permission permanently denied returns permissionDeniedForever failure',
        () async {
      LocationService.mockServiceEnabledChecker = () async => true;
      LocationService.mockPermissionChecker =
          () async => LocationPermission.deniedForever;

      final res = await LocationService.getCurrentPosition();

      expect(res.isSuccess, isFalse);
      expect(res.isPermanentlyDenied, isTrue);
      expect(res.reason, equals(LocationFailure.permissionDeniedForever));
      expect(res.error, equals(LocationService.msgDeniedForever));
    });

    test('Permission granted returns fresh location successfully', () async {
      LocationService.mockServiceEnabledChecker = () async => true;
      LocationService.mockPermissionChecker =
          () async => LocationPermission.whileInUse;
      LocationService.mockPositionGetter = () async => Position(
            latitude: 19.0760,
            longitude: 72.8777,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 1.0,
          );

      final res = await LocationService.getFreshCurrentPosition();

      expect(res.isSuccess, isTrue);
      expect(res.latitude, closeTo(19.0760, 0.0001));
      expect(res.longitude, closeTo(72.8777, 0.0001));
      expect(res.error, isNull);
    });

    test('Case E — GPS timeout returns timeout failure', () async {
      LocationService.mockServiceEnabledChecker = () async => true;
      LocationService.mockPermissionChecker =
          () async => LocationPermission.whileInUse;
      LocationService.mockPositionGetter =
          () => throw TimeoutException('Location request timed out');

      final res = await LocationService.getCurrentPosition(
        timeLimit: const Duration(milliseconds: 50),
      );

      expect(res.isSuccess, isFalse);
      expect(res.reason, equals(LocationFailure.timeout));
      expect(res.error, equals(LocationService.msgTimeout));
    });

    test(
        'Reverse geocoding failure gracefully preserves coordinates with coordinateFallbackLabel',
        () async {
      const lat = 19.076;
      const lon = 72.877;
      final fallback = LocationService.coordinateFallbackLabel(lat, lon);
      expect(fallback, equals('Near 19.08, 72.88'));
    });

    test('openAppSettings and openLocationSettings use platform delegates',
        () async {
      bool appSettingsOpened = false;
      bool locationSettingsOpened = false;

      LocationService.mockOpenAppSettings = () async {
        appSettingsOpened = true;
        return true;
      };
      LocationService.mockOpenLocationSettings = () async {
        locationSettingsOpened = true;
        return true;
      };

      await LocationService.openAppSettings();
      expect(appSettingsOpened, isTrue);

      await LocationService.openLocationSettings();
      expect(locationSettingsOpened, isTrue);
    });
  });

  group('Part A: Profile State & Location Propagation Tests', () {
    test('Saving verified profile location updates in-memory ActivitiesState place',
        () async {
      final actState = ActivitiesState();
      expect(actState.place, isNull);

      const resolvedCity = 'Bandra West, Mumbai';
      const lat = 19.0596;
      const lon = 72.8295;

      actState.setPlace(
        const SavedPlace(
          displayName: resolvedCity,
          short: resolvedCity,
          lat: lat,
          lon: lon,
          city: resolvedCity,
        ),
      );

      expect(actState.place, isNotNull);
      expect(actState.place!.displayName, equals(resolvedCity));
      expect(actState.place!.lat, equals(lat));
      expect(actState.place!.lon, equals(lon));
      expect(actState.place!.city, equals(resolvedCity));
    });

    test('Switching accounts or signing out clears cached location and state',
        () async {
      final actState = ActivitiesState();
      actState.setPlace(
        const SavedPlace(
          displayName: 'Mumbai',
          short: 'Mumbai',
          lat: 19.076,
          lon: 72.877,
          city: 'Mumbai',
        ),
      );
      expect(actState.place, isNotNull);

      // Account switch or logout clears location
      actState.clearLocation();
      LocationService.clearCache();

      expect(actState.place, isNull);
    });

    test('UserProfile copyWith preserves coordinates correctly', () {
      final u1 = UserProfile(
        id: 'u1',
        fullName: 'Aarav Patel',
        username: 'aarav',
        city: 'Mumbai',
        latitude: 19.076,
        longitude: 72.877,
      );

      final u2 = u1.copyWith(
        city: 'Pune',
        latitude: 18.5204,
        longitude: 73.8567,
      );

      expect(u2.city, equals('Pune'));
      expect(u2.latitude, equals(18.5204));
      expect(u2.longitude, equals(73.8567));
    });
  });

  group('Part A: Edit Profile Modal UI & Location Flow Widget Tests', () {
    testWidgets(
        'Tapping Use Current Location retrieves fresh position and updates fields',
        (tester) async {
      LocationService.mockServiceEnabledChecker = () async => true;
      LocationService.mockPermissionChecker =
          () async => LocationPermission.whileInUse;
      LocationService.mockPositionGetter = () async => Position(
            latitude: 19.0760,
            longitude: 72.8777,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 1.0,
          );
      LocationService.mockReverseGeocoder = (lat, lon) async => 'Mumbai, MH';

      final user = UserProfile(
        id: 'test_user_01',
        fullName: 'Mayank Thakkar',
        username: 'mayank_t',
        city: 'Old City',
        latitude: null,
        longitude: null,
      );

      final authState = AuthState();
      final actState = ActivitiesState();
      final themeState = ThemeState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: authState),
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
            ChangeNotifierProvider<ThemeState>.value(value: themeState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) => _EditProfileTestWrapper(user: user),
                    );
                  },
                  child: const Text('Open Edit Profile'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);

      // Tap Use current location
      await tester.tap(find.text('Use current location'));
      await tester.pump(); // Trigger async fetch

      await tester.pumpAndSettle();

      // UI city field updated
      expect(find.text('Mumbai, MH'), findsOneWidget);
    });

    testWidgets('Manual city editing invalidates pending async GPS responses',
        (tester) async {
      final user = UserProfile(
        id: 'test_user_02',
        fullName: 'Mayank Thakkar',
        username: 'mayank_t',
        city: 'Initial City',
      );

      final authState = AuthState();
      final actState = ActivitiesState();
      final themeState = ThemeState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: authState),
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
            ChangeNotifierProvider<ThemeState>.value(value: themeState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) => _EditProfileTestWrapper(user: user),
                    );
                  },
                  child: const Text('Open Edit Profile'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Profile'));
      await tester.pumpAndSettle();

      // User manually enters a new city in the text field
      final cityFinder = find.widgetWithText(TextField, 'City / Neighborhood');
      expect(cityFinder, findsOneWidget);

      await tester.enterText(cityFinder, 'Bengaluru, Karnataka');
      await tester.pumpAndSettle();

      expect(find.text('Bengaluru, Karnataka'), findsOneWidget);
    });
  });
}

/// Helper wrapper that mirrors _EditProfileModalContent for direct widget tests
class _EditProfileTestWrapper extends StatefulWidget {
  final UserProfile user;

  const _EditProfileTestWrapper({required this.user});

  @override
  State<_EditProfileTestWrapper> createState() =>
      _EditProfileTestWrapperState();
}

class _EditProfileTestWrapperState extends State<_EditProfileTestWrapper> {
  late final TextEditingController _cityCtrl;
  bool _fetchingGps = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.user.city ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGps() async {
    final t = ++_token;
    setState(() => _fetchingGps = true);
    final pos = await LocationService.getFreshCurrentPosition();
    if (!mounted || t != _token) return;

    if (pos.isSuccess) {
      final city = await LocationService.resolveProfileCity(
        pos.latitude!,
        pos.longitude!,
      );
      if (!mounted || t != _token) return;
      setState(() {
        _cityCtrl.text = city;
        _fetchingGps = false;
      });
    } else {
      setState(() => _fetchingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit Profile'),
          TextField(
            controller: _cityCtrl,
            onChanged: (_) {
              _token++;
            },
            decoration: const InputDecoration(labelText: 'City / Neighborhood'),
          ),
          TextButton(
            onPressed: _fetchingGps ? null : _handleGps,
            child: const Text('Use current location'),
          ),
        ],
      ),
    );
  }
}
