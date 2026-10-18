import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
    } catch (e, stackTrace) {
      debugPrint('Supabase initialization failed: $e');
      debugPrint('$stackTrace');
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
  /// Attempts PostGIS RPC `get_nearby_activities` first with pagination; falls back to indexed bounding-box query + virtual activities.
  static Future<List<dynamic>?> fetchNearbyActivities({
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    int limit = 50,
    int offset = 0,
  }) async {
    final c = client;
    if (c == null) return null;

    try {
      // 1. Try 5-arg RPC with pagination parameters
      final res = await c.rpc(
        'get_nearby_activities',
        params: {
          'user_lat': lat,
          'user_lng': lng,
          'radius_km': radiusKm,
          'limit_count': limit,
          'offset_count': offset,
        },
      );
      if (res is List<dynamic>) return res;
    } catch (_) {
      try {
        // Fallback to 3-arg RPC if remote db only has 3-argument signature
        final res3 = await c.rpc(
          'get_nearby_activities',
          params: {'user_lat': lat, 'user_lng': lng, 'radius_km': radiusKm},
        );
        if (res3 is List<dynamic>) {
          if (offset >= res3.length) return <dynamic>[];
          final end = (offset + limit < res3.length) ? offset + limit : res3.length;
          return res3.sublist(offset, end);
        }
      } catch (_) {
        try {
          final double latRad = lat * math.pi / 180.0;
          final double cosLat = math.cos(latRad).abs();
          final double safeCos = cosLat > 0.1 ? cosLat : 0.1;
          final double latDelta = radiusKm / 111.0;
          final double lngDelta = radiusKm / (111.0 * safeCos);

          final nearbyRes = await c
              .from('activities')
              .select('*, profiles_public(*)')
              .filter('deleted_at', 'is', null)
              .gte('latitude', lat - latDelta)
              .lte('latitude', lat + latDelta)
              .gte('longitude', lng - lngDelta)
              .lte('longitude', lng + lngDelta)
              .range(offset, offset + limit - 1)
              .order('date_time', ascending: true);

          final onlineRes = await c
              .from('activities')
              .select('*, profiles_public(*)')
              .filter('deleted_at', 'is', null)
              .eq('is_online', true)
              .range(offset, offset + limit - 1)
              .order('date_time', ascending: true);

          final combined = <dynamic>[];
          final seenIds = <dynamic>{};

          for (final item in nearbyRes) {
            if (item['id'] != null && seenIds.add(item['id'])) {
              combined.add(item);
            }
          }
          for (final item in onlineRes) {
            if (item['id'] != null && seenIds.add(item['id'])) {
              combined.add(item);
            }
          }

          return combined;
        } catch (_) {}
      }
    }
    return null;
  }

  /// Securely retrieves the meeting link for an online activity via security-definer RPC.
  /// Returns the link if the caller is the host or an accepted attendee; null otherwise.
  static Future<String?> getMeetingLink(String activityId) async {
    final c = client;
    if (c == null) return null;
    try {
      final res = await c.rpc(
        'get_meeting_link',
        params: {'_activity_id': activityId},
      );
      if (res is String && res.trim().isNotEmpty) {
        return res.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
