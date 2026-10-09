import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Why a location lookup failed. Lets the UI react appropriately (e.g. offer
/// an "Open settings" action only when permission is permanently denied).
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

/// Encapsulates a latitude/longitude result or an error message.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  final LocationFailure? reason;

  const LocationResult._({
    this.latitude,
    this.longitude,
    this.error,
    this.reason,
  });

  factory LocationResult.success(double lat, double lon) =>
      LocationResult._(latitude: lat, longitude: lon);

  factory LocationResult.failure(
    String error, {
    LocationFailure reason = LocationFailure.unavailable,
  }) => LocationResult._(error: error, reason: reason);

  bool get isSuccess => latitude != null && longitude != null && error == null;

  bool get isPermanentlyDenied =>
      reason == LocationFailure.permissionDeniedForever;

  bool get isServiceDisabled => reason == LocationFailure.serviceDisabled;
}

/// A user-chosen or GPS-resolved place. Mirrors the TanStack `Place` type
/// (`src/components/place-search.tsx`) and is persisted under the same
/// `lobby:place` key so behaviour matches the web app.
class SavedPlace {
  final String displayName;
  final String short;
  final double lat;
  final double lon;
  final String city;
  final String? state;
  final String? postcode;

  const SavedPlace({
    required this.displayName,
    required this.short,
    required this.lat,
    required this.lon,
    this.city = '',
    this.state,
    this.postcode,
  });

  /// Label shown in the header chip — same precedence as TanStack `setPlace`:
  /// `short || city || display_name.split(",")[0]`.
  String get label => LocationService.firstNonEmpty([
    short,
    city,
    displayName.split(',').first.trim(),
  ]);

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    'short': short,
    'lat': lat,
    'lon': lon,
    'city': city,
    if (state != null) 'state': state,
    if (postcode != null) 'postcode': postcode,
  };

  /// Returns null when the stored JSON is malformed (TanStack silently
  /// ignores a corrupt `lobby:place` entry; so do we).
  static SavedPlace? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lon = json['lon'];
    if (lat is! num || lon is! num) return null;
    if (!lat.isFinite || !lon.isFinite) return null;
    return SavedPlace(
      displayName: json['display_name']?.toString() ?? '',
      short: json['short']?.toString() ?? '',
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
    );
  }
}

/// Thin wrapper around [Geolocator] that handles permission checks and
/// returns a [LocationResult] with the user's current GPS position.
///
/// Does **not** fall back to hardcoded coordinates — callers must handle
/// the failure explicitly.
class LocationService {
  LocationService._();

  // TanStack-equivalent user-facing messages (src/lib/services.ts).
  static const String msgServiceDisabled =
      'Location services are disabled. Please enable GPS in your device settings.';
  static const String msgDenied =
      'Location permission was denied. Please allow location access to use this feature.';
  static const String msgDeniedForever =
      'Location permission is permanently denied. Please enable it from app settings.';
  static const String msgTimeout =
      'Getting your location is taking too long. Move near a window or try again.';
  static const String msgUnavailable =
      'Location unavailable. Check that GPS is on and try again.';

  static const Map<String, String> _nominatimHeaders = {
    'Accept': 'application/json',
    // Nominatim's usage policy requires an identifying UA. Browsers forbid
    // setting it, so only send it on native platforms.
    if (!kIsWeb) 'User-Agent': 'tribeX-app/1.0.0 (contact@tribex.app)',
  };

  // Cache structures with TTL (15 minutes) to avoid repeated hits to OSM/Photon
  static final Map<String, ({SavedPlace place, DateTime timestamp})>
  _resolvedPlaceCache = {};
  static final Map<String, ({String city, DateTime timestamp})> _cityCache = {};
  static final Map<String, ({Map<String, String> data, DateTime timestamp})>
  _reverseCache = {};
  static final Map<String, ({Map<String, dynamic> data, DateTime timestamp})>
  _forwardCache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  /// Clears in-memory geocoding and position caches (useful on logout / testing)
  static void clearCache() {
    _resolvedPlaceCache.clear();
    _cityCache.clear();
    _reverseCache.clear();
    _forwardCache.clear();
  }

  static String _roundCoordKey(double lat, double lon) =>
      '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';

