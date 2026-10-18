import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_formatter.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/message.dart';
import '../models/poll.dart';
import '../models/rating_item.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/poll_service.dart';
import '../services/supabase_service.dart';

class ChatState extends ChangeNotifier {
  static const int messagePageSize = 40;

  final Map<String, List<Message>> _messagesByActivity = {};
  final Map<String, Expense> _expenses = {};
  final Map<String, Poll> _polls = {};
  final List<RatingItem> _ratings = [];
  final Set<String> _pendingExpenseFetches = {};
  final Set<String> _pendingPollFetches = {};
  final Set<String> _votingPollIds = {};
  final Map<String, int> _userPollVotes = {};
  final Map<String, DateTime> _userPollVoteTimes = {};
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, List<ExpenseMember>> _squadMembersByActivity = {};
  final Map<String, UserProfile> _profileCache = {};
  final Map<String, bool> _hasMoreOlderMessages = {};
  final Map<String, bool> _isLoadingOlder = {};
  List<Activity> _userChats = [];
  bool _isLoadingUserChats = false;
  bool _isDisposed = false;
  PollService _pollService = PollService();
  String? _activeChatActivityId;

  String? get activeChatActivityId => _activeChatActivityId;
  void setActiveChat(String? activityId) {
    _activeChatActivityId = activityId;
  }

  @visibleForTesting
  void setPollServiceForTesting(PollService service) {
    _pollService = service;
  }

  List<Activity> get userChats => List.unmodifiable(_userChats);
  bool get isLoadingUserChats => _isLoadingUserChats;
  bool hasMoreOlderMessages(String activityId) =>
      _hasMoreOlderMessages[activityId] ?? false;
  bool isLoadingOlder(String activityId) =>
      _isLoadingOlder[activityId] ?? false;
  List<ExpenseMember>? getSquadMembers(String activityId) =>
      _squadMembersByActivity[activityId];
  UserProfile? getCachedProfile(String userId) => _profileCache[userId];

