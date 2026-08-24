import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/join_request.dart';
import '../models/user_profile.dart';
import 'mock_data.dart';

enum SortKey { date, distance, popularity }

enum ModeFilter { all, inPerson, online }

enum FeedScope { discover, joined, hosting }

class ActivitiesState extends ChangeNotifier {
  final List<Activity> _activities = MockData.getInitialActivities();
  final List<JoinRequest> _joinRequests = MockData.getInitialJoinRequests();

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

  // Getters
  List<Activity> get activities => _activities;
  List<JoinRequest> get joinRequests => _joinRequests;
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

  // Plan Actions
  void createActivity(Activity activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  void updateActivity(Activity activity) {
    final idx = _activities.indexWhere((a) => a.id == activity.id);
    if (idx != -1) {
      _activities[idx] = activity;
      notifyListeners();
    }
  }

  void deleteActivity(String id) {
    _activities.removeWhere((a) => a.id == id);
    _joinRequests.removeWhere((r) => r.activityId == id);
    notifyListeners();
  }

  void toggleUrgent(String activityId) {
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx != -1) {
      final act = _activities[idx];
      final nextUrgent = !act.isUrgentActive;
      _activities[idx] = act.copyWith(
        isUrgent: nextUrgent,
        urgentUntil: nextUrgent
            ? DateTime.now().add(const Duration(minutes: 30))
            : null,
      );
      notifyListeners();
    }
  }

  void requestToJoin(String activityId, UserProfile user) {
    final existing = _joinRequests.where(
      (r) => r.activityId == activityId && r.userId == user.id,
    );
    if (existing.isEmpty) {
      _joinRequests.add(
        JoinRequest(
          id: "req_${DateTime.now().millisecondsSinceEpoch}",
          activityId: activityId,
          userId: user.id,
          status: JoinStatus.pending,
          requestedAt: DateTime.now(),
          user: user,
        ),
      );
      notifyListeners();
    }
  }

  void respondToRequest(String requestId, JoinStatus status) {
    final idx = _joinRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _joinRequests[idx];
      _joinRequests[idx] = req.copyWith(status: status);

      if (status == JoinStatus.accepted) {
        final actIdx = _activities.indexWhere((a) => a.id == req.activityId);
        if (actIdx != -1) {
          final act = _activities[actIdx];
          if (act.slotsLeft > 0) {
            _activities[actIdx] = act.copyWith(slotsLeft: act.slotsLeft - 1);
          }
        }
      }
      notifyListeners();
    }
  }

  void removeAttendee(String requestId) {
    final idx = _joinRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _joinRequests[idx];
      final wasAccepted = req.status == JoinStatus.accepted;
      _joinRequests.removeAt(idx);

      if (wasAccepted) {
        final actIdx = _activities.indexWhere((a) => a.id == req.activityId);
        if (actIdx != -1) {
          final act = _activities[actIdx];
          _activities[actIdx] = act.copyWith(slotsLeft: act.slotsLeft + 1);
        }
      }
      notifyListeners();
    }
  }

  void markAttendeeCheckIn(String activityId, String userId) {
    final idx = _joinRequests.indexWhere(
      (r) => r.activityId == activityId && r.userId == userId,
    );
    if (idx != -1) {
      _joinRequests[idx] = _joinRequests[idx].copyWith(
        checkedInAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void markAttendeeNoShow(String requestId) {
    final idx = _joinRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _joinRequests[idx] = _joinRequests[idx].copyWith(noShow: true);
      notifyListeners();
    }
  }

  void addMemoryPhoto(String activityId, String photoUrl) {
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx != -1) {
      final act = _activities[idx];
      _activities[idx] = act.copyWith(
        photoMemories: [...act.photoMemories, photoUrl],
      );
      notifyListeners();
    }
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
}
