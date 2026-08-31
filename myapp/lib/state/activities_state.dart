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
  bool _isLoading = false;
  String? _error;

  RealtimeChannel? _activitiesChannel;
  RealtimeChannel? _joinRequestsChannel;

  // Search & Filter State
  String _selectedGroup = "All";
  String _selectedCategory = "All";
  ModeFilter _modeFilter = ModeFilter.all;
  String _searchQuery = "";
  SortKey _sortKey = SortKey.date;
  FeedScope _scope = FeedScope.discover;
  String _location = "Indiranagar, Bengaluru";

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
  List<Activity> get activities => _activities;
  List<JoinRequest> get joinRequests => _joinRequests;
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

  void setLocation(String loc) {
    _location = loc;
    notifyListeners();
  }

  void setGroup(String group) {
    _selectedGroup = group;
    _selectedCategory = "All";
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setModeFilter(ModeFilter mode) {
    _modeFilter = mode;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortKey(SortKey sort) {
    _sortKey = sort;
    notifyListeners();
  }

  void setScope(FeedScope scope) {
    _scope = scope;
    notifyListeners();
  }

  void toggleFreeOnly() {
    _freeOnly = !_freeOnly;
    notifyListeners();
  }

  void toggleSpotsOnly() {
    _spotsOnly = !_spotsOnly;
    notifyListeners();
  }

  void toggleTodayOnly() {
    _todayOnly = !_todayOnly;
    notifyListeners();
  }

  void toggleWeekendOnly() {
    _weekendOnly = !_weekendOnly;
    notifyListeners();
  }

  void toggleVerifiedHostsOnly() {
    _verifiedHostsOnly = !_verifiedHostsOnly;
    notifyListeners();
  }

  void resetFilters() {
    _sortKey = SortKey.date;
    _freeOnly = false;
    _spotsOnly = false;
    _todayOnly = false;
    _weekendOnly = false;
    _verifiedHostsOnly = false;
    notifyListeners();
  }

  Future<void> fetchActivities() async {
    final client = SupabaseService.client;
    if (client == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await client
          .from('activities')
          .select('*, profiles_public(*)')
          .filter('deleted_at', 'is', null)
          .order('date_time', ascending: true);

      _activities = (res as List<dynamic>)
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList();

      final reqsRes = await client
          .from('join_requests')
          .select('*, profiles_public(*)');

      _joinRequests = (reqsRes as List<dynamic>)
          .map((json) => JoinRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.client;
    if (client == null) return;

    _activitiesChannel = client
        .channel('public:activities')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          callback: (payload) {
            fetchActivities();
          },
        )
        .subscribe();

    _joinRequestsChannel = client
        .channel('public:join_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'join_requests',
          callback: (payload) {
            fetchActivities();
          },
        )
        .subscribe();
  }

  // Filtered Activities
  List<Activity> getFilteredActivities(
    String? currentUserId,
    Set<String> blockedIds,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    final result = _activities.where((a) {
      if (blockedIds.contains(a.hostId)) return false;

      final isHostedByMe = currentUserId != null && a.hostId == currentUserId;
      final myReq = currentUserId != null
          ? _joinRequests.firstWhere(
              (r) => r.activityId == a.id && r.userId == currentUserId,
              orElse: () => JoinRequest(
                id: '',
                activityId: '',
                userId: '',
                status: JoinStatus.rejected,
                requestedAt: DateTime.now(),
              ),
            )
          : null;

      final isJoined = myReq != null && myReq.status == JoinStatus.accepted;
      final isPending = myReq != null && myReq.status == JoinStatus.pending;

      if (currentUserId != null) {
        if (_scope == FeedScope.hosting && !isHostedByMe) return false;
        if (_scope == FeedScope.joined && !isJoined) return false;
        if (_scope == FeedScope.discover) {
          if (isHostedByMe || isJoined || isPending) return false;
        }
      }

      if (_selectedCategory != "All" && a.category != _selectedCategory) {
        return false;
      }

      if (_modeFilter == ModeFilter.inPerson && a.isOnline) return false;
      if (_modeFilter == ModeFilter.online && !a.isOnline) return false;

      if (_freeOnly && a.costPerHead > 0) return false;
      if (_spotsOnly && a.slotsLeft <= 0) return false;

      if (_todayOnly) {
        final now = DateTime.now();
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
      result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else if (_sortKey == SortKey.popularity) {
      result.sort((a, b) => a.slotsLeft.compareTo(b.slotsLeft));
    } else if (_sortKey == SortKey.distance) {
      result.sort((a, b) => a.location.compareTo(b.location));
    }

    return result;
  }

  // Real Database Actions
  Future<void> createActivity(Activity activity) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .insert(activity.toJson());
      await fetchActivities();
    } catch (e) {
      // ignore
    }
  }

  Future<void> updateActivity(Activity activity) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .update(activity.toJson())
          .eq('id', activity.id);
      await fetchActivities();
    } catch (e) {
      // ignore
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await SupabaseService.client
          ?.from('activities')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      await fetchActivities();
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleUrgent(String activityId) async {
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx != -1) {
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
      } catch (_) {}
    }
  }

  Future<void> requestToJoin(String activityId, UserProfile user) async {
    try {
      await SupabaseService.client?.from('join_requests').insert({
        'activity_id': activityId,
        'user_id': user.id,
        'status': 'pending',
      });
      await fetchActivities();
    } catch (_) {}
  }

  Future<void> respondToRequest(String requestId, JoinStatus status) async {
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
    } catch (_) {}
  }

  Future<void> removeAttendee(String requestId) async {
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
    } catch (_) {}
  }

  Future<void> markAttendeeCheckIn(String activityId, String userId) async {
    try {
      await SupabaseService.client?.rpc(
        'check_in_activity',
        params: {'_activity_id': activityId, '_user_id': userId},
      );
      await fetchActivities();
    } catch (_) {}
  }

  Future<void> markAttendeeNoShow(String requestId) async {
    try {
      await SupabaseService.client?.rpc(
        'mark_no_show',
        params: {'_request_id': requestId},
      );
      await fetchActivities();
    } catch (_) {}
  }

  Future<void> addMemoryPhoto(String activityId, String photoUrl) async {
    try {
      await SupabaseService.client?.from('event_memories').insert({
        'activity_id': activityId,
        'image_url': photoUrl,
      });
      await fetchActivities();
    } catch (_) {}
  }

  List<JoinRequest> getRequestsForActivity(String activityId) {
    return _joinRequests.where((r) => r.activityId == activityId).toList();
  }

  int getPendingCountForActivity(String activityId) {
    return _joinRequests
        .where(
          (r) => r.activityId == activityId && r.status == JoinStatus.pending,
        )
        .length;
  }

  JoinRequest? getMyRequest(String activityId, String userId) {
    try {
      return _joinRequests.firstWhere(
        (r) => r.activityId == activityId && r.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _activitiesChannel?.unsubscribe();
    _joinRequestsChannel?.unsubscribe();
    super.dispose();
  }
}