  /// JS-style `a || b || c` over strings: first non-empty (trimmed) value.
  static String firstNonEmpty(Iterable<String?> values) {
    for (final v in values) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  /// Fallback label used when reverse geocoding fails — identical to TanStack:
  /// `Near ${lat.toFixed(2)}, ${lon.toFixed(2)}`.
  static String coordinateFallbackLabel(double lat, double lon) =>
      'Near ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';

  /// Header-chip label from a Nominatim `address` object.
  /// Exact port of `requestBrowserLocation` in `src/hooks/use-location.ts`.
  static ({String label, String city}) feedLabelFromAddress(
    Map<String, dynamic> a,
  ) {
    String s(String k) => a[k]?.toString() ?? '';
    final city = firstNonEmpty([
      s('city'),
      s('town'),
      s('village'),
      s('hamlet'),
      s('suburb'),
      s('county'),
      s('state'),
    ]);
    final short = firstNonEmpty([
      s('suburb'),
      s('neighbourhood'),
      s('village'),
      s('hamlet'),
      s('town'),
      s('city'),
      city,
    ]);
    final label = short.isNotEmpty && city.isNotEmpty && short != city
        ? '$short, $city'
        : firstNonEmpty([short, city, 'Your location']);
    return (label: label, city: city);
  }

  /// Profile `city` value from a Nominatim response.
  /// Exact port of `saveVerifiedProfileLocation` in `src/lib/services.ts`.
  static String profileCityFromAddress(
    Map<String, dynamic> a, {
    String? displayName,
    required String fallback,
  }) {
    String s(String k) => a[k]?.toString() ?? '';
    final locality = firstNonEmpty([
      s('suburb'),
      s('neighbourhood'),
      s('village'),
      s('hamlet'),
      s('town'),
      s('city'),
    ]);
    final cityName = firstNonEmpty([
      s('city'),
      s('town'),
      s('village'),
      s('county'),
      s('state'),
    ]);
    if (locality.isNotEmpty && cityName.isNotEmpty && locality != cityName) {
      return '$locality, $cityName';
    }
    return firstNonEmpty([locality, cityName, displayName, fallback]);
  }

  /// Great-circle distance in kilometres (same formula as the backend
  /// `haversine_m` SQL function, divided by 1000).
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0088;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Checks whether location service is enabled and permission is granted,
  /// without popping any permission prompt dialogs.
  static Future<bool> hasLocationPermission() async {
    if (kIsWeb) return false;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      final perm = await Geolocator.checkPermission();
      return perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Request location permission (if needed) and return the device's current
  /// GPS position. Returns [LocationResult.failure] with a user-friendly
  /// message when the location cannot be obtained.
  ///
  /// [maxAge] mirrors the browser `maximumAge` option: a cached fix younger
  /// than this is returned immediately instead of waiting for a new one.
  static Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
    Duration? maxAge,
  }) async {
    // 1 & 2: Mobile platforms check OS location service and app permissions first.
    // On Web, navigator.geolocation directly handles the browser permission prompt
    // when getCurrentPosition() is called.
    if (!kIsWeb) {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) {
          return LocationResult.failure(
            msgServiceDisabled,
            reason: LocationFailure.serviceDisabled,
          );
        }
      } catch (_) {
        return LocationResult.failure(
          msgUnavailable,
          reason: LocationFailure.unavailable,
        );
      }

      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return LocationResult.failure(
              msgDenied,
              reason: LocationFailure.permissionDenied,
            );
          }
        }
      } catch (_) {
        return LocationResult.failure(
          msgDenied,
          reason: LocationFailure.permissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.failure(
          msgDeniedForever,
          reason: LocationFailure.permissionDeniedForever,
        );
      }
    }

    // 3. Serve a recent cached fix when allowed (not supported on web).
    if (maxAge != null && !kIsWeb) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            DateTime.now().difference(last.timestamp).abs() <= maxAge) {
          return LocationResult.success(last.latitude, last.longitude);
        }
      } catch (_) {
        // fall through to a fresh fix
      }
    }

    // 4. Obtain the current position.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return LocationResult.success(position.latitude, position.longitude);
    } on TimeoutException {
      // Graceful fallback: If fresh satellite acquisition timed out, try last known position
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            return LocationResult.success(last.latitude, last.longitude);
          }
        } catch (_) {}
      }
      return LocationResult.failure(
        msgTimeout,
        reason: LocationFailure.timeout,
      );
    } on LocationServiceDisabledException {
      return LocationResult.failure(
        msgServiceDisabled,
        reason: LocationFailure.serviceDisabled,
      );
    } on PermissionDeniedException {
      return LocationResult.failure(
        msgDenied,
        reason: LocationFailure.permissionDenied,
      );
    } catch (_) {
      // Attempt last known fix as fallback on unexpected platform failure
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            return LocationResult.success(last.latitude, last.longitude);
          }
        } catch (_) {}
      }
      return LocationResult.failure(
        msgUnavailable,
        reason: LocationFailure.unavailable,
      );
    }
  }

  /// Two-stage lookup used for the profile location and mirrors TanStack
  /// `getCurrentCoords`: a fast low-power read accepting a fix up to 10 min
  /// old (12 s window), then a longer 20 s window accepting any cached fix.
  /// Permission / service errors are returned immediately without retrying.
  static Future<LocationResult> getProfileCoords() async {
    final first = await getCurrentPosition(
      accuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 12),
      maxAge: const Duration(minutes: 10),
    );
    if (first.isSuccess) return first;
    if (first.reason != LocationFailure.timeout &&
        first.reason != LocationFailure.unavailable) {
      return first;
    }
    // maximumAge: Infinity → any last-known fix is acceptable.
    return getCurrentPosition(
      accuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 20),
      maxAge: const Duration(days: 3650),
    );
  }

  /// Resolve the device location into a [SavedPlace] for the Explore header.
  /// Uses cached reverse geocode if queried within 15 minutes for similar coords.
  static Future<({SavedPlace? place, LocationResult result})>
  resolveCurrentPlace() async {
    final result = await getCurrentPosition(
      accuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
      maxAge: const Duration(seconds: 60),
    );
    if (!result.isSuccess) return (place: null, result: result);

    final lat = result.latitude!;
    final lon = result.longitude!;
    final cacheKey = _roundCoordKey(lat, lon);
    final cached = _resolvedPlaceCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return (place: cached.place, result: result);
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=$lat&lon=$lon&accept-language=en',
      );
      final res = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final a = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final built = feedLabelFromAddress(a);
        final place = SavedPlace(
          displayName: data['display_name']?.toString() ?? built.label,
          short: built.label,
          lat: lat,
          lon: lon,
          city: built.city,
          state: a['state']?.toString(),
          postcode: a['postcode']?.toString(),
        );
        _resolvedPlaceCache[cacheKey] = (
          place: place,
          timestamp: DateTime.now(),
        );
        return (place: place, result: result);
      }
    } catch (_) {
      // fall through to coordinate label
    }
    final fallback = coordinateFallbackLabel(lat, lon);
    final place = SavedPlace(
      displayName: fallback,
      short: fallback,
      lat: lat,
      lon: lon,
    );
    _resolvedPlaceCache[cacheKey] = (place: place, timestamp: DateTime.now());
    return (place: place, result: result);
  }

  /// Reverse geocode for the profile `city` column, capped at 3 s exactly like
  /// TanStack so the save flow never hangs; falls back to `Near lat, lon`.
  static Future<String> resolveProfileCity(double lat, double lon) async {
    final cacheKey = _roundCoordKey(lat, lon);
    final cached = _cityCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.city;
    }

    final fallback = coordinateFallbackLabel(lat, lon);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=$lat&lon=$lon&accept-language=en',
      );
      final res = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final a = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final city = profileCityFromAddress(
          a,
          displayName: data['display_name']?.toString(),
          fallback: fallback,
        );
        _cityCache[cacheKey] = (city: city, timestamp: DateTime.now());
        return city;
      }
    } catch (_) {
      // keep coordinate fallback
    }
    _cityCache[cacheKey] = (city: fallback, timestamp: DateTime.now());
    return fallback;
  }

  /// Open the OS app-settings page (used after a permanent denial).
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open the OS location-services settings page (used when GPS is off).
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Reverse geocode (lat, lon) coordinates to human-readable place title & address.
  static Future<Map<String, String>?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    final cacheKey = _roundCoordKey(lat, lon);
    final cached = _reverseCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.data;
    }

    // 1. Try Photon reverse geocoding
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/reverse?lat=$lat&lon=$lon',
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];
        if (features.isNotEmpty) {
          final props =
              (features.first['properties'] as Map<String, dynamic>?) ?? {};
          final name =
              props['name']?.toString() ?? props['street']?.toString() ?? '';
          final locality =
              props['locality']?.toString() ??
              props['suburb']?.toString() ??
              props['district']?.toString() ??
              '';
          final city =
              props['city']?.toString() ??
              props['town']?.toString() ??
              props['village']?.toString() ??
              '';
          final state = props['state']?.toString() ?? '';
          final postcode = props['postcode']?.toString() ?? '';

          final title = name.isNotEmpty
              ? (locality.isNotEmpty && locality != name
                    ? '$name, $locality'
                    : name)
              : (locality.isNotEmpty
                    ? locality
                    : (city.isNotEmpty ? city : 'Current Location'));

          final subtitleParts = [
            if (city.isNotEmpty && city != locality && city != title) city,
            if (state.isNotEmpty) state,
            if (postcode.isNotEmpty) postcode,
          ];
          final subtitle = subtitleParts.isNotEmpty
              ? subtitleParts.join(', ')
              : 'Near ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

          final result = {'title': title, 'subtitle': subtitle};
          _reverseCache[cacheKey] = (data: result, timestamp: DateTime.now());
          return result;
        }
      }
    } catch (_) {}

    // 2. Fallback to OpenStreetMap Nominatim reverse geocoding
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'tribeX-app/1.0.0 (contact@tribex.app)',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = (data['address'] as Map<String, dynamic>?) ?? {};
        final road =
            address['road']?.toString() ??
            address['pedestrian']?.toString() ??
            '';
        final suburb =
            address['suburb']?.toString() ??
            address['neighbourhood']?.toString() ??
            '';
        final city =
            address['city']?.toString() ??
            address['town']?.toString() ??
            address['village']?.toString() ??
            '';
        final state = address['state']?.toString() ?? '';
        final postcode = address['postcode']?.toString() ?? '';

        final title = road.isNotEmpty
            ? (suburb.isNotEmpty ? '$road, $suburb' : road)
            : (suburb.isNotEmpty
                  ? suburb
                  : (city.isNotEmpty ? city : 'Current Location'));

        final subtitleParts = [
          if (suburb.isNotEmpty && suburb != title) suburb,
          if (city.isNotEmpty && city != suburb && city != title) city,
          if (state.isNotEmpty) state,
          if (postcode.isNotEmpty) postcode,
        ];
        final subtitle = subtitleParts.isNotEmpty
            ? subtitleParts.join(', ')
            : (data['display_name']?.toString() ??
                  'Near ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}');

        final result = {'title': title, 'subtitle': subtitle};
        _reverseCache[cacheKey] = (data: result, timestamp: DateTime.now());
        return result;
      }
    } catch (_) {}

    return null;
  }

  /// Calculates great-circle distance between two coordinate pairs in kilometers using the Haversine formula.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0; // Earth mean radius in kilometers
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Validates that coordinates fall within India's geographic bounding box
  /// (Latitude: 6.5° N - 37.5° N, Longitude: 68.0° E - 97.5° E).
  static bool isInIndia(
    double lat,
    double lon, {
    String? countryCode,
    String? country,
  }) {
    if (lat < 6.5 || lat > 37.5 || lon < 68.0 || lon > 97.5) {
      return false;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      if (countryCode.toLowerCase() != 'in') return false;
    }
    if (country != null && country.isNotEmpty) {
      final c = country.toLowerCase();
      if (!c.contains('india') && !c.contains('bharat')) return false;
    }
    return true;
  }

  /// Forward geocode an address/place name string to coordinates.
  /// Returns a map with 'title', 'subtitle', 'lat', 'lon' or null if not found.
  static Future<Map<String, dynamic>?> geocodeAddress(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return null;

    final cached = _forwardCache[q];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.data;
    }

    // 1. Try Photon forward search with India bbox
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lang=en&limit=3&lat=22.35&lon=78.66&bbox=68.0,6.5,97.5,37.5',
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];
        for (final f in features) {
          final coords = (f['geometry']['coordinates'] as List<dynamic>);
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final props = f['properties'] as Map<String, dynamic>? ?? {};

          if (!isInIndia(
            lat,
            lon,
            countryCode: props['countrycode']?.toString(),
            country: props['country']?.toString(),
          )) {
            continue;
          }

          final name =
              props['name']?.toString() ?? props['street']?.toString() ?? q;
          final locality =
              props['locality']?.toString() ??
              props['suburb']?.toString() ??
              props['district']?.toString() ??
              '';
          final city =
              props['city']?.toString() ?? props['state']?.toString() ?? '';
          final postcode = props['postcode']?.toString() ?? '';

          final subtitleParts = <String>[];
          if (locality.isNotEmpty && locality != name) {
            subtitleParts.add(locality);
          }
          if (city.isNotEmpty && city != locality && city != name) {
            subtitleParts.add(city);
          }
          if (postcode.isNotEmpty) {
            subtitleParts.add(postcode);
          }

          final result = {
            'title': name,
            'subtitle': subtitleParts.isNotEmpty
                ? subtitleParts.join(', ')
                : 'India',
            'lat': lat,
            'lon': lon,
          };
          _forwardCache[q] = (data: result, timestamp: DateTime.now());
          return result;
        }
      }
    } catch (_) {}

    // 2. Fallback to Nominatim restricted to India
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&limit=3&countrycodes=in&addressdetails=1&accept-language=en&q=${Uri.encodeComponent(q)}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'tribeX-app/1.0.0 (contact@tribex.app)',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '');
          final lon = double.tryParse(map['lon']?.toString() ?? '');
          if (lat != null && lon != null && isInIndia(lat, lon)) {
            final address = map['address'] as Map<String, dynamic>? ?? {};
            final displayName = map['display_name']?.toString() ?? q;
            final firstPart = displayName.split(',').first.trim();
            final result = {
              'title': firstPart.isNotEmpty ? firstPart : q,
              'subtitle': displayName,
              'lat': lat,
              'lon': lon,
              if (address['postcode'] != null)
                'postcode': address['postcode'].toString(),
            };
            _forwardCache[q] = (data: result, timestamp: DateTime.now());
            return result;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
