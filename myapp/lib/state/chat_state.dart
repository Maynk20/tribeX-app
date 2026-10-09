import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../models/expense.dart';
import '../models/message.dart';
import '../models/poll.dart';
import '../models/rating_item.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ChatState extends ChangeNotifier {
  final Map<String, List<Message>> _messagesByActivity = {};
  final Map<String, Expense> _expenses = {};
  final Map<String, Poll> _polls = {};
  final List<RatingItem> _ratings = [];
  final Set<String> _pendingExpenseFetches = {};
  final Set<String> _pendingPollFetches = {};
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, List<ExpenseMember>> _squadMembersByActivity = {};
  List<Activity> _userChats = [];
  bool _isLoadingUserChats = false;
  bool _isDisposed = false;

  List<Activity> get userChats => List.unmodifiable(_userChats);
  bool get isLoadingUserChats => _isLoadingUserChats;
  List<ExpenseMember>? getSquadMembers(String activityId) =>
      _squadMembersByActivity[activityId];

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

  Future<void> fetchPollIfNeeded(String pollId) async {
    if (_polls.containsKey(pollId) ||
        _pendingPollFetches.contains(pollId) ||
        _isDisposed) {
      return;
    }
    _pendingPollFetches.add(pollId);
    try {
      await fetchPoll(pollId);
    } finally {
      _pendingPollFetches.remove(pollId);
    }
  }

  Future<void> fetchMessagesForActivity(String activityId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      dynamic res;
      try {
        res = await client
            .from('messages')
            .select('*, profiles_public(*)')
            .eq('activity_id', activityId)
            .order('created_at', ascending: true);
      } catch (_) {
        res = await client
            .from('messages')
            .select('*, profiles(*)')
            .eq('activity_id', activityId)
            .order('created_at', ascending: true);
      }

      if (_isDisposed) return;

      final msgs = (res as List<dynamic>)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();

      final currentList = _messagesByActivity[activityId] ?? [];
      final pendingTemp = currentList
          .where((m) => m.id.startsWith('temp_'))
          .toList();

      final Map<String, Message> deduped = {};
      for (final m in msgs) {
        deduped[m.id] = m;
      }
      for (final temp in pendingTemp) {
        final alreadyDelivered = msgs.any(
          (m) =>
              m.senderId == temp.senderId &&
              m.text == temp.text &&
              m.createdAt.difference(temp.createdAt).abs().inSeconds < 15,
        );
        if (!alreadyDelivered) {
          deduped[temp.id] = temp;
        }
      }

      final merged = deduped.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messagesByActivity[activityId] = merged;

      if (!_isDisposed) {
        notifyListeners();
        _subscribeActivityChat(activityId);
      }
    } catch (_) {}
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

  Future<void> fetchPoll(String pollId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      // 1. Fetch poll row
      final pollRes = await client
          .from('polls')
          .select('*')
          .eq('id', pollId)
          .maybeSingle();

      if (pollRes == null) return;
      final pollData = Map<String, dynamic>.from(pollRes);

      // 2. Fetch votes reliably without depending on schema cache foreign key embedding
      try {
        final votesRes = await client
            .from('poll_votes')
            .select('*')
            .eq('poll_id', pollId)
            .order('created_at', ascending: true);
        pollData['poll_votes'] = votesRes;
      } catch (e) {
        debugPrint('fetchPoll votes query error: $e');
        pollData['poll_votes'] = [];
      }

      if (!_isDisposed) {
        final poll = Poll.fromJson(pollData);
        _polls[poll.id] = poll;
        notifyListeners();
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
              fetchMessagesForActivity(activityId);
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
              final pollId =
                  payload.newRecord['id']?.toString() ??
                  payload.oldRecord['id']?.toString();
              if (pollId != null) {
                fetchPoll(pollId);
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
              if (pollId != null && _polls.containsKey(pollId)) {
                fetchPoll(pollId);
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

  void reconnectActiveSubscriptions() {
    if (_isDisposed) return;
    final activityIds = List<String>.from(_activeChannels.keys);
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
          return ExpenseMember(
            userId: map['user_id']?.toString() ?? '',
            name:
                map['full_name']?.toString() ??
                map['username']?.toString() ??
                'Squad Member',
            avatarUrl: map['avatar_url']?.toString(),
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

      // Query accepted join requests
      dynamic reqsRes;
      try {
        reqsRes = await client
            .from('join_requests')
            .select('user_id, status, profiles_public(*)')
            .eq('activity_id', activityId)
            .eq('status', 'accepted');
      } catch (_) {
        try {
          reqsRes = await client
              .from('join_requests')
              .select('user_id, status, profiles(*)')
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
              .filter('id', 'in', participantUserIds.toList());
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
                .filter('id', 'in', participantUserIds.toList());
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
            .select('*, profiles_public(*)')
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
              .select('*, profiles_public(*)')
              .filter('id', 'in', joinedActivityIds)
              .filter('deleted_at', 'is', null);
        } catch (_) {
          joinedRes = await client
              .from('activities')
              .select('*')
              .filter('id', 'in', joinedActivityIds)
              .filter('deleted_at', 'is', null);
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

    // Optimistic local update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = Message(
      id: tempId,
      activityId: activityId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      sender: sender,
      isSending: true,
      isFailed: false,
    );

    final currentList = _messagesByActivity.putIfAbsent(activityId, () => []);
    currentList.add(optimisticMsg);
    if (!_isDisposed) notifyListeners();

    try {
      dynamic inserted;
      try {
        inserted = await client
            .from('messages')
            .insert({
              'activity_id': activityId,
              'sender_id': senderId,
              'text': text,
            })
            .select('*, profiles_public(*)')
            .maybeSingle();
      } catch (_) {
        inserted = await client
            .from('messages')
            .insert({
              'activity_id': activityId,
              'sender_id': senderId,
              'text': text,
            })
            .select('*, profiles(*)')
            .maybeSingle();
      }

      if (inserted != null && !_isDisposed) {
        final realMsg = Message.fromJson(inserted as Map<String, dynamic>);
        final idx = currentList.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          currentList[idx] = realMsg;
        } else if (!currentList.any((m) => m.id == realMsg.id)) {
          currentList.add(realMsg);
        }
        notifyListeners();
      }

      if (!_activeChannels.containsKey(activityId)) {
        await fetchMessagesForActivity(activityId);
      }
      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      // DO NOT delete optimistic message. Mark it failed so user can safely retry!
      final idx = currentList.indexWhere((m) => m.id == tempId);
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

  /// Retries sending a previously failed message without losing text or creating duplicates.
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

    try {
      dynamic inserted;
      try {
        inserted = await client
            .from('messages')
            .insert({
              'activity_id': failedMsg.activityId,
              'sender_id': failedMsg.senderId,
              'text': failedMsg.text,
            })
            .select('*, profiles_public(*)')
            .maybeSingle();
      } catch (_) {
        inserted = await client
            .from('messages')
            .insert({
              'activity_id': failedMsg.activityId,
              'sender_id': failedMsg.senderId,
              'text': failedMsg.text,
            })
            .select('*, profiles(*)')
            .maybeSingle();
      }

      if (inserted != null && !_isDisposed) {
        final realMsg = Message.fromJson(inserted as Map<String, dynamic>);
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

    try {
      final pollRes = await client
          .from('polls')
          .insert({
            'activity_id': activityId,
            'created_by': creatorId,
            'question': question.trim(),
            'options': optionTexts,
          })
          .select()
          .single();

      final pollId = pollRes['id'] as String;

      // Optimistically store poll immediately so it renders in 0 ms
      final initialPoll = Poll(
        id: pollId,
        activityId: activityId,
        creatorId: creatorId,
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
        createdAt: DateTime.now(),
      );
      _polls[pollId] = initialPoll;
      notifyListeners();

      // TanStack-compatible format: [[poll:<uuid>]] <question>
      final formattedText = '[[poll:$pollId]] ${question.trim()}';

      await sendMessage(
        activityId: activityId,
        senderId: creatorId,
        text: formattedText,
        sender: creator,
      );

      // Sync to ensure server consistency
      await fetchPoll(pollId);
      return true;
    } catch (e) {
      debugPrint('createPoll error: $e');
      return false;
    }
  }

  Future<bool> votePoll(String pollId, String optionId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    final int optionIdx = int.tryParse(optionId) ?? 0;

    // Optimistic local update
    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      final updatedOptions = currentPoll.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final newVoters = List<String>.from(opt.voterIds);
        newVoters.remove(userId);
        if (idx == optionIdx) {
          newVoters.add(userId);
        }
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      _polls[pollId] = currentPoll.copyWith(options: updatedOptions);
      if (!_isDisposed) notifyListeners();
    }

    try {
      await client.from('poll_votes').upsert({
        'poll_id': pollId,
        'user_id': userId,
        'option_index': optionIdx,
      }, onConflict: 'poll_id,user_id');

      await fetchPoll(pollId);
      return true;
    } catch (e) {
      debugPrint('votePoll error: $e');
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return false;
    }
  }

  Future<bool> retractPollVote(String pollId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return false;

    final currentPoll = _polls[pollId];
    if (currentPoll != null) {
      final updatedOptions = currentPoll.options.map((opt) {
        final newVoters = List<String>.from(opt.voterIds);
        newVoters.remove(userId);
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      _polls[pollId] = currentPoll.copyWith(options: updatedOptions);
      if (!_isDisposed) notifyListeners();
    }

    try {
      await client
          .from('poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', userId);

      await fetchPoll(pollId);
      return true;
    } catch (e) {
      debugPrint('retractPollVote error: $e');
      if (currentPoll != null) {
        _polls[pollId] = currentPoll;
        if (!_isDisposed) notifyListeners();
      }
      return false;
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
