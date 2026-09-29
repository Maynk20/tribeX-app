import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Encapsulates a latitude/longitude result or an error message.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;

  const LocationResult._({this.latitude, this.longitude, this.error});

  factory LocationResult.success(double lat, double lon) =>
      LocationResult._(latitude: lat, longitude: lon);

  factory LocationResult.failure(String error) =>
      LocationResult._(error: error);

  bool get isSuccess => latitude != null && longitude != null && error == null;
}

/// Thin wrapper around [Geolocator] that handles permission checks and
/// returns a [LocationResult] with the user's current GPS position.
///
/// Does **not** fall back to hardcoded coordinates — callers must handle
/// the failure explicitly.
class LocationService {
  LocationService._();

  /// Request location permission (if needed) and return the device's current
  /// GPS position.  Returns [LocationResult.failure] with a user-friendly
  /// message when the location cannot be obtained.
  static Future<LocationResult> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check whether location services are enabled at the OS level.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(
        'Location services are disabled. Please enable GPS in your device settings.',
      );
    }

    // 2. Request permission if not already granted.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
          'Location permission was denied. Please allow location access to use this feature.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(
        'Location permission is permanently denied. Please enable it from app settings.',
      );
    }

    // 3. Obtain the current position.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult.success(position.latitude, position.longitude);
    } catch (e) {
      return LocationResult.failure(
        'Could not determine your location. Please try again.',
      );
    }
  }

  /// Reverse geocode (lat, lon) coordinates to human-readable place title & address.
  static Future<Map<String, String>?> reverseGeocode(
    double lat,
    double lon,
  ) async {
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
          final locality = props['locality']?.toString() ??
              props['suburb']?.toString() ??
              props['district']?.toString() ??
              '';
          final city = props['city']?.toString() ??
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

          return {'title': title, 'subtitle': subtitle};
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
        final road = address['road']?.toString() ??
            address['pedestrian']?.toString() ??
            '';
        final suburb = address['suburb']?.toString() ??
            address['neighbourhood']?.toString() ??
            '';
        final city = address['city']?.toString() ??
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

        return {'title': title, 'subtitle': subtitle};
      }
    } catch (_) {}

    return null;
  }

  /// Forward geocode an address/place name string to coordinates.
  /// Returns a map with 'title', 'subtitle', 'lat', 'lon' or null if not found.
  static Future<Map<String, dynamic>?> geocodeAddress(String query) async {
    final q = query.trim();
    if (q.length < 2) return null;

    // 1. Try Photon forward search
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lang=en&limit=1&lat=22.35&lon=78.66&location_bias_scale=0.4',
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];
        if (features.isNotEmpty) {
          final f = features.first;
          final coords = (f['geometry']['coordinates'] as List<dynamic>);
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final name =
              props['name']?.toString() ?? props['street']?.toString() ?? q;
          final city =
              props['city']?.toString() ?? props['state']?.toString() ?? '';
          return {
            'title': name,
            'subtitle': city.isNotEmpty ? city : 'India',
            'lat': lat,
            'lon': lon,
          };
        }
      }
    } catch (_) {}

    // 2. Fallback to Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=in&accept-language=en&q=${Uri.encodeComponent(q)}',
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
        if (data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return {
              'title':
                  item['display_name']?.toString().split(',').first.trim() ?? q,
              'subtitle': item['display_name']?.toString() ?? '',
              'lat': lat,
              'lon': lon,
            };
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
