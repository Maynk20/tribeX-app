import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isDisposed = false;

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
      final res = await client
          .from('messages')
          .select('*, profiles_public(*)')
          .eq('activity_id', activityId)
          .order('created_at', ascending: true);

      if (_isDisposed) return;

      final msgs = (res as List<dynamic>)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messagesByActivity[activityId] = msgs;

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
      final res = await client
          .from('expenses')
          .select(
            '*, profiles_public(*), expense_shares(*, profiles_public(*))',
          )
          .eq('id', expenseId)
          .maybeSingle();

      if (res != null && !_isDisposed) {
        final exp = Expense.fromJson(res);
        _expenses[exp.id] = exp;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchPoll(String pollId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      final res = await client
          .from('polls')
          .select('*, poll_votes(*)')
          .eq('id', pollId)
          .maybeSingle();

      if (res != null && !_isDisposed) {
        final poll = Poll.fromJson(res);
        _polls[poll.id] = poll;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _subscribeActivityChat(String activityId) {
    if (_activeChannels.containsKey(activityId) || _isDisposed) return;
    final client = SupabaseService.client;
    if (client == null) return;

    final channel = client
        .channel('public:messages:$activityId')
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
        .subscribe();

    _activeChannels[activityId] = channel;
  }

  Future<void> sendMessage({
    required String activityId,
    required String senderId,
    required String text,
    UserProfile? sender,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    // Optimistic local update
    final optimisticMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      activityId: activityId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      sender: sender,
    );

    final currentList = _messagesByActivity.putIfAbsent(activityId, () => []);
    currentList.add(optimisticMsg);
    if (!_isDisposed) notifyListeners();

    try {
      await client.from('messages').insert({
        'activity_id': activityId,
        'sender_id': senderId,
        'text': text,
      });
      // Note: If realtime subscription is active, it will auto-refresh.
      // In case realtime is not connected or delayed, fetch once after slight delay if needed.
      if (!_activeChannels.containsKey(activityId)) {
        await fetchMessagesForActivity(activityId);
      }
    } catch (_) {
      // Revert optimistic message on error
      currentList.remove(optimisticMsg);
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> createExpense({
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
    if (client == null || _isDisposed) return;

    try {
      final expRes = await client
          .from('expenses')
          .insert({
            'activity_id': activityId,
            'creator_id': creatorId,
            'description': description,
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
                      'share_amount': m.amount,
                      'is_paid': m.isPaid,
                    },
                  )
                  .toList(),
            );
      }

      await fetchExpense(expId);

      await sendMessage(
        activityId: activityId,
        senderId: creatorId,
        text: 'EXPENSE:$expId',
        sender: creator,
      );
    } catch (_) {}
  }

  Future<void> toggleMemberPaid(String expenseId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    final exp = _expenses[expenseId];
    if (exp != null) {
      final member = exp.members.where((m) => m.userId == userId).firstOrNull;
      if (member == null) return;
      final nextPaid = !member.isPaid;

      try {
        await client
            .from('expense_shares')
            .update({'is_paid': nextPaid})
            .eq('expense_id', expenseId)
            .eq('user_id', userId);

        await fetchExpense(expenseId);
      } catch (_) {}
    }
  }

  Future<void> createPoll({
    required String activityId,
    required String creatorId,
    required String question,
    required List<String> optionTexts,
    UserProfile? creator,
  }) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      final pollRes = await client
          .from('polls')
          .insert({
            'activity_id': activityId,
            'creator_id': creatorId,
            'question': question,
            'options': optionTexts,
          })
          .select()
          .single();

      final pollId = pollRes['id'] as String;

      await fetchPoll(pollId);

      await sendMessage(
        activityId: activityId,
        senderId: creatorId,
        text: 'POLL:$pollId',
        sender: creator,
      );
    } catch (_) {}
  }

  Future<void> votePoll(String pollId, String optionId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      await client.from('poll_votes').upsert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': userId,
      });

      await fetchPoll(pollId);
    } catch (_) {}
  }

  Future<void> submitRating(RatingItem rating) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    try {
      await client.from('ratings').insert({
        'activity_id': rating.planId,
        'reviewer_id': rating.reviewerId,
        'reviewee_id': rating.revieweeId,
        'stars': rating.rating,
        'tags': rating.badges,
        'comment': rating.comment,
      });

      await client.rpc(
        'recalculate_user_rating',
        params: {'_user_id': rating.revieweeId},
      );

      final idx = _ratings.indexWhere((r) => r.id == rating.id);
      if (idx != -1) {
        _ratings[idx] = rating;
      } else {
        _ratings.add(rating);
      }
      if (!_isDisposed) notifyListeners();
    } catch (_) {}
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

  @override
  void dispose() {
    _isDisposed = true;
    for (final channel in _activeChannels.values) {
      channel.unsubscribe();
    }
    super.dispose();
  }
}
