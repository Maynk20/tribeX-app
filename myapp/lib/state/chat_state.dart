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
      final pendingTemp =
          currentList.where((m) => m.id.startsWith('temp_')).toList();

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
            .select('*, profiles(*), expense_shares(*, profiles(*))')
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
              final pollId = payload.newRecord['id']?.toString() ??
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
              final pollId = payload.newRecord['poll_id']?.toString() ??
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
              final expId = payload.newRecord['id']?.toString() ??
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
              final expId = payload.newRecord['expense_id']?.toString() ??
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
      // Revert optimistic message on error
      currentList.removeWhere((m) => m.id == tempId);
      if (!_isDisposed) notifyListeners();
      return false;
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

      _polls[pollId] = Poll(
        id: currentPoll.id,
        activityId: currentPoll.activityId,
        creatorId: currentPoll.creatorId,
        question: currentPoll.question,
        options: updatedOptions,
        createdAt: currentPoll.createdAt,
      );
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
