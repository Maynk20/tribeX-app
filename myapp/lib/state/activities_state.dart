import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../models/join_request.dart';
import '../models/user_profile.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

enum SortKey { date, distance, popularity }

/// Structured result from the check_in_activity RPC.
class CheckInResult {
  /// 'checked_in', 'already', 'too_far', or 'error'.
  final String status;
  final double? distanceM;
  final String? errorMessage;

  const CheckInResult({
    required this.status,
    this.distanceM,
    this.errorMessage,
  });

  bool get isSuccess => status == 'checked_in';
  bool get isAlready => status == 'already';
  bool get isTooFar => status == 'too_far';
  bool get isError => status == 'error';
}

enum ModeFilter { all, inPerson, online }

enum FeedScope { discover, joined, hosting }

class ActivitiesState extends ChangeNotifier {
  List<Activity> _activities = [];
  List<JoinRequest> _joinRequests = [];
  Map<String, List<JoinRequest>> _requestsByActivity = const {};
  Map<String, JoinRequest> _userRequestIndex = const {};
  Map<String, int> _pendingCountByActivity = const {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  final Set<String> _pendingJoinRequests = {};
  final Set<String> _pendingRespondRequests = {};

  // Pagination state
  static const int defaultPageSize = 30;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isSpatialResult = false;
  final Set<String> _spatiallyVerifiedIds = {};
  bool _isLocationRestored = false;
  Completer<void>? _locationRestoreCompleter;

  // Memoization Cache for Filtered Activities
  List<Activity>? _cachedFilteredActivities;
  String? _cachedCurrentUserId;
  Set<String>? _cachedBlockedIds;
  bool? _cachedApplyRadiusFilter;
  bool _filterCacheValid = false;

  RealtimeChannel? _activitiesChannel;
  RealtimeChannel? _joinRequestsChannel;

  // Cached user profiles for hosts and requesters
  final Map<String, UserProfile> _profileCache = {};
  UserProfile? getCachedProfile(String userId) => _profileCache[userId];
  void cacheUserProfile(UserProfile profile) => _profileCache[profile.id] = profile;

  Future<UserProfile?> fetchUserProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    final client = SupabaseService.client;
    if (client == null || userId.isEmpty) return null;
    try {
      dynamic profRes;
      try {
        profRes = await client
            .from('profiles_public')
            .select('id, full_name, username, avatar_url, rating, is_verified')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        try {
          profRes = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url')
              .eq('id', userId)
              .maybeSingle();
        } catch (_) {
          profRes = await client
              .from('profiles')
              .select('id, full_name, username, avatar_url')
              .eq('id', userId)
              .maybeSingle();
        }
      }
      if (profRes != null && profRes is Map<String, dynamic>) {
        final prof = UserProfile.fromJson(profRes);
        _profileCache[userId] = prof;
        return prof;
      }
    } catch (_) {}
    return null;
  }

  void _invalidateFilterCache() {
    _filterCacheValid = false;
    _cachedFilteredActivities = null;
    _cachedApplyRadiusFilter = null;
  }

  void _rebuildJoinRequestIndices() {
    final byActivity = <String, List<JoinRequest>>{};
    final userIdx = <String, JoinRequest>{};
    final pendingCounts = <String, int>{};

    for (final req in _joinRequests) {
      byActivity.putIfAbsent(req.activityId, () => []).add(req);
      userIdx['${req.activityId}:${req.userId}'] = req;
      if (req.status == JoinStatus.pending) {
        pendingCounts[req.activityId] =
            (pendingCounts[req.activityId] ?? 0) + 1;
      }
    }

    _requestsByActivity = byActivity;
    _userRequestIndex = userIdx;
    _pendingCountByActivity = pendingCounts;
    _invalidateFilterCache();
  }

  // Search & Filter State
  String _selectedGroup = "All";
  String _selectedCategory = "All";
  ModeFilter _modeFilter = ModeFilter.all;
  String _searchQuery = "";
  SortKey _sortKey = SortKey.date;
  FeedScope _scope = FeedScope.discover;

  // Location — mirrors TanStack `useLocation` (src/hooks/use-location.ts):
  // a human label (default DEFAULT_CITY) plus an optional chosen place with
  // coordinates. No coordinates are invented when nothing has been chosen.
  static const String defaultCity = 'Bengaluru';
  static const double defaultRadiusKm = 15.0;
  static const String locationPrefsKey = 'lobby:location';
  static const String placePrefsKey = 'lobby:place';
  String _location = defaultCity;
  SavedPlace? _place;
  double _radiusKm = defaultRadiusKm;
  bool _locationTouched = false;

