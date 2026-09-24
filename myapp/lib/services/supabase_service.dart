import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://ovknvssfrsuufuopbeqf.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_k8-EYhRp1ixYnTUCkWPaVQ_pbhzebqL';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Perform PostGIS spatial distance query for activities near (lat, lng) within radiusKm.
  /// Attempts PostGIS RPC `get_nearby_activities` first; falls back to indexed bounding-box query.
  static Future<List<dynamic>?> fetchNearbyActivities({
    required double lat,
    required double lng,
    double radiusKm = 25.0,
  }) async {
    final c = client;
    if (c == null) return null;

    try {
      final res = await c.rpc(
        'get_nearby_activities',
        params: {'user_lat': lat, 'user_lng': lng, 'radius_km': radiusKm},
      );
      if (res is List<dynamic>) return res;
    } catch (_) {
      try {
        final double latDelta = radiusKm / 111.0;
        final double lngDelta = radiusKm / (111.0 * 0.7);

        final res = await c
            .from('activities')
            .select('*, profiles_public(*)')
            .filter('deleted_at', 'is', null)
            .gte('latitude', lat - latDelta)
            .lte('latitude', lat + latDelta)
            .gte('longitude', lng - lngDelta)
            .lte('longitude', lng + lngDelta)
            .order('date_time', ascending: true);

        return res as List<dynamic>;
      } catch (_) {}
    }
    return null;
  }
}
