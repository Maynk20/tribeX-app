import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../models/join_request.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

enum SortKey { date, distance, popularity }

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

  // Memoization Cache for Filtered Activities
  List<Activity>? _cachedFilteredActivities;
  String? _cachedCurrentUserId;
  Set<String>? _cachedBlockedIds;
  bool _filterCacheValid = false;

  RealtimeChannel? _activitiesChannel;
  RealtimeChannel? _joinRequestsChannel;

  void _invalidateFilterCache() {
    _filterCacheValid = false;
    _cachedFilteredActivities = null;
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
  String _location = "Indiranagar, Bengaluru";
  double _userLat = 12.9784; // Indiranagar, Bengaluru default lat
  double _userLng = 77.6408; // Indiranagar, Bengaluru default lng

  // Quick Filters
  bool _freeOnly = false;
  bool _spotsOnly = false;
  bool _todayOnly = false;
  bool _weekendOnly = false;
  bool _verifiedHostsOnly = false;

  ActivitiesState() {
    fetchActivities();
    _subscribeRealtime();
  }

  // Getters
  List<Activity> get activities => List.unmodifiable(_activities);
  List<JoinRequest> get joinRequests => List.unmodifiable(_joinRequests);
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get selectedGroup => _selectedGroup;
  String get selectedCategory => _selectedCategory;
  ModeFilter get modeFilter => _modeFilter;
  String get searchQuery => _searchQuery;
  SortKey get sortKey => _sortKey;
  FeedScope get scope => _scope;
  String get location => _location;

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

  void setLocation(String loc, {double? lat, double? lng}) {
    _location = loc;
    if (lat != null && lng != null) {
      _userLat = lat;
      _userLng = lng;
    }
    _invalidateFilterCache();
    if (!_isDisposed) notifyListeners();
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

  Future<void> fetchActivities() async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    _isLoading = true;
    _error = null;
    if (!_isDisposed) notifyListeners();

    try {
      dynamic res;
      // 1. Try with profiles_public relation
      try {
        res = await client
            .from('activities')
            .select('*, profiles_public(*)')
            .filter('deleted_at', 'is', null)
            .order('date_time', ascending: true);
      } catch (_) {
        // 2. Fallback to profiles relation
        try {
          res = await client
              .from('activities')
              .select('*, profiles(*)')
              .filter('deleted_at', 'is', null)
              .order('date_time', ascending: true);
        } catch (_) {
          // 3. Fallback to flat activities table
          res = await client
              .from('activities')
              .select('*')
              .filter('deleted_at', 'is', null)
              .order('date_time', ascending: true);
        }
      }

      if (_isDisposed) return;

      if (res is List<dynamic>) {
        _activities = res
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        if (_activities.isNotEmpty && _activities.any((a) => a.host == null)) {
          try {
            final hostIds = _activities.map((a) => a.hostId).toSet().toList();
            final profRes = await client
                .from('profiles_public')
                .select('id, full_name, username, avatar_url, rating, is_verified')
                .filter('id', 'in', hostIds);
            if (profRes is List<dynamic>) {
              final profMap = <String, UserProfile>{};
              for (final p in profRes) {
                if (p is Map<String, dynamic> && p['id'] != null) {
                  profMap[p['id'].toString()] = UserProfile.fromJson(p);
                }
              }
              _activities = _activities.map((a) {
                if (a.host == null && profMap.containsKey(a.hostId)) {
                  return a.copyWith(host: profMap[a.hostId]);
                }
                return a;
              }).toList();
            }
          } catch (_) {
            // Ignore profile enrichment failure
          }
        }
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
          callback: (payload) => _onRealtimeChange(),
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
    Set<String> blockedIds,
  ) {
    if (_filterCacheValid &&
        _cachedCurrentUserId == currentUserId &&
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
        final aUpcoming = a.dateTime.isAfter(now) || a.dateTime.isAtSameMomentAs(now);
        final bUpcoming = b.dateTime.isAfter(now) || b.dateTime.isAtSameMomentAs(now);
        if (aUpcoming && !bUpcoming) return -1;
        if (!aUpcoming && bUpcoming) return 1;
        return a.dateTime.compareTo(b.dateTime);
      });
    } else if (_sortKey == SortKey.popularity) {
      result.sort((a, b) => a.slotsLeft.compareTo(b.slotsLeft));
    } else if (_sortKey == SortKey.distance) {
      result.sort((a, b) {
        if (a.latitude != null &&
            a.longitude != null &&
            b.latitude != null &&
            b.longitude != null) {
          final distA = (a.latitude! - _userLat) * (a.latitude! - _userLat) +
              (a.longitude! - _userLng) * (a.longitude! - _userLng);
          final distB = (b.latitude! - _userLat) * (b.latitude! - _userLat) +
              (b.longitude! - _userLng) * (b.longitude! - _userLng);
          return distA.compareTo(distB);
        }
        return a.location.compareTo(b.location);
      });
    }

    _cachedFilteredActivities = List.unmodifiable(result);
    _cachedCurrentUserId = currentUserId;
    _cachedBlockedIds = Set.from(blockedIds);
    _filterCacheValid = true;

    return _cachedFilteredActivities!;
  }

  // Database Actions
  Future<bool> createActivity(Activity activity) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .insert(activity.toJson());
      await fetchActivities();
      return true;
    } catch (e) {
      _error = e.toString();
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .update(activity.toJson())
          .eq('id', activity.id);
      await fetchActivities();
      return true;
    } catch (e) {
      _error = e.toString();
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      await fetchActivities();
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

    try {
      await SupabaseService.client
          ?.from('activities')
          .update({'is_urgent': nextUrgent, 'urgent_until': urgentUntil})
          .eq('id', activityId);
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestToJoin(String activityId, UserProfile user) async {
    try {
      await SupabaseService.client?.from('join_requests').insert({
        'activity_id': activityId,
        'user_id': user.id,
        'status': 'pending',
      });
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, JoinStatus status) async {
    final statusStr = status == JoinStatus.accepted
        ? 'accepted'
        : (status == JoinStatus.rejected ? 'rejected' : 'pending');

    try {
      if (status == JoinStatus.accepted) {
        try {
          await SupabaseService.client?.rpc(
            'accept_join_request',
            params: {'_request_id': requestId},
          );
        } catch (_) {
          await SupabaseService.client
              ?.from('join_requests')
              .update({'status': 'accepted'})
              .eq('id', requestId);
        }
      } else {
        await SupabaseService.client
            ?.from('join_requests')
            .update({'status': statusStr})
            .eq('id', requestId);
      }
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeAttendee(String requestId) async {
    try {
      try {
        await SupabaseService.client?.rpc(
          'remove_join_request',
          params: {'_request_id': requestId},
        );
      } catch (_) {
        await SupabaseService.client
            ?.from('join_requests')
            .update({'status': 'rejected'})
            .eq('id', requestId);
      }
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAttendeeCheckIn(String activityId, String userId) async {
    try {
      await SupabaseService.client?.rpc(
        'check_in_activity',
        params: {'_activity_id': activityId, '_user_id': userId},
      );
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAttendeeNoShow(String requestId) async {
    try {
      await SupabaseService.client?.rpc(
        'mark_no_show',
        params: {'_request_id': requestId},
      );
      await fetchActivities();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMemoryPhoto(String activityId, String photoUrl) async {
    try {
      await SupabaseService.client?.from('event_memories').insert({
        'activity_id': activityId,
        'image_url': photoUrl,
      });
      await fetchActivities();
      return true;
    } catch (e) {
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