  // Quick Filters
  bool _freeOnly = false;
  bool _spotsOnly = false;
  bool _todayOnly = false;
  bool _weekendOnly = false;
  bool _verifiedHostsOnly = false;

  ActivitiesState() {
    _init();
  }

  Future<void> _init() async {
    await restoreLocation();
    final client = SupabaseService.client;
    final currentUid = client?.auth.currentUser?.id;
    if (currentUid != null) {
      await fetchActivities();
      _subscribeRealtime();
    }
  }

  void clearActivities() {
    _activities = [];
    _joinRequests = [];
    _isSpatialResult = false;
    _spatiallyVerifiedIds.clear();
    _currentPage = 0;
    _hasMore = false;
    _error = null;
    _activitiesChannel?.unsubscribe();
    _joinRequestsChannel?.unsubscribe();
    _activitiesChannel = null;
    _joinRequestsChannel = null;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  // Getters
  List<Activity> get activities => List.unmodifiable(_activities);
  List<JoinRequest> get joinRequests => List.unmodifiable(_joinRequests);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get error => _error;

  String get selectedGroup => _selectedGroup;
  String get selectedCategory => _selectedCategory;
  ModeFilter get modeFilter => _modeFilter;
  String get searchQuery => _searchQuery;
  SortKey get sortKey => _sortKey;
  FeedScope get scope => _scope;
  String get location => _location;

  /// The chosen/GPS place with coordinates, or null when only the default
  /// city label is in use.
  SavedPlace? get place => _place;

  /// Default 15.0 km radius from user's current GPS or selected location.
  double get radiusKm => _radiusKm;

  void setRadiusKm(double km) {
    if (_radiusKm == km) return;
    _radiusKm = km;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
    fetchActivities();
  }

  @visibleForTesting
  void setActivitiesForTesting(List<Activity> acts, {bool isSpatial = false}) {
    final deduplicated = <String, Activity>{};
    for (final a in acts) {
      if (a.id.isNotEmpty) {
        deduplicated[a.id] = a;
      }
    }
    _activities = deduplicated.values.toList();
    _isSpatialResult = isSpatial;
    _spatiallyVerifiedIds.clear();
    if (isSpatial) {
      _spatiallyVerifiedIds.addAll(deduplicated.keys);
    }
    _currentPage = 0;
    _hasMore = false;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  @visibleForTesting
  void handleRealtimeActivityChangeForTesting({
    required PostgresChangeEvent eventType,
    Map<String, dynamic> newRecord = const {},
    Map<String, dynamic> oldRecord = const {},
  }) {
    _onRealtimeActivityChange(
      PostgresChangePayload(
        eventType: eventType,
        newRecord: newRecord,
        oldRecord: oldRecord,
        schema: 'public',
        table: 'activities',
        commitTimestamp: DateTime.now(),
        errors: const [],
      ),
    );
  }

  bool get freeOnly => _freeOnly;
  bool get spotsOnly => _spotsOnly;
  bool get todayOnly => _todayOnly;
  bool get weekendOnly => _weekendOnly;
  bool get verifiedHostsOnly => _verifiedHostsOnly;

  int get activeFilterCount {
    int count = 0;
    if (_freeOnly) count++;
    if (_spotsOnly) count++;
    if (_todayOnly) count++;
    if (_weekendOnly) count++;
    if (_verifiedHostsOnly) count++;
    return count;
  }

  /// Restore the persisted label/place (TanStack reads localStorage on mount).
  Future<void> restoreLocation() async {
    if (_isLocationRestored) return;
    if (_locationRestoreCompleter != null) {
      return _locationRestoreCompleter!.future;
    }
    _locationRestoreCompleter = Completer<void>();
    try {
      final prefs = await SharedPreferences.getInstance();
      // Don't clobber a location the user picked while prefs were loading.
      if (!_isDisposed && !_locationTouched) {
        final saved = prefs.getString(locationPrefsKey);
        final savedPlace = prefs.getString(placePrefsKey);
        var changed = false;
        if (saved != null && saved.trim().isNotEmpty) {
          _location = saved;
          changed = true;
        }
        if (savedPlace != null) {
          try {
            final p = SavedPlace.tryFromJson(jsonDecode(savedPlace));
            if (p != null) {
              _place = p;
              changed = true;
            }
          } catch (_) {
            // corrupt entry — ignore, same as TanStack
          }
        }
        if (changed) {
          _invalidateFilterCache();
          notifyListeners();
        }
      }
    } catch (_) {
      // storage unavailable — safe to ignore
    } finally {
      _isLocationRestored = true;
      if (!(_locationRestoreCompleter?.isCompleted ?? true)) {
        _locationRestoreCompleter!.complete();
      }
    }
  }

  Future<void> _persistLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(locationPrefsKey, _location);
      final p = _place;
      if (p != null) {
        await prefs.setString(placePrefsKey, jsonEncode(p.toJson()));
      }
    } catch (_) {
      // storage unavailable — safe to ignore
    }
  }