  List<Message> getMessagesForActivity(String activityId) {
    final list = _messagesByActivity[activityId];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  void unsubscribeFromActivityChat(String activityId) {
    if (_activeChannels.containsKey(activityId)) {
      _activeChannels[activityId]?.unsubscribe();
      _activeChannels.remove(activityId);
    }
  }

  Expense? getExpense(String expenseId) => _expenses[expenseId];

  Poll? getPoll(String pollId) => _polls[pollId];

  @visibleForTesting
  void setPollForTesting(Poll poll) {
    _polls[poll.id] = poll;
  }

  @visibleForTesting
  void setSquadMembersForTesting(
    String activityId,
    List<ExpenseMember> members,
  ) {
    _squadMembersByActivity[activityId] = members;
  }

  @visibleForTesting
  void setProfileForTesting(String userId, UserProfile profile) {
    _profileCache[userId] = profile;
  }

  Future<void> fetchExpenseIfNeeded(String expenseId) async {
    if (_expenses.containsKey(expenseId) ||
        _pendingExpenseFetches.contains(expenseId) ||
        _isDisposed) {
      return;
    }
    _pendingExpenseFetches.add(expenseId);
    try {
      await fetchExpense(expenseId);
    } finally {
      _pendingExpenseFetches.remove(expenseId);
    }
  }

  Future<void> fetchPollIfNeeded(String pollId, {bool force = false}) async {
    if (!force && _polls.containsKey(pollId)) {
      if (!_pendingPollFetches.contains(pollId) && !_isDisposed) {
        _pendingPollFetches.add(pollId);
        unawaited(
          fetchPoll(pollId).whenComplete(() {
            _pendingPollFetches.remove(pollId);
          }),
        );
      }
      return;
    }
    if (_pendingPollFetches.contains(pollId) || _isDisposed) return;

    _pendingPollFetches.add(pollId);
    try {
      await fetchPoll(pollId);
    } finally {
      _pendingPollFetches.remove(pollId);
    }
  }

  Future<void> fetchMessagesForActivity(
    String activityId, {
    bool refresh = false,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      dynamic res;
      try {
        res = await client
            .from('messages')
            .select(
              'id, activity_id, sender_id, text, created_at, profiles_public(id, username, full_name, avatar_url)',
            )
            .eq('activity_id', activityId)
            .order('created_at', ascending: false)
            .limit(messagePageSize);
      } catch (_) {
        res = await client
            .from('messages')
            .select(
              'id, activity_id, sender_id, text, created_at, profiles(id, username, full_name, avatar_url)',
            )
            .eq('activity_id', activityId)
            .order('created_at', ascending: false)
            .limit(messagePageSize);
      }

      if (_isDisposed) return;

      final rawList = (res as List<dynamic>?) ?? [];
      _hasMoreOlderMessages[activityId] = rawList.length >= messagePageSize;

      final msgs = rawList
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      // Batch enrich sender profiles from profiles_public for all missing senders
      final missingSenderIds = msgs
          .map((m) => m.senderId)
          .where((id) => id.isNotEmpty && !_profileCache.containsKey(id))
          .toSet();

      if (missingSenderIds.isNotEmpty) {
        try {
          final profRes = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url')
              .inFilter('id', missingSenderIds.toList());
          for (final p in (profRes as List<dynamic>)) {
            final pid = p['id']?.toString();
            if (pid != null) {
              _profileCache[pid] = UserProfile.fromJson(
                p as Map<String, dynamic>,
              );
            }
          }
        } catch (e) {
          debugPrint('fetchMessages profiles_public error: $e');
        }
      }

      // Pre-fetch squad members in background to guarantee full squad roster
      unawaited(fetchSquadMembers(activityId));

      final enrichedMsgs = msgs.map((m) {
        if (m.sender != null &&
            m.sender!.fullName.isNotEmpty &&
            m.sender!.fullName != 'Squad Member' &&
            m.sender!.fullName != 'User') {
          _profileCache[m.senderId] = m.sender!;
          return m;
        }
        final cached = _profileCache[m.senderId];
        if (cached != null) {
          return m.copyWith(sender: cached);
        }
        final sm = _squadMembersByActivity[activityId]
            ?.where((s) => s.userId == m.senderId)
            .firstOrNull;
        if (sm != null && sm.name.isNotEmpty && sm.name != 'Squad Member') {
          final p = UserProfile(
            id: sm.userId,
            fullName: sm.name,
            username: sm.name,
            avatarUrl: sm.avatarUrl,
          );
          _profileCache[sm.userId] = p;
          return m.copyWith(sender: p);
        }
        return m;
      }).toList();

      final currentList = _messagesByActivity[activityId] ?? [];
      final pendingTemp = currentList
          .where((m) => m.isSending || m.isFailed)
          .toList();

      final Map<String, Message> deduped = {};
      for (final m in enrichedMsgs) {
        deduped[m.id] = m;
      }
      for (final temp in pendingTemp) {
        if (!deduped.containsKey(temp.id)) {
          deduped[temp.id] = temp;
        }
      }

      final merged = deduped.values.toList()
        ..sort((a, b) {
          final cmp = a.createdAt.compareTo(b.createdAt);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });

      _messagesByActivity[activityId] = merged;

      // Pre-fetch all polls and expenses in messages in background
      for (final m in msgs) {
        final pid = m.pollId;
        if (pid != null) unawaited(fetchPollIfNeeded(pid));
        final eid = m.expenseId;
        if (eid != null) unawaited(fetchExpenseIfNeeded(eid));
      }

      if (!_isDisposed) {
        notifyListeners();
        _subscribeActivityChat(activityId);
      }
    } catch (e) {
      debugPrint('fetchMessagesForActivity error: $e');
    }
  }

  /// Loads older history messages on-demand using cursor-based pagination
  Future<bool> fetchOlderMessagesForActivity(String activityId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;
    if (_isLoadingOlder[activityId] == true ||
        _hasMoreOlderMessages[activityId] == false) {
      return false;
    }

    _isLoadingOlder[activityId] = true;
    notifyListeners();

    try {
      final currentList = _messagesByActivity[activityId] ?? [];
      final persisted = currentList
          .where((m) => !m.isSending && !m.isFailed)
          .toList();
      if (persisted.isEmpty) {
        _isLoadingOlder[activityId] = false;
        notifyListeners();
        return false;
      }

      final oldest = persisted.first;
      dynamic res;
      try {
        res = await client
            .from('messages')
            .select(
              'id, activity_id, sender_id, text, created_at, profiles_public(id, username, full_name, avatar_url)',
            )
            .eq('activity_id', activityId)
            .lt('created_at', oldest.createdAt.toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(messagePageSize);
      } catch (_) {
        res = await client
            .from('messages')
            .select(
              'id, activity_id, sender_id, text, created_at, profiles(id, username, full_name, avatar_url)',
            )
            .eq('activity_id', activityId)
            .lt('created_at', oldest.createdAt.toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(messagePageSize);
      }

      if (_isDisposed) return false;

      final rawList = (res as List<dynamic>?) ?? [];
      _hasMoreOlderMessages[activityId] = rawList.length >= messagePageSize;

      if (rawList.isEmpty) {
        _isLoadingOlder[activityId] = false;
        notifyListeners();
        return true;
      }

      final olderMsgs = rawList
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();

      // Batch enrich sender profiles from profiles_public
      final missingOlderSenderIds = olderMsgs
          .map((m) => m.senderId)
          .where((id) => id.isNotEmpty && !_profileCache.containsKey(id))
          .toSet();

      if (missingOlderSenderIds.isNotEmpty) {
        try {
          final profRes = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url')
              .inFilter('id', missingOlderSenderIds.toList());
          for (final p in (profRes as List<dynamic>)) {
            final pid = p['id']?.toString();
            if (pid != null) {
              _profileCache[pid] = UserProfile.fromJson(
                p as Map<String, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      final enrichedOlderMsgs = olderMsgs.map((m) {
        if (m.sender != null &&
            m.sender!.fullName.isNotEmpty &&
            m.sender!.fullName != 'Squad Member' &&
            m.sender!.fullName != 'User') {
          _profileCache[m.senderId] = m.sender!;
          return m;
        }
        final cached = _profileCache[m.senderId];
        if (cached != null) {
          return m.copyWith(sender: cached);
        }
        final sm = _squadMembersByActivity[activityId]
            ?.where((s) => s.userId == m.senderId)
            .firstOrNull;
        if (sm != null && sm.name.isNotEmpty && sm.name != 'Squad Member') {
          final p = UserProfile(
            id: sm.userId,
            fullName: sm.name,
            username: sm.name,
            avatarUrl: sm.avatarUrl,
          );
          _profileCache[sm.userId] = p;
          return m.copyWith(sender: p);
        }
        return m;
      }).toList();

      final Map<String, Message> deduped = {};
      for (final m in enrichedOlderMsgs) {
        deduped[m.id] = m;
      }
      for (final m in currentList) {
        deduped[m.id] = m;
      }

      final merged = deduped.values.toList()
        ..sort((a, b) {
          final cmp = a.createdAt.compareTo(b.createdAt);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });

      _messagesByActivity[activityId] = merged;

      for (final m in olderMsgs) {
        final pid = m.pollId;
        if (pid != null) unawaited(fetchPollIfNeeded(pid));
        final eid = m.expenseId;
        if (eid != null) unawaited(fetchExpenseIfNeeded(eid));
      }

      return true;
    } catch (e) {
      debugPrint('fetchOlderMessagesForActivity error: $e');
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoadingOlder[activityId] = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchExpense(String expenseId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      // 1. Fetch expense row
      final expRes = await client
          .from('expenses')
          .select('*')
          .eq('id', expenseId)
          .maybeSingle();

      if (expRes == null) return;
      final expData = Map<String, dynamic>.from(expRes);
      final activityId = expData['activity_id']?.toString() ?? '';

      // 2. Fetch expense shares
      List<dynamic> sharesList = [];
      try {
        final sharesRes = await client
            .from('expense_shares')
            .select('*')
            .eq('expense_id', expenseId)
            .order('created_at', ascending: true);
        sharesList = (sharesRes as List<dynamic>?) ?? [];
      } catch (e) {
        debugPrint('fetchExpense shares query error: $e');
      }

      // 3. Collect all user IDs involved
      final Set<String> userIds = {};
      final creatorUid = expData['created_by']?.toString();
      if (creatorUid != null && creatorUid.isNotEmpty) {
        userIds.add(creatorUid);
      }
      for (final s in sharesList) {
        final uid = s['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          userIds.add(uid);
        }
      }

      // 4. Batch query profiles for all involved members
      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profRes = await client
              .from('profiles')
              .select('id, full_name, username, avatar_url')
              .inFilter('id', userIds.toList());

          for (final p in (profRes as List<dynamic>)) {
            final pid = p['id']?.toString();
            if (pid != null) {
              profilesMap[pid] = Map<String, dynamic>.from(p);
            }
          }
        } catch (e) {
          debugPrint('fetchExpense profiles query error: $e');
        }
      }

      // Fallback to cached squad members for any missing profiles
      if (activityId.isNotEmpty &&
          _squadMembersByActivity.containsKey(activityId)) {
        for (final m in _squadMembersByActivity[activityId]!) {
          if (!profilesMap.containsKey(m.userId) ||
              (profilesMap[m.userId]?['full_name'] == null &&
                  profilesMap[m.userId]?['username'] == null)) {
            profilesMap[m.userId] = {
              'id': m.userId,
              'full_name': m.name,
              'username': m.name,
              'avatar_url': m.avatarUrl,
            };
          }
        }
      }

      // 5. Attach creator profile
      if (creatorUid != null && profilesMap.containsKey(creatorUid)) {
        expData['profiles'] = profilesMap[creatorUid];
      }

      // 6. Enrich shares with profile data
      final List<Map<String, dynamic>> enrichedShares = [];
      for (final s in sharesList) {
        final shareMap = Map<String, dynamic>.from(s as Map<String, dynamic>);
        final uid = shareMap['user_id']?.toString();
        if (uid != null && profilesMap.containsKey(uid)) {
          shareMap['profiles'] = profilesMap[uid];
        }
        enrichedShares.add(shareMap);
      }
      expData['expense_shares'] = enrichedShares;

      if (!_isDisposed) {
        final exp = Expense.fromJson(expData);
        _expenses[exp.id] = exp;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchExpense fatal error: $e');
    }
  }

  bool _pollsEqual(Poll a, Poll b) {
    if (a.id != b.id) return false;
    if (a.question != b.question) return false;
    if (a.isClosed != b.isClosed) return false;
    if (a.options.length != b.options.length) return false;
    for (int i = 0; i < a.options.length; i++) {
      final optA = a.options[i];
      final optB = b.options[i];
      if (optA.id != optB.id || optA.text != optB.text) return false;
      if (optA.voterIds.length != optB.voterIds.length) return false;
      final setA = optA.voterIds.map((v) => v.trim().toLowerCase()).toSet();
      final setB = optB.voterIds.map((v) => v.trim().toLowerCase()).toSet();
      if (!setA.containsAll(setB)) return false;
    }
    return true;
  }

  Future<void> fetchPoll(String pollId, {bool force = false}) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;
    // Don't overwrite state while user is actively voting on this poll unless forced
    if (!force && _votingPollIds.contains(pollId)) return;

    try {
      final fetchedPoll = await _pollService.fetchPoll(pollId);

      if (fetchedPoll == null) {
        return;
      }

      if (!_isDisposed && (force || !_votingPollIds.contains(pollId))) {
        Poll poll = fetchedPoll;

        // Safeguard recent local user vote against replication delay:
        final recentOptionIdx = _userPollVotes[pollId];
        final recentVoteTime = _userPollVoteTimes[pollId];
        final currentUid = client.auth.currentUser?.id.trim().toLowerCase();

        if (recentOptionIdx != null &&
            recentVoteTime != null &&
            currentUid != null &&
            DateTime.now().difference(recentVoteTime).inSeconds < 15) {
          final serverVoted = poll.userVotedOptionId(currentUid);
          if (serverVoted == null ||
              serverVoted != recentOptionIdx.toString()) {
            // Server hasn't reflected local vote yet; merge local vote into poll
            final mergedOptions = poll.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final voters = opt.voterIds
                  .where((v) => v.trim().toLowerCase() != currentUid)
                  .toList();
              if (idx == recentOptionIdx) {
                voters.add(currentUid);
              }
              return opt.copyWith(voterIds: voters);
            }).toList();
            poll = poll.copyWith(options: mergedOptions);
          } else {
            // Server has caught up; clear tracking
            _userPollVotes.remove(pollId);
            _userPollVoteTimes.remove(pollId);
          }
        }

        final existing = _polls[poll.id];
        if (existing == null || !_pollsEqual(existing, poll)) {
          _polls[poll.id] = poll;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('fetchPoll fatal error: $e');
    }
  }

  void _subscribeActivityChat(String activityId) {
    if (_activeChannels.containsKey(activityId) || _isDisposed) return;
    final client = SupabaseService.client;
    if (client == null) return;

    final channel = client
        .channel('chat_activity_$activityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'activity_id',
            value: activityId,
          ),
          callback: (payload) {
            if (!_isDisposed) {
              _handleRealtimeMessageEvent(activityId, payload);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'activity_id',
            value: activityId,
          ),
          callback: (payload) {
            if (!_isDisposed) {
              if (payload.eventType == PostgresChangeEvent.delete) {
                final pollId = payload.oldRecord['id']?.toString();
                if (pollId != null) {
                  final existing = _polls[pollId];
                  if (existing != null) {
                    _polls[pollId] = existing.copyWith(isDeleted: true);
                    notifyListeners();
                  }
                }
                return;
              }
              final pollId =
                  payload.newRecord['id']?.toString() ??
                  payload.oldRecord['id']?.toString();
              if (pollId != null) {
                fetchPoll(pollId, force: true);
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'poll_votes',
          callback: (payload) {
            if (!_isDisposed) {
              final pollId =
                  payload.newRecord['poll_id']?.toString() ??
                  payload.oldRecord['poll_id']?.toString();
              if (pollId != null) {
                fetchPoll(pollId, force: true);
              } else {
                // On DELETE events (vote retraction), oldRecord may lack poll_id under default REPLICA IDENTITY.
                // Refresh all loaded polls for this activity so vote counts remain synced across all users.
                for (final pId in _polls.keys.toList()) {
                  fetchPoll(pId, force: true);
                }
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'activity_id',
            value: activityId,
          ),
          callback: (payload) {
            if (!_isDisposed) {
              final expId =
                  payload.newRecord['id']?.toString() ??
                  payload.oldRecord['id']?.toString();
              if (expId != null) {
                fetchExpense(expId);
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_shares',
          callback: (payload) {
            if (!_isDisposed) {
              final expId =
                  payload.newRecord['expense_id']?.toString() ??
                  payload.oldRecord['expense_id']?.toString();
              if (expId != null && _expenses.containsKey(expId)) {
                fetchExpense(expId);
              }
            }
          },
        )
        .subscribe();

    _activeChannels[activityId] = channel;
  }

  void _handleRealtimeMessageEvent(
    String activityId,
    PostgresChangePayload payload,
  ) {
    if (_isDisposed) return;
    final currentList = _messagesByActivity.putIfAbsent(activityId, () => []);

    if (payload.eventType == PostgresChangeEvent.insert) {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final msgId = newRecord['id']?.toString();
      if (msgId == null || msgId.isEmpty) return;

      // Check if message is already in list (e.g. from optimistic insert)
      final existingIdx = currentList.indexWhere((m) => m.id == msgId);
      if (existingIdx != -1) {
        final existing = currentList[existingIdx];
        currentList[existingIdx] = existing.copyWith(
          isSending: false,
          isFailed: false,
          createdAt: DateFormatter.parseServerDateTime(newRecord['created_at']),
        );
        notifyListeners();
        return;
      }

      // Incoming message from another user or confirmed send
      final senderId = newRecord['sender_id']?.toString() ?? '';
      UserProfile? senderProfile = _profileCache[senderId];
      if (senderProfile == null) {
        final cachedMembers = _squadMembersByActivity[activityId];
        if (cachedMembers != null) {
          final member = cachedMembers
              .where((m) => m.userId == senderId)
              .firstOrNull;
          if (member != null &&
              member.name.isNotEmpty &&
              member.name != 'Squad Member') {
            senderProfile = UserProfile(
              id: member.userId,
              username: member.name,
              fullName: member.name,
              avatarUrl: member.avatarUrl,
            );
            _profileCache[senderId] = senderProfile;
          }
        }
      }

      final msg = Message(
        id: msgId,
        activityId: activityId,
        senderId: senderId,
        text: newRecord['text']?.toString() ?? '',
        createdAt: DateFormatter.parseServerDateTime(newRecord['created_at']),
        sender: senderProfile,
        isSending: false,
        isFailed: false,
      );

      // If profile is still unknown, fetch it asynchronously and update in-memory
      if (senderProfile == null && senderId.isNotEmpty) {
        unawaited(_fetchAndCacheProfile(senderId, activityId, msgId));
      }

      currentList.add(msg);
      currentList.sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      final pid = msg.pollId;
      if (pid != null) unawaited(fetchPollIfNeeded(pid));
      final eid = msg.expenseId;
      if (eid != null) unawaited(fetchExpenseIfNeeded(eid));

      // Native notification when not actively viewing this chat
      final currentUid = SupabaseService.client?.auth.currentUser?.id;
      if (currentUid != null &&
          senderId != currentUid &&
          _activeChatActivityId != activityId) {
        final senderDisplayName = senderProfile?.fullName.isNotEmpty == true
            ? senderProfile!.fullName
            : (senderProfile?.username.isNotEmpty == true
                ? senderProfile!.username
                : 'Squad Member');

        String notifBody = msg.text;
        if (msg.pollId != null) {
          notifBody = '📊 Created a group poll';
        } else if (msg.expenseId != null) {
          notifBody = '💰 Added an expense split';
        }

        NotificationService().showNotification(
          title: 'Squad: $senderDisplayName',
          body: notifBody,
          channelType: NotificationChannelType.messages,
          deduplicationKey: 'msg_$msgId',
        );
      }

      notifyListeners();
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id']?.toString();
      if (oldId != null) {
        currentList.removeWhere((m) => m.id == oldId);
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updId = payload.newRecord['id']?.toString();
      if (updId != null) {
        final idx = currentList.indexWhere((m) => m.id == updId);
        if (idx != -1) {
          currentList[idx] = currentList[idx].copyWith(
            text:
                payload.newRecord['text']?.toString() ?? currentList[idx].text,
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> _fetchAndCacheProfile(
    String userId,
    String activityId,
    String msgId,
  ) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;
    try {
      final res = await client
          .from('profiles_public')
          .select('id, full_name, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && !_isDisposed) {
        final profile = UserProfile.fromJson(res);
        _profileCache[userId] = profile;
        final list = _messagesByActivity[activityId];
        if (list != null) {
          final idx = list.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            list[idx] = list[idx].copyWith(sender: profile);
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  void reconnectActiveSubscriptions() {
    if (_isDisposed) return;
    final activityIds = Set<String>.from(_activeChannels.keys);
    if (_activeChatActivityId != null && _activeChatActivityId!.isNotEmpty) {
      activityIds.add(_activeChatActivityId!);
    }
    for (final id in activityIds) {
      _activeChannels[id]?.unsubscribe();
      _activeChannels.remove(id);
      _subscribeActivityChat(id);
      fetchMessagesForActivity(id);
    }
  }

  /// Fetches all joined and confirmed squad members (Host + all accepted attendees).
  /// Uses get_squad_members security-definer RPC with fallback to direct queries.
  Future<List<ExpenseMember>> fetchSquadMembers(String activityId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) {
      return _squadMembersByActivity[activityId] ?? const [];
    }

    try {
      // 1. Try security-definer RPC
      final rpcRes = await client.rpc(
        'get_squad_members',
        params: {'_activity_id': activityId},
      );
      if (rpcRes is List<dynamic> && rpcRes.isNotEmpty) {
        final list = rpcRes.map((item) {
          final map = item as Map<String, dynamic>;
          final name =
              map['full_name']?.toString() ??
              map['username']?.toString() ??
              'Squad Member';
          final uid = map['user_id']?.toString() ?? '';
          final avatar = map['avatar_url']?.toString();

          if (uid.isNotEmpty && name.isNotEmpty && name != 'Squad Member') {
            _profileCache[uid] = UserProfile(
              id: uid,
              fullName: name,
              username: name,
              avatarUrl: avatar,
            );
          }

          return ExpenseMember(
            userId: uid,
            name: name,
            avatarUrl: avatar,
            amount: 0.0,
            isPaid: false,
          );
        }).toList();
        _squadMembersByActivity[activityId] = list;
        if (!_isDisposed) notifyListeners();
        return list;
      }
    } catch (_) {
      // Fallback below
    }

    try {
      // 2. Query activity host
      final actRes = await client
          .from('activities')
          .select('id, host_id')
          .eq('id', activityId)
          .maybeSingle();

      final hostId = actRes?['host_id']?.toString();

      // Query accepted join requests with safe non-sensitive profile columns
      dynamic reqsRes;
      try {
        reqsRes = await client
            .from('join_requests')
            .select(
              'user_id, status, profiles_public(id, full_name, username, avatar_url)',
            )
            .eq('activity_id', activityId)
            .eq('status', 'accepted');
      } catch (_) {
        try {
          reqsRes = await client
              .from('join_requests')
              .select(
                'user_id, status, profiles(id, full_name, username, avatar_url)',
              )
              .eq('activity_id', activityId)
              .eq('status', 'accepted');
        } catch (_) {
          reqsRes = await client
              .from('join_requests')
              .select('user_id, status')
              .eq('activity_id', activityId)
              .eq('status', 'accepted');
        }
      }

      final participantUserIds = <String>{};
      if (hostId != null) participantUserIds.add(hostId);

      final reqsList = (reqsRes as List<dynamic>?) ?? [];
      for (final r in reqsList) {
        final uid = r['user_id']?.toString();
        if (uid != null) participantUserIds.add(uid);
      }

      // Fetch profiles for all participantUserIds
      final Map<String, UserProfile> profMap = {};
      if (participantUserIds.isNotEmpty) {
        try {
          final profs = await client
              .from('profiles_public')
              .select('id, full_name, username, avatar_url')
              .inFilter('id', participantUserIds.toList());
          for (final p in profs) {
            final uid = p['id']?.toString();
            if (uid != null) {
              profMap[uid] = UserProfile.fromJson(p);
            }
          }
        } catch (_) {
          try {
            final profs = await client
                .from('profiles')
                .select('id, full_name, username, avatar_url')
                .inFilter('id', participantUserIds.toList());
            for (final p in profs) {
              final uid = p['id']?.toString();
              if (uid != null) {
                profMap[uid] = UserProfile.fromJson(p);
              }
            }
          } catch (_) {}
        }
      }

      final members = <ExpenseMember>[];
      // Host first
      if (hostId != null) {
        final hostProf = profMap[hostId];
        members.add(
          ExpenseMember(
            userId: hostId,
            name: hostProf?.fullName ?? hostProf?.username ?? 'Host',
            avatarUrl: hostProf?.avatarUrl,
            amount: 0.0,
            isPaid: false,
          ),
        );
      }

      // Accepted members
      for (final r in reqsList) {
        final uid = r['user_id']?.toString();
        if (uid != null && uid != hostId) {
          final prof =
              profMap[uid] ??
              (r['profiles_public'] != null
                  ? UserProfile.fromJson(
                      r['profiles_public'] as Map<String, dynamic>,
                    )
                  : null);
          members.add(
            ExpenseMember(
              userId: uid,
              name: prof?.fullName ?? prof?.username ?? 'Squad Member',
              avatarUrl: prof?.avatarUrl,
              amount: 0.0,
              isPaid: false,
            ),
          );
        }
      }

      for (final m in members) {
        if (m.name.isNotEmpty && m.name != 'Squad Member') {
          _profileCache[m.userId] = UserProfile(
            id: m.userId,
            fullName: m.name,
            username: m.name,
            avatarUrl: m.avatarUrl,
          );
        }
      }

      _squadMembersByActivity[activityId] = members;
      if (!_isDisposed) notifyListeners();
      return members;
    } catch (e) {
      debugPrint('fetchSquadMembers error: $e');
      return _squadMembersByActivity[activityId] ?? const [];
    }
  }

  /// Loads all chats the user hosts or joined, regardless of Explore screen location/radius.
  Future<void> fetchUserChats(String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    _isLoadingUserChats = true;
    if (!_isDisposed) notifyListeners();

    try {
      // 1. Hosted activities
      dynamic hostedRes;
      try {
        hostedRes = await client
            .from('activities')
            .select('*, profiles_public(id, full_name, username, avatar_url)')
            .eq('host_id', userId)
            .filter('deleted_at', 'is', null)
            .order('date_time', ascending: false);
      } catch (_) {
        try {
          hostedRes = await client
              .from('activities')
              .select('*, profiles(id, full_name, username, avatar_url)')
              .eq('host_id', userId)
              .filter('deleted_at', 'is', null)
              .order('date_time', ascending: false);
        } catch (_) {
          hostedRes = await client
              .from('activities')
              .select('*')
              .eq('host_id', userId)
              .filter('deleted_at', 'is', null)
              .order('date_time', ascending: false);
        }
      }

      // 2. Joined activities (status = 'accepted')
      final joinedReqs = await client
          .from('join_requests')
          .select('activity_id')
          .eq('user_id', userId)
          .eq('status', 'accepted');

      final joinedActivityIds = ((joinedReqs as List<dynamic>?) ?? [])
          .map((r) => r['activity_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final List<Activity> combined = [];
      if (hostedRes is List<dynamic>) {
        combined.addAll(
          hostedRes.map((j) => Activity.fromJson(j as Map<String, dynamic>)),
        );
      }

      if (joinedActivityIds.isNotEmpty) {
        dynamic joinedRes;
        try {
          joinedRes = await client
              .from('activities')
              .select('*, profiles_public(id, full_name, username, avatar_url)')
              .inFilter('id', joinedActivityIds)
              .filter('deleted_at', 'is', null);
        } catch (_) {
          try {
            joinedRes = await client
                .from('activities')
                .select('*, profiles(id, full_name, username, avatar_url)')
                .inFilter('id', joinedActivityIds)
                .filter('deleted_at', 'is', null);
          } catch (_) {
            joinedRes = await client
                .from('activities')
                .select('*')
                .inFilter('id', joinedActivityIds)
                .filter('deleted_at', 'is', null);
          }
        }

        if (joinedRes is List<dynamic>) {
          for (final j in joinedRes) {
            final act = Activity.fromJson(j as Map<String, dynamic>);
            if (!combined.any((a) => a.id == act.id)) {
              combined.add(act);
            }
          }
        }
      }

      // Sort by date_time descending
      combined.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _userChats = combined;

      // Pre-fetch latest messages for previews in background
      for (final chat in combined.take(15)) {
        if (!_messagesByActivity.containsKey(chat.id)) {
          unawaited(fetchMessagesForActivity(chat.id));
        }
      }
    } catch (e) {
      debugPrint('fetchUserChats error: $e');
    } finally {
      if (!_isDisposed) {
        _isLoadingUserChats = false;
        notifyListeners();
      }
    }
  }

  Future<bool> sendMessage({
    required String activityId,
    required String senderId,
    required String text,
    UserProfile? sender,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    // Enforce server-side verified auth ID to prevent sender spoofing
    final verifiedSenderId = client.auth.currentUser?.id ?? senderId;

    // Durable client-generated v4 UUID ensures stable idempotency across retries and connections
    final clientMsgId = const Uuid().v4();
    final optimisticMsg = Message(
      id: clientMsgId,
      activityId: activityId,
      senderId: verifiedSenderId,
      text: text,
      createdAt: DateTime.now().toUtc(),
      sender: sender,
      isSending: true,
      isFailed: false,
    );

    final currentList = _messagesByActivity.putIfAbsent(activityId, () => []);
    currentList.add(optimisticMsg);
    if (!_isDisposed) notifyListeners();

    try {
      // Keep the message insert independent from optional profile relations.
      // A relation-select can fail after the insert has already committed;
      // retrying the same UUID would then turn a successful insert into a
      // misleading duplicate-key failure.
      final inserted = await client
          .from('messages')
          .insert({
            'id': clientMsgId,
            'activity_id': activityId,
            'sender_id': verifiedSenderId,
            'text': text,
          })
          .select('id, activity_id, sender_id, text, created_at')
          .maybeSingle();

      if (inserted == null) {
        throw StateError('Message insert returned no row');
      }

      if (!_isDisposed) {
        final realMsg = Message.fromJson(inserted).copyWith(sender: sender);
        final idx = currentList.indexWhere((m) => m.id == clientMsgId);
        if (idx != -1) {
          currentList[idx] = realMsg;
        } else if (!currentList.any((m) => m.id == realMsg.id)) {
          currentList.add(realMsg);
        }
        currentList.sort((a, b) {
          final cmp = a.createdAt.compareTo(b.createdAt);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });
        notifyListeners();
      }

      if (!_activeChannels.containsKey(activityId)) {
        await fetchMessagesForActivity(activityId);
      }
      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      // DO NOT delete optimistic message. Mark it failed so user can safely retry!
      final idx = currentList.indexWhere((m) => m.id == clientMsgId);
      if (idx != -1) {
        currentList[idx] = currentList[idx].copyWith(
          isSending: false,
          isFailed: true,
        );
      }
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  /// Retries sending a previously failed message with durable ID idempotency.
  Future<bool> retrySendMessage(Message failedMsg) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    final currentList = _messagesByActivity[failedMsg.activityId];
    if (currentList == null) return false;

    final idx = currentList.indexWhere((m) => m.id == failedMsg.id);
    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(
        isSending: true,
        isFailed: false,
      );
      notifyListeners();
    }

    final verifiedSenderId = client.auth.currentUser?.id ?? failedMsg.senderId;

    try {
      // Upsert by primary key is idempotent when retrying a message whose
      // original insert may already have committed.
      final inserted = await client
          .from('messages')
          .upsert({
            'id': failedMsg.id,
            'activity_id': failedMsg.activityId,
            'sender_id': verifiedSenderId,
            'text': failedMsg.text,
          }, onConflict: 'id')
          .select('id, activity_id, sender_id, text, created_at')
          .maybeSingle();

      if (inserted == null) {
        throw StateError('Message retry returned no row');
      }

      if (!_isDisposed) {
        final realMsg = Message.fromJson(inserted)
            .copyWith(sender: failedMsg.sender);
        final currentIdx = currentList.indexWhere((m) => m.id == failedMsg.id);
        if (currentIdx != -1) {
          currentList[currentIdx] = realMsg;
        } else if (!currentList.any((m) => m.id == realMsg.id)) {
          currentList.add(realMsg);
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('retrySendMessage error: $e');
      final currentIdx = currentList.indexWhere((m) => m.id == failedMsg.id);
      if (currentIdx != -1) {
        currentList[currentIdx] = currentList[currentIdx].copyWith(
          isSending: false,
          isFailed: true,
        );
      }
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> createExpense({
    required String activityId,
    required String creatorId,
    required String creatorName,
    required String description,
    required double totalAmount,
    String? upiId,
    required List<ExpenseMember> members,
    UserProfile? creator,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    try {
      final expRes = await client
          .from('expenses')
          .insert({
            'activity_id': activityId,
            'created_by': creatorId,
            'description': description.trim(),
            'total_amount': totalAmount,
            'upi_id': upiId,
          })
          .select()
          .single();

      final expId = expRes['id'] as String;

      if (members.isNotEmpty) {
        await client
            .from('expense_shares')
            .insert(
              members
                  .map(
                    (m) => {
                      'expense_id': expId,
                      'user_id': m.userId,
                      'amount': m.amount,
                      'status': m.isPaid ? 'paid' : 'pending',
                    },
                  )
                  .toList(),
            );
      }

      // Immediately store in local state with the exact member names and amounts passed in
      final initialExpense = Expense(
        id: expId,
        activityId: activityId,
        creatorId: creatorId,
        creatorName: creatorName,
        description: description.trim(),
        totalAmount: totalAmount,
        upiId: upiId,
        members: members,
        createdAt: DateTime.now(),
      );
      _expenses[expId] = initialExpense;
      notifyListeners();

      // TanStack-compatible format: [[expense:<uuid>]] <description> · ₹<amount>
      final formattedText =
          '[[expense:$expId]] ${description.trim()} · ₹${totalAmount.toStringAsFixed(2)}';

      await sendMessage(
        activityId: activityId,
        senderId: creatorId,
        text: formattedText,
        sender: creator,
      );

      // Sync to ensure server consistency
      await fetchExpense(expId);
      return true;
    } catch (e) {
      debugPrint('createExpense error: $e');
      return false;
    }
  }

  Future<bool> toggleMemberPaid(String expenseId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    final exp = _expenses[expenseId];
    if (exp == null) return false;
    final member = exp.members.where((m) => m.userId == userId).firstOrNull;
    if (member == null) return false;
    final nextPaid = !member.isPaid;

    // Optimistic local update
    final updatedMembers = exp.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(isPaid: nextPaid);
      }
      return m;
    }).toList();
    _expenses[expenseId] = exp.copyWith(members: updatedMembers);
    notifyListeners();

    try {
      await client
          .from('expense_shares')
          .update({
            'status': nextPaid ? 'paid' : 'pending',
            'paid_at': nextPaid ? DateTime.now().toIso8601String() : null,
          })
          .eq('expense_id', expenseId)
          .eq('user_id', userId);

      await fetchExpense(expenseId);
      return true;
    } catch (e) {
      debugPrint('toggleMemberPaid error: $e');
      // Revert optimistic update
      _expenses[expenseId] = exp;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  Future<bool> createPoll({
    required String activityId,
    required String creatorId,
    required String question,
    required List<String> optionTexts,
    UserProfile? creator,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    // Enforce server-side authenticated user identity
    final authUser = client.auth.currentUser;
    final verifiedCreatorId = (authUser?.id ?? creatorId).trim().toLowerCase();
    if (verifiedCreatorId.isEmpty) {
      debugPrint('createPoll error: Unauthenticated user');
      return false;
    }

    try {
      final pollId = const Uuid().v4();

      // Optimistically store poll immediately so it renders in 0 ms
      final initialPoll = Poll(
        id: pollId,
        activityId: activityId,
        creatorId: verifiedCreatorId,
        question: question.trim(),
        options: optionTexts
            .asMap()
            .entries
            .map(
              (e) => PollOption(
                id: e.key.toString(),
                text: e.value,
                voterIds: const [],
              ),
            )
            .toList(),
        createdAt: DateTime.now().toUtc(),
      );
      _polls[pollId] = initialPoll;
      notifyListeners();

      await _pollService.createPoll(
        activityId: activityId,
        creatorId: verifiedCreatorId,
        question: question,
        optionTexts: optionTexts,
        clientPollId: pollId,
      );

      // TanStack-compatible format: [[poll:<uuid>]] <question>
      final formattedText = '[[poll:$pollId]] ${question.trim()}';

      final messageSent = await sendMessage(
        activityId: activityId,
        senderId: verifiedCreatorId,
        text: formattedText,
        sender: creator,
      );

      if (!messageSent) {
        debugPrint(
          'createPoll: poll $pollId was saved, but its chat message failed',
        );
        return false;
      }

      await fetchPoll(pollId, force: true);
      return true;
    } catch (e) {
      debugPrint('createPoll error: $e');
      return false;
    }
  }

  Future<bool> updatePoll({
    required String pollId,
    required String creatorId,
    required String question,
    List<String>? optionTexts,
  }) async {
    if (_isDisposed) return false;
    final client = SupabaseService.client;
    final authUser = client?.auth.currentUser;
    final verifiedCreatorId = (authUser?.id ?? creatorId).trim().toLowerCase();
    if (verifiedCreatorId.isEmpty) return false;

    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      List<PollOption>? updatedOptions;
      if (optionTexts != null && optionTexts.length >= 2) {
        updatedOptions = optionTexts
            .asMap()
            .entries
            .map(
              (e) => PollOption(
                id: e.key.toString(),
                text: e.value,
                voterIds: currentPoll.options.length > e.key
                    ? currentPoll.options[e.key].voterIds
                    : const [],
              ),
            )
            .toList();
      }
      _polls[pollId] = currentPoll.copyWith(
        question: question.trim(),
        options: updatedOptions,
      );
      notifyListeners();
    }

    if (client == null) {
      return true;
    }

    try {
      final success = await _pollService.updatePoll(
        pollId: pollId,
        creatorId: verifiedCreatorId,
        question: question,
        optionTexts: optionTexts,
      );

      if (success) {
        // Synchronize in-memory message text if present in activity messages
        for (final entry in _messagesByActivity.entries) {
          final idx = entry.value.indexWhere((m) => m.pollId == pollId);
          if (idx != -1) {
            final old = entry.value[idx];
            entry.value[idx] = old.copyWith(
              text: '[[poll:$pollId]] ${question.trim()}',
            );
            notifyListeners();
            break;
          }
        }
        await fetchPoll(pollId, force: true);
      } else if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updatePoll error: $e');
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> togglePollClosed({
    required String pollId,
    required String creatorId,
    required bool close,
  }) async {
    if (_isDisposed) return false;
    final client = SupabaseService.client;
    final authUser = client?.auth.currentUser;
    final verifiedCreatorId = (authUser?.id ?? creatorId).trim().toLowerCase();
    if (verifiedCreatorId.isEmpty) return false;

    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      _polls[pollId] = currentPoll.copyWith(
        closedAt: close ? DateTime.now().toUtc() : null,
        clearClosedAt: !close,
      );
      notifyListeners();
    }

    if (client == null) {
      return true;
    }

    try {
      final success = await _pollService.togglePollClosed(
        pollId: pollId,
        creatorId: verifiedCreatorId,
        close: close,
      );

      if (success) {
        await fetchPoll(pollId, force: true);
      } else if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('togglePollClosed error: $e');
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> deletePoll({
    required String pollId,
    required String creatorId,
    required String activityId,
  }) async {
    if (_isDisposed) return false;
    final client = SupabaseService.client;
    final authUser = client?.auth.currentUser;
    final verifiedCreatorId = (authUser?.id ?? creatorId).trim().toLowerCase();
    if (verifiedCreatorId.isEmpty) return false;

    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      _polls[pollId] = currentPoll.copyWith(isDeleted: true);
      notifyListeners();
    }

    if (client == null) {
      return true;
    }

    try {
      final success = await _pollService.deletePoll(
        pollId: pollId,
        creatorId: verifiedCreatorId,
      );

      if (!success && currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deletePoll error: $e');
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> votePoll(String pollId, String optionId, String userId) async {
    final client = SupabaseService.client;
    final authUser = client?.auth.currentUser;
    final verifiedUserId = (authUser?.id ?? userId).trim().toLowerCase();
    if (verifiedUserId.isEmpty) {
      debugPrint('votePoll error: Unauthenticated user');
      return false;
    }

    final currentPoll = _polls[pollId];
    if (currentPoll != null && (currentPoll.isClosed || currentPoll.isDeleted)) {
      debugPrint('votePoll error: Poll is closed or deleted');
      return false;
    }

    int optionIdx = -1;
    if (currentPoll != null) {
      optionIdx = currentPoll.options.indexWhere(
        (o) => o.id == optionId || o.text == optionId,
      );
    }
    if (optionIdx == -1) {
      optionIdx = int.tryParse(optionId) ?? 0;
    }

    // Lock poll ID and record local vote to prevent background periodic sync from overwriting optimistic UI
    _votingPollIds.add(pollId);
    _userPollVotes[pollId] = optionIdx;
    _userPollVoteTimes[pollId] = DateTime.now();

    // Optimistic local update (instant 0 ms visual response)
    if (currentPoll != null) {
      final updatedOptions = currentPoll.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final newVoters = opt.voterIds
            .where((v) => v.trim().toLowerCase() != verifiedUserId)
            .toList();
        if (idx == optionIdx) {
          newVoters.add(verifiedUserId);
        }
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      _polls[pollId] = currentPoll.copyWith(options: updatedOptions);
      if (!_isDisposed) notifyListeners();
    }

    if (client == null) {
      // Local/offline test mode
      _votingPollIds.remove(pollId);
      return true;
    }

    try {
      final ok = await _pollService.votePoll(
        pollId: pollId,
        userId: verifiedUserId,
        optionIndex: optionIdx,
      );

      _votingPollIds.remove(pollId);
      if (ok) {
        await fetchPoll(pollId, force: true);
      } else if (currentPoll != null) {
        _userPollVotes.remove(pollId);
        _userPollVoteTimes.remove(pollId);
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('votePoll error: $e');
      _votingPollIds.remove(pollId);
      _userPollVotes.remove(pollId);
      _userPollVoteTimes.remove(pollId);
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return false;
    } finally {
      _votingPollIds.remove(pollId);
    }
  }

  Future<bool> retractPollVote(String pollId, String userId) async {
    if (_isDisposed) return false;

    final client = SupabaseService.client;
    final authUser = client?.auth.currentUser;
    final verifiedUserId = (authUser?.id ?? userId).trim().toLowerCase();
    if (verifiedUserId.isEmpty) return false;

    _votingPollIds.add(pollId);
    _userPollVotes.remove(pollId);
    _userPollVoteTimes.remove(pollId);

    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      final updatedOptions = currentPoll.options.map((opt) {
        final newVoters = opt.voterIds
            .where((v) => v.trim().toLowerCase() != verifiedUserId)
            .toList();
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      _polls[pollId] = currentPoll.copyWith(options: updatedOptions);
      if (!_isDisposed) notifyListeners();
    }

    if (client == null) {
      _votingPollIds.remove(pollId);
      return true;
    }

    try {
      final ok = await _pollService.retractVote(
        pollId: pollId,
        userId: verifiedUserId,
      );

      _votingPollIds.remove(pollId);
      if (ok) {
        await fetchPoll(pollId, force: true);
      } else if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('retractPollVote error: $e');
      _votingPollIds.remove(pollId);
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return false;
    } finally {
      _votingPollIds.remove(pollId);
    }
  }

  Future<void> submitRating(RatingItem rating) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      await client.from('ratings').insert({
        'plan_id': rating.planId,
        'reviewer_id': rating.reviewerId,
        'reviewee_id': rating.revieweeId,
        'rating': rating.rating,
        'badges': rating.badges,
        'comment': rating.comment,
      });

      // Recalculation is automatically handled by the database trigger
      // `ratings_recalc_aiud` on insert/update/delete.

      final idx = _ratings.indexWhere((r) => r.id == rating.id);
      if (idx != -1) {
        _ratings[idx] = rating;
      } else {
        _ratings.add(rating);
      }
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('submitRating error: $e');
    }
  }

  RatingItem? getMyRating(String planId, String reviewerId, String revieweeId) {
    try {
      return _ratings.firstWhere(
        (r) =>
            r.planId == planId &&
            r.reviewerId == reviewerId &&
            r.revieweeId == revieweeId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reset all local chat cache and unsubscribe from realtime channels (e.g. on logout)
  void clear() {
    for (final channel in _activeChannels.values) {
      channel.unsubscribe();
    }
    _activeChannels.clear();
    _messagesByActivity.clear();
    _expenses.clear();
    _polls.clear();
    _userPollVotes.clear();
    _userPollVoteTimes.clear();
    _votingPollIds.clear();
    _ratings.clear();
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final channel in _activeChannels.values) {
      channel.unsubscribe();
    }
    super.dispose();
  }
}
