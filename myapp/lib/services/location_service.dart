import 'package:geolocator/geolocator.dart';

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
}