  /// Set only the label (TanStack `setLocation`). Empty input falls back to
  /// the default city. If [lat]/[lng] are supplied, behaves like [setPlace].
  void setLocation(String loc, {double? lat, double? lng}) {
    if (lat != null && lng != null) {
      final label = loc.trim().isNotEmpty ? loc.trim() : defaultCity;
      setPlace(
        SavedPlace(displayName: label, short: label, lat: lat, lon: lng),
      );
      return;
    }
    _locationTouched = true;
    _location = loc.trim().isNotEmpty ? loc.trim() : defaultCity;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
    unawaited(_persistLocation());
  }

  /// Choose a place with coordinates (TanStack `setPlace`).
  void setPlace(SavedPlace next) {
    _locationTouched = true;
    _place = next;
    final label = next.label;
    _location = label.isNotEmpty ? label : defaultCity;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
    unawaited(_persistLocation());
    fetchActivities();
  }

  /// Reset to the default city and forget the stored place
  /// (TanStack `clearLocation`, called on sign-out).
  void clearLocation() {
    _locationTouched = true;
    _location = defaultCity;
    _place = null;
    _isLocationRestored = true;
    _isSpatialResult = false;
    _spatiallyVerifiedIds.clear();
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
    fetchActivities();
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(locationPrefsKey);
        await prefs.remove(placePrefsKey);
      } catch (_) {
        // ignore
      }
    }());
  }

  void setGroup(String group) {
    if (_selectedGroup == group && _selectedCategory == "All") return;
    _selectedGroup = group;
    _selectedCategory = "All";
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void setModeFilter(ModeFilter mode) {
    if (_modeFilter == mode) return;
    _modeFilter = mode;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void setSearchQuery(String q) {
    if (_searchQuery == q) return;
    _searchQuery = q;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void setSortKey(SortKey sort) {
    if (_sortKey == sort) return;
    _sortKey = sort;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void setScope(FeedScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void toggleFreeOnly() {
    _freeOnly = !_freeOnly;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void toggleSpotsOnly() {
    _spotsOnly = !_spotsOnly;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void toggleTodayOnly() {
    _todayOnly = !_todayOnly;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void toggleWeekendOnly() {
    _weekendOnly = !_weekendOnly;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void toggleVerifiedHostsOnly() {
    _verifiedHostsOnly = !_verifiedHostsOnly;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  void resetFilters() {
    _sortKey = SortKey.date;
    _freeOnly = false;
    _spotsOnly = false;
    _todayOnly = false;
    _weekendOnly = false;
    _verifiedHostsOnly = false;
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchActivities({bool refresh = true}) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    // Do not load plans until the user is signed in
    final currentUid = client.auth.currentUser?.id;
    if (currentUid == null) {
      _activities = [];
      _joinRequests = [];
      _isSpatialResult = false;
      _spatiallyVerifiedIds.clear();
      _isLoading = false;
      _hasMore = false;
      _error = null;
      _invalidateFilterCache();
      if (!_isDisposed) notifyListeners();
      return;
    }

    if (_activitiesChannel == null) {
      _subscribeRealtime();
    }

    if (!_isLocationRestored && !_locationTouched) {
      await restoreLocation();
    }

    if (refresh) {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    }
    _error = null;
    if (!_isDisposed) notifyListeners();

    try {
      dynamic res;
      final currentPlace = _place;
      bool spatial = false;

      // 1. When coordinates are available, attempt backend spatial filtering via get_nearby_activities RPC
      if (currentPlace != null) {
        try {
          res = await SupabaseService.fetchNearbyActivities(
            lat: currentPlace.lat,
            lng: currentPlace.lon,
            radiusKm: _radiusKm,
            limit: defaultPageSize,
            offset: 0,
          );
          if (res != null) {
            spatial = true;
          }
        } catch (_) {
          res = null;
        }
      }

      // 2. If spatial RPC returned null, not configured, or failed, fallback to standard queries
      if (res == null) {
        try {
          res = await client
              .from('activities')
              .select('*, profiles_public(*)')
              .filter('deleted_at', 'is', null)
              .range(0, defaultPageSize - 1)
              .order('date_time', ascending: true);
        } catch (_) {
          try {
            res = await client
                .from('activities')
                .select('*, profiles(*)')
                .filter('deleted_at', 'is', null)
                .range(0, defaultPageSize - 1)
                .order('date_time', ascending: true);
          } catch (_) {
            res = await client
                .from('activities')
                .select('*')
                .filter('deleted_at', 'is', null)
                .range(0, defaultPageSize - 1)
                .order('date_time', ascending: true);
          }
        }
      }

      if (_isDisposed) return;

      if (res is List<dynamic>) {
        _isSpatialResult = spatial;
        _spatiallyVerifiedIds.clear();
        if (spatial) {
          for (final item in res) {
            if (item is Map<String, dynamic> && item['id'] != null) {
              _spatiallyVerifiedIds.add(item['id'].toString());
            }
          }
        }
        final list = res
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        // Deduplicate by stable ID
        final deduplicated = <String, Activity>{};
        for (final a in list) {
          if (a.id.isNotEmpty) {
            deduplicated[a.id] = a;
          }
        }
        _activities = deduplicated.values.toList();
        _hasMore = list.length >= defaultPageSize;

        await _enrichHostProfiles(_activities);
      }

      // Safe join_requests fetch (does not break activities if unauthenticated or empty)
      try {
        dynamic reqsRes;
        try {
          reqsRes = await client
              .from('join_requests')
              .select('*, profiles_public(*)');
        } catch (_) {
          try {
            reqsRes = await client
                .from('join_requests')
                .select('*, profiles(*)');
          } catch (_) {
            reqsRes = await client.from('join_requests').select('*');
          }
        }

        if (reqsRes is List<dynamic>) {
          _joinRequests = reqsRes
              .map((json) => JoinRequest.fromJson(json as Map<String, dynamic>))
              .toList();
          _rebuildJoinRequestIndices();
          await _enrichJoinRequestProfiles(_joinRequests);
        }
      } catch (_) {
        // join_requests error should not fail activities loading
      }

      _invalidateFilterCache();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads the next page of matching nearby plans deterministically.
  Future<void> loadMoreActivities() async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed || _isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    if (!_isDisposed) notifyListeners();

    try {
      final currentPlace = _place;
      final nextOffset = (_currentPage + 1) * defaultPageSize;
      dynamic res;
      bool spatial = false;

      if (currentPlace != null) {
        try {
          res = await SupabaseService.fetchNearbyActivities(
            lat: currentPlace.lat,
            lng: currentPlace.lon,
            radiusKm: _radiusKm,
            limit: defaultPageSize,
            offset: nextOffset,
          );
          if (res != null) {
            spatial = true;
          }
        } catch (_) {
          res = null;
        }
      }

      if (res == null) {
        try {
          res = await client
              .from('activities')
              .select('*, profiles_public(*)')
              .filter('deleted_at', 'is', null)
              .range(nextOffset, nextOffset + defaultPageSize - 1)
              .order('date_time', ascending: true);
        } catch (_) {
          try {
            res = await client
                .from('activities')
                .select('*, profiles(*)')
                .filter('deleted_at', 'is', null)
                .range(nextOffset, nextOffset + defaultPageSize - 1)
                .order('date_time', ascending: true);
          } catch (_) {
            res = await client
                .from('activities')
                .select('*')
                .filter('deleted_at', 'is', null)
                .range(nextOffset, nextOffset + defaultPageSize - 1)
                .order('date_time', ascending: true);
          }
        }
      }

      if (_isDisposed) return;

      if (res is List<dynamic> && res.isNotEmpty) {
        if (spatial) {
          for (final item in res) {
            if (item is Map<String, dynamic> && item['id'] != null) {
              _spatiallyVerifiedIds.add(item['id'].toString());
            }
          }
        }
        final newItems = res
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        final currentMap = <String, Activity>{for (final a in _activities) a.id: a};
        final newlyAdded = <Activity>[];
        for (final item in newItems) {
          if (!currentMap.containsKey(item.id)) {
            currentMap[item.id] = item;
            newlyAdded.add(item);
          }
        }
        _activities = currentMap.values.toList();
        _currentPage++;
        _hasMore = newItems.length >= defaultPageSize;

        if (newlyAdded.isNotEmpty) {
          await _enrichHostProfiles(newlyAdded);
        }
        _invalidateFilterCache();
      } else {
        _hasMore = false;
      }
    } catch (_) {
      // Load more failure should not crash existing list
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> _enrichHostProfiles(List<Activity> items) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    final missingHostIds = items
        .where((a) => a.host == null && a.hostId.isNotEmpty)
        .map((a) => a.hostId)
        .toSet()
        .toList();

    if (missingHostIds.isEmpty) return;

    final toFetch = missingHostIds
        .where((id) => !_profileCache.containsKey(id))
        .toList();

    if (toFetch.isNotEmpty) {
      try {
        dynamic profRes;
        try {
          profRes = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url, rating, is_verified')
              .inFilter('id', toFetch);
        } catch (_) {
          try {
            profRes = await client
                .from('profiles_public')
                .select('id, full_name, username, avatar_url')
                .inFilter('id', toFetch);
          } catch (_) {
            profRes = await client
                .from('profiles')
                .select('id, full_name, username, avatar_url')
                .inFilter('id', toFetch);
          }
        }
        if (profRes is List<dynamic>) {
          for (final p in profRes) {
            if (p is Map<String, dynamic> && p['id'] != null) {
              _profileCache[p['id'].toString()] = UserProfile.fromJson(p);
            }
          }
        }
      } catch (_) {
        // Ignore profile enrichment failure
      }
    }

    bool changed = false;
    _activities = _activities.map((a) {
      if (a.host == null && _profileCache.containsKey(a.hostId)) {
        changed = true;
        return a.copyWith(host: _profileCache[a.hostId]);
      }
      return a;
    }).toList();

    if (changed) {
      _invalidateFilterCache();
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _enrichJoinRequestProfiles(List<JoinRequest> reqs) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    final missingUserIds = reqs
        .where((r) => r.user == null && r.userId.isNotEmpty)
        .map((r) => r.userId)
        .toSet()
        .toList();

    if (missingUserIds.isEmpty) return;

    final toFetch = missingUserIds
        .where((id) => !_profileCache.containsKey(id))
        .toList();

    if (toFetch.isNotEmpty) {
      try {
        dynamic profRes;
        try {
          profRes = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url, rating, is_verified')
              .inFilter('id', toFetch);
        } catch (_) {
          try {
            profRes = await client
                .from('profiles_public')
                .select('id, full_name, username, avatar_url')
                .inFilter('id', toFetch);
          } catch (_) {
            profRes = await client
                .from('profiles')
                .select('id, full_name, username, avatar_url')
                .inFilter('id', toFetch);
          }
        }
        if (profRes is List<dynamic>) {
          for (final p in profRes) {
            if (p is Map<String, dynamic> && p['id'] != null) {
              _profileCache[p['id'].toString()] = UserProfile.fromJson(p);
            }
          }
        }
      } catch (_) {
        // Ignore profile enrichment failure
      }
    }

    bool changed = false;
    _joinRequests = _joinRequests.map((r) {
      if (r.user == null && _profileCache.containsKey(r.userId)) {
        changed = true;
        return r.copyWith(user: _profileCache[r.userId]);
      }
      return r;
    }).toList();

    if (changed) {
      _rebuildJoinRequestIndices();
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void _onRealtimeActivityChange(PostgresChangePayload payload) {
    if (_isDisposed) return;

    if (payload.eventType == PostgresChangeEvent.insert) {
      final record = payload.newRecord;
      if (record.isNotEmpty && record['id'] != null) {
        try {
          final newAct = Activity.fromJson(record);
          if (record['deleted_at'] == null) {
            final idx = _activities.indexWhere((a) => a.id == newAct.id);
            if (idx == -1) {
              _activities.insert(0, newAct);
              _invalidateFilterCache();
              notifyListeners();
              unawaited(_enrichHostProfiles([newAct]));
            }
          }
        } catch (_) {}
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final record = payload.newRecord;
      if (record.isNotEmpty && record['id'] != null) {
        try {
          final updAct = Activity.fromJson(record);
          if (record['deleted_at'] != null) {
            _activities.removeWhere((a) => a.id == updAct.id);
          } else {
            final idx = _activities.indexWhere((a) => a.id == updAct.id);
            if (idx != -1) {
              final existing = _activities[idx];
              _activities[idx] = updAct.copyWith(
                host: updAct.host ?? existing.host,
              );
            }
          }
          _invalidateFilterCache();
          notifyListeners();
        } catch (_) {}
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id']?.toString();
      if (oldId != null && oldId.isNotEmpty) {
        _activities.removeWhere((a) => a.id == oldId);
        _invalidateFilterCache();
        notifyListeners();
      }
    }

    _onRealtimeChange();
  }

  Timer? _debounceTimer;

  void _onRealtimeChange() {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        fetchActivities();
      }
    });
  }

  void reconnectRealtime() {
    _activitiesChannel?.unsubscribe();
    _joinRequestsChannel?.unsubscribe();
    _activitiesChannel = null;
    _joinRequestsChannel = null;
    fetchActivities();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    _activitiesChannel = client
        .channel('public:activities')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          callback: (payload) => _onRealtimeActivityChange(payload),
        )
        .subscribe();

    _joinRequestsChannel = client
        .channel('public:join_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'join_requests',
          callback: (payload) => _onRealtimeChange(),
        )
        .subscribe();
  }

  // Filtered Activities with Memoization
  List<Activity> getFilteredActivities(
    String? currentUserId,
    Set<String> blockedIds, {
    bool applyRadiusFilter = true,
  }) {
    if (_filterCacheValid &&
        _cachedCurrentUserId == currentUserId &&
        _cachedApplyRadiusFilter == applyRadiusFilter &&
        _cachedBlockedIds != null &&
        _cachedBlockedIds!.length == blockedIds.length &&
        _cachedBlockedIds!.containsAll(blockedIds) &&
        _cachedFilteredActivities != null) {
      return _cachedFilteredActivities!;
    }

    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();

    final result = _activities.where((a) {
      if (blockedIds.contains(a.hostId)) return false;

      final isHostedByMe = currentUserId != null && a.hostId == currentUserId;
      final myReq = currentUserId != null
          ? _userRequestIndex['${a.id}:$currentUserId']
          : null;

      final isJoined = myReq != null && myReq.status == JoinStatus.accepted;

      if (currentUserId != null) {
        if (_scope == FeedScope.hosting && !isHostedByMe) return false;
        if (_scope == FeedScope.joined && !isJoined) return false;
      }

      if (_selectedCategory != "All" && a.category != _selectedCategory) {
        return false;
      }

      if (_modeFilter == ModeFilter.inPerson && a.isOnline) return false;
      if (_modeFilter == ModeFilter.online && !a.isOnline) return false;

      // 15 KM Default Radius Filtering (applies in discover feed when location is known and radius filtering is active):
      if (applyRadiusFilter && _scope == FeedScope.discover && _place != null) {
        if (!a.isOnline) {
          // In-person physical plans must have valid coordinates within radius
          if (a.latitude != null && a.longitude != null) {
            final dist = LocationService.haversineKm(
              _place!.lat,
              _place!.lon,
              a.latitude!,
              a.longitude!,
            );
            // Plans within 15 km appear; plans beyond 15 km do not appear
            // 0.001km precision allowance handles floating-point 15.000km edge
            if (dist > _radiusKm + 0.001) {
              return false;
            }
          } else {
            // In-person physical plans with no coordinates cannot be confirmed within 15 km
            return false;
          }
        } else {
          // Virtual plans: proximity anchor is creator's authorized discovery location
          final double? anchorLat = a.latitude ?? a.host?.latitude;
          final double? anchorLon = a.longitude ?? a.host?.longitude;

          if (anchorLat != null && anchorLon != null) {
            final dist = LocationService.haversineKm(
              _place!.lat,
              _place!.lon,
              anchorLat,
              anchorLon,
            );
            if (dist > _radiusKm + 0.001) {
              return false;
            }
          } else {
            // If coordinates are not directly exposed on activity or host model:
            // Check if this virtual plan was already spatially verified by the backend RPC
            if (!(_isSpatialResult && _spatiallyVerifiedIds.contains(a.id))) {
              // Unverified virtual plan without location anchor cannot be confirmed within 15 km
              return false;
            }
          }
        }
      }

      if (_freeOnly && a.costPerHead > 0) return false;
      if (_spotsOnly && a.slotsLeft <= 0) return false;

      if (_todayOnly) {
        if (a.dateTime.year != now.year ||
            a.dateTime.month != now.month ||
            a.dateTime.day != now.day) {
          return false;
        }
      }

      if (_weekendOnly) {
        final weekday = a.dateTime.weekday;
        if (weekday != DateTime.saturday && weekday != DateTime.sunday) {
          return false;
        }
      }

      if (_verifiedHostsOnly && !(a.host?.isVerified ?? false)) return false;

      if (query.isNotEmpty) {
        final matchTitle = a.title.toLowerCase().contains(query);
        final matchLoc = a.location.toLowerCase().contains(query);
        final matchCat = a.category.toLowerCase().contains(query);
        final matchTags = a.topicTags.any(
          (t) => t.toLowerCase().contains(query),
        );
        if (!matchTitle && !matchLoc && !matchCat && !matchTags) return false;
      }

      return true;
    }).toList();

    // Sort
    if (_sortKey == SortKey.date) {
      result.sort((a, b) {
        final aUpcoming =
            a.dateTime.isAfter(now) || a.dateTime.isAtSameMomentAs(now);
        final bUpcoming =
            b.dateTime.isAfter(now) || b.dateTime.isAtSameMomentAs(now);
        if (aUpcoming && !bUpcoming) return -1;
        if (!aUpcoming && bUpcoming) return 1;
        return a.dateTime.compareTo(b.dateTime);
      });
    } else if (_sortKey == SortKey.popularity) {
      result.sort((a, b) => a.slotsLeft.compareTo(b.slotsLeft));
    } else if (_sortKey == SortKey.distance) {
      final origin = _place;
      if (origin == null) {
        // No chosen coordinates: TanStack sorts by the venue label
        // (`a.location.localeCompare(b.location)`). Never assume a city centre.
        result.sort(
          (a, b) =>
              a.location.toLowerCase().compareTo(b.location.toLowerCase()),
        );
      } else {
        // A real place is known: order by great-circle distance (using venue or creator anchor)
        double? distOf(Activity a) {
          final lat = a.isOnline ? (a.latitude ?? a.host?.latitude) : a.latitude;
          final lon = a.isOnline ? (a.longitude ?? a.host?.longitude) : a.longitude;
          return (lat != null && lon != null)
              ? LocationService.haversineKm(
                  origin.lat,
                  origin.lon,
                  lat,
                  lon,
                )
              : null;
        }
        result.sort((a, b) {
          final da = distOf(a);
          final db = distOf(b);
          if (da != null && db == null) return -1;
          if (da == null && db != null) return 1;
          if (da != null && db != null) {
            final c = da.compareTo(db);
            if (c != 0) return c;
          }
          return a.location.toLowerCase().compareTo(b.location.toLowerCase());
        });
      }
    }

    _cachedFilteredActivities = List.unmodifiable(result);
    _cachedCurrentUserId = currentUserId;
    _cachedBlockedIds = Set.from(blockedIds);
    _cachedApplyRadiusFilter = applyRadiusFilter;
    _filterCacheValid = true;

    return _cachedFilteredActivities!;
  }

  // Database Actions
  Future<bool> createActivity(Activity activity) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;
    try {
      await client.from('activities').insert(activity.toJson());
      // Reconcile and ensure newly created plan is in memory immediately
      final existingIdx = _activities.indexWhere((a) => a.id == activity.id);
      if (existingIdx == -1) {
        _activities = [activity, ..._activities];
        _invalidateFilterCache();
      }
      await fetchActivities(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;
    try {
      await client
          .from('activities')
          .update(activity.toJson())
          .eq('id', activity.id);
      final existingIdx = _activities.indexWhere((a) => a.id == activity.id);
      if (existingIdx != -1) {
        _activities[existingIdx] = activity;
        _invalidateFilterCache();
      }
      await fetchActivities(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;
    try {
      await client
          .from('activities')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      _activities.removeWhere((a) => a.id == id);
      _invalidateFilterCache();
      await fetchActivities(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUrgent(String activityId) async {
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx == -1) return false;

    final act = _activities[idx];
    final nextUrgent = !act.isUrgentActive;
    final urgentUntil = nextUrgent
        ? DateTime.now().add(const Duration(minutes: 30)).toIso8601String()
        : null;
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    try {
      await client
          .from('activities')
          .update({'is_urgent': nextUrgent, 'urgent_until': urgentUntil})
          .eq('id', activityId);
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  final Map<String, String?> _meetingLinks = {};

  /// Retrieves the meeting link from in-memory activity or cache if available.
  String? getMeetingLink(String activityId) {
    final act = _activities.where((a) => a.id == activityId).firstOrNull;
    if (act?.meetingLink != null && act!.meetingLink!.trim().isNotEmpty) {
      return act.meetingLink!.trim();
    }
    return _meetingLinks[activityId];
  }

  /// Securely fetches meeting link from backend via get_meeting_link RPC.
  Future<String?> fetchMeetingLink(String activityId) async {
    final cached = getMeetingLink(activityId);
    if (cached != null) return cached;

    final link = await SupabaseService.getMeetingLink(activityId);
    if (link != null) {
      _meetingLinks[activityId] = link;
      if (!_isDisposed) notifyListeners();
    }
    return link;
  }

  /// True when the profile has the verified GPS location that the backend
  /// RLS policy "Users can request to join with verified profile location"
  /// requires (city + latitude + longitude). Same check as TanStack.
  static bool profileHasGpsLocation(UserProfile? user) =>
      user != null &&
      (user.city?.trim().isNotEmpty ?? false) &&
      user.latitude != null &&
      user.longitude != null;

  /// Sends a join request. Returns `null` on success or a user-facing error
  /// message. Pre-checks and error mapping mirror TanStack `requestToJoin`.
  Future<String?> requestToJoin(String activityId, UserProfile user) async {
    final act = _activities.where((a) => a.id == activityId).firstOrNull;
    final isOnline = act?.isOnline ?? false;
    if (!isOnline && !profileHasGpsLocation(user)) {
      return 'Add your GPS profile location before requesting to join.';
    }
    if (act != null && act.hostId == user.id) {
      return "You're the host of this plan.";
    }
    final existing = _userRequestIndex['$activityId:${user.id}'];
    if (existing != null) {
      return existing.status == JoinStatus.accepted
          ? "You've already joined this plan!"
          : "You've already requested to join this plan!";
    }
    final client = SupabaseService.client;
    if (client == null || _isDisposed) {
      return 'The service is temporarily unavailable.';
    }
    final key = '$activityId:${user.id}';
    if (_pendingJoinRequests.contains(key)) return null;
    _pendingJoinRequests.add(key);
    try {
      await client.from('join_requests').insert({
        'activity_id': activityId,
        'user_id': user.id,
        'status': 'pending',
      });
      await fetchActivities();
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return "You've already requested to join this plan!";
      }
      if (e.code == '42501' ||
          RegExp(
            'row-level security',
            caseSensitive: false,
          ).hasMatch(e.message)) {
        return "Add your GPS profile location first, or this plan has safety restrictions you don't meet.";
      }
      return 'Could not send your join request. Please try again.';
    } catch (_) {
      return 'Could not send your join request. Please try again.';
    } finally {
      _pendingJoinRequests.remove(key);
    }
  }

  Future<bool> respondToRequest(String requestId, JoinStatus status) async {
    if (_pendingRespondRequests.contains(requestId)) return false;
    _pendingRespondRequests.add(requestId);
    final statusStr = status == JoinStatus.accepted
        ? 'accepted'
        : (status == JoinStatus.rejected ? 'rejected' : 'pending');

    final client = SupabaseService.client;
    if (client == null || _isDisposed) {
      _pendingRespondRequests.remove(requestId);
      return false;
    }

    try {
      if (status == JoinStatus.accepted) {
        try {
          await client.rpc(
            'accept_join_request',
            params: {'_req_id': requestId},
          );
        } catch (_) {
          await client
              .from('join_requests')
              .update({'status': 'accepted'})
              .eq('id', requestId);
        }
      } else {
        await client
            .from('join_requests')
            .update({'status': statusStr})
            .eq('id', requestId);
      }
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    } finally {
      _pendingRespondRequests.remove(requestId);
    }
  }

  Future<bool> removeAttendee(String requestId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    try {
      try {
        await client.rpc('remove_join_request', params: {'_req_id': requestId});
      } catch (_) {
        await client
            .from('join_requests')
            .update({'status': 'rejected'})
            .eq('id', requestId);
      }
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calls the check_in_activity RPC with the user's real GPS coordinates.
  /// Returns a [CheckInResult] with the backend status and distance.
  Future<CheckInResult> checkInAtVenue({
    required String activityId,
    required double lat,
    required double lon,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) {
      return const CheckInResult(
        status: 'error',
        errorMessage: 'The service is temporarily unavailable.',
      );
    }
    try {
      final res = await client.rpc(
        'check_in_activity',
        params: {'_activity_id': activityId, '_lat': lat, '_lon': lon},
      );
      await fetchActivities();
      // The RPC returns a table with {status, distance_m}
      if (res is List && res.isNotEmpty) {
        final row = res.first as Map<String, dynamic>;
        return CheckInResult(
          status: row['status'] as String? ?? 'unknown',
          distanceM: (row['distance_m'] as num?)?.toDouble(),
        );
      }
      return const CheckInResult(
        status: 'error',
        errorMessage: 'Unexpected response from check-in service.',
      );
    } catch (e) {
      debugPrint('checkInAtVenue error: $e');
      return const CheckInResult(
        status: 'error',
        errorMessage: 'Unable to check in right now. Please try again.',
      );
    }
  }

  Future<bool> markAttendeeNoShow(String requestId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;
    try {
      await client.rpc('mark_no_show', params: {'_req_id': requestId});
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMemoryPhoto(String activityId, String photoUrl) async {
    final client = SupabaseService.client;
    final currentUserId = client?.auth.currentUser?.id;
    if (client == null || currentUserId == null) return false;

    try {
      await client.from('event_memories').insert({
        'activity_id': activityId,
        'user_id': currentUserId,
        'image_url': photoUrl,
      });
      await fetchActivities();
      return true;
    } catch (e) {
      debugPrint('addMemoryPhoto error: $e');
      return false;
    }
  }

  List<JoinRequest> getRequestsForActivity(String activityId) {
    return _requestsByActivity[activityId] ?? const [];
  }

  int getPendingCountForActivity(String activityId) {
    return _pendingCountByActivity[activityId] ?? 0;
  }

  JoinRequest? getMyRequest(String activityId, String userId) {
    return _userRequestIndex['$activityId:$userId'];
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _activitiesChannel?.unsubscribe();
    _joinRequestsChannel?.unsubscribe();
    super.dispose();
  }
}
