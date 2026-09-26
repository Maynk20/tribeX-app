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
      dynamic res;
      try {
        res = await client
            .from('expenses')
            .select(
              '*, profiles_public(*), expense_shares(*, profiles_public(*))',
            )
            .eq('id', expenseId)
            .maybeSingle();
      } catch (_) {
        res = await client
            .from('expenses')
            .select(
              '*, profiles(*), expense_shares(*, profiles(*))',
            )
            .eq('id', expenseId)
            .maybeSingle();
      }

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
            'created_by': creatorId,
            'description': description,
            'total_amount': totalAmount,
            'upi_id': upiId,
          })
          .select()
          .single();

      final expId = expRes['id'] as String;

      if (members.isNotEmpty) {
        await client.from('expense_shares').insert(
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

      await fetchExpense(expId);

      await sendMessage(
        activityId: activityId,
        senderId: creatorId,
        text: 'EXPENSE:$expId',
        sender: creator,
      );
    } catch (e) {
      debugPrint('createExpense error: $e');
    }
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
            .update({
              'status': nextPaid ? 'paid' : 'pending',
              'paid_at': nextPaid ? DateTime.now().toIso8601String() : null,
            })
            .eq('expense_id', expenseId)
            .eq('user_id', userId);

        await fetchExpense(expenseId);
      } catch (e) {
        debugPrint('toggleMemberPaid error: $e');
      }
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
            'created_by': creatorId,
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
    } catch (e) {
      debugPrint('createPoll error: $e');
    }
  }

  Future<void> votePoll(String pollId, String optionId, String userId) async {
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    final int optionIdx = int.tryParse(optionId) ?? 0;

    try {
      await client.from('poll_votes').upsert(
        {
          'poll_id': pollId,
          'user_id': userId,
          'option_index': optionIdx,
        },
        onConflict: 'poll_id,user_id',
      );

      await fetchPoll(pollId);
    } catch (e) {
      debugPrint('votePoll error: $e');
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
