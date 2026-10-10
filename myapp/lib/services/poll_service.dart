import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/poll.dart';
import 'supabase_service.dart';

class PollService {
  final SupabaseClient? customClient;

  PollService({this.customClient});

  SupabaseClient? get client => customClient ?? SupabaseService.client;

  /// Fetches a poll and all its associated votes by poll ID.
  /// Returns null if the poll doesn't exist or is deleted.
  Future<Poll?> fetchPoll(String pollId) async {
    final c = client;
    if (c == null) return null;

    try {
      final pollRes = await c
          .from('polls')
          .select('*')
          .eq('id', pollId)
          .maybeSingle();

      if (pollRes == null) return null;
      final pollData = Map<String, dynamic>.from(pollRes);

      try {
        final votesRes = await c
            .from('poll_votes')
            .select('*')
            .eq('poll_id', pollId)
            .order('created_at', ascending: true);
        pollData['poll_votes'] = votesRes;
      } catch (e) {
        debugPrint('PollService.fetchPoll votes query warning: $e');
        pollData['poll_votes'] = [];
      }

      return Poll.fromJson(pollData);
    } catch (e) {
      debugPrint('PollService.fetchPoll error: $e');
      return null;
    }
  }

  /// Creates a new poll in the database with durable UUIDv4 idempotency.
  Future<Poll?> createPoll({
    required String activityId,
    required String creatorId,
    required String question,
    required List<String> optionTexts,
    String? clientPollId,
  }) async {
    final c = client;
    if (c == null) return null;

    final trimmedQ = question.trim();
    if (trimmedQ.length < 2) {
      throw ArgumentError('Question must be at least 2 characters long');
    }

    final cleanedOpts = optionTexts
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (cleanedOpts.length < 2) {
      throw ArgumentError('A poll requires at least 2 options');
    }

    final uniqueOpts = <String>{};
    for (final opt in cleanedOpts) {
      if (!uniqueOpts.add(opt.toLowerCase())) {
        throw ArgumentError('Poll options must be unique');
      }
    }

    final pollId = clientPollId ?? const Uuid().v4();
    final verifiedCreatorId = (c.auth.currentUser?.id ?? creatorId).trim().toLowerCase();

    try {
      final inserted = await c.from('polls').insert({
        'id': pollId,
        'activity_id': activityId,
        'created_by': verifiedCreatorId,
        'question': trimmedQ,
        'options': cleanedOpts,
      }).select().maybeSingle();

      if (inserted == null) {
        // Even if select fails due to RLS, build the Poll model locally
        return Poll(
          id: pollId,
          activityId: activityId,
          creatorId: verifiedCreatorId,
          question: trimmedQ,
          options: cleanedOpts
              .asMap()
              .entries
              .map((e) => PollOption(id: e.key.toString(), text: e.value, voterIds: const []))
              .toList(),
          createdAt: DateTime.now().toUtc(),
        );
      }

      return Poll.fromJson(Map<String, dynamic>.from(inserted));
    } catch (e) {
      debugPrint('PollService.createPoll error: $e');
      rethrow;
    }
  }

  /// Updates an existing poll question and optionally options if no votes exist.
  Future<bool> updatePoll({
    required String pollId,
    required String creatorId,
    required String question,
    List<String>? optionTexts,
  }) async {
    final c = client;
    if (c == null) return false;

    final trimmedQ = question.trim();
    if (trimmedQ.isEmpty) return false;

    final verifiedCreatorId = (c.auth.currentUser?.id ?? creatorId).trim().toLowerCase();

    final updatePayload = <String, dynamic>{
      'question': trimmedQ,
    };

    if (optionTexts != null && optionTexts.length >= 2) {
      final cleanedOpts = optionTexts
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      if (cleanedOpts.length >= 2) {
        updatePayload['options'] = cleanedOpts;
      }
    }

    try {
      await c
          .from('polls')
          .update(updatePayload)
          .eq('id', pollId)
          .eq('created_by', verifiedCreatorId);
      return true;
    } catch (e) {
      debugPrint('PollService.updatePoll error: $e');
      return false;
    }
  }

  /// Closes or reopens an existing poll.
  Future<bool> togglePollClosed({
    required String pollId,
    required String creatorId,
    required bool close,
  }) async {
    final c = client;
    if (c == null) return false;

    final verifiedCreatorId = (c.auth.currentUser?.id ?? creatorId).trim().toLowerCase();

    try {
      await c
          .from('polls')
          .update({
            'closed_at': close ? DateTime.now().toUtc().toIso8601String() : null,
          })
          .eq('id', pollId)
          .eq('created_by', verifiedCreatorId);
      return true;
    } catch (e) {
      debugPrint('PollService.togglePollClosed error: $e');
      return false;
    }
  }

  /// Deletes an existing poll and cascades delete to its votes.
  Future<bool> deletePoll({
    required String pollId,
    required String creatorId,
  }) async {
    final c = client;
    if (c == null) return false;

    final verifiedCreatorId = (c.auth.currentUser?.id ?? creatorId).trim().toLowerCase();

    try {
      await c
          .from('polls')
          .delete()
          .eq('id', pollId)
          .eq('created_by', verifiedCreatorId);
      return true;
    } catch (e) {
      debugPrint('PollService.deletePoll error: $e');
      return false;
    }
  }

  /// Records or switches a vote on a poll option.
  /// Enforces single-choice constraint at the database level.
  Future<bool> votePoll({
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    final c = client;
    if (c == null) return false;

    final verifiedUserId = (c.auth.currentUser?.id ?? userId).trim().toLowerCase();
    if (verifiedUserId.isEmpty) return false;

    try {
      // Primary: atomic upsert on unique constraint (poll_id, user_id)
      try {
        await c.from('poll_votes').upsert({
          'poll_id': pollId,
          'user_id': verifiedUserId,
          'option_index': optionIndex,
        }, onConflict: 'poll_id,user_id');
      } catch (upsertErr) {
        debugPrint('PollService.votePoll upsert fallback: $upsertErr');
        // Fallback: delete previous row(s) then insert new vote
        await c
            .from('poll_votes')
            .delete()
            .eq('poll_id', pollId)
            .eq('user_id', verifiedUserId);

        await c.from('poll_votes').insert({
          'poll_id': pollId,
          'user_id': verifiedUserId,
          'option_index': optionIndex,
        });
      }
      return true;
    } catch (e) {
      debugPrint('PollService.votePoll error: $e');
      return false;
    }
  }

  /// Retracts/withdraws a previously cast vote.
  Future<bool> retractVote({
    required String pollId,
    required String userId,
  }) async {
    final c = client;
    if (c == null) return false;

    final verifiedUserId = (c.auth.currentUser?.id ?? userId).trim().toLowerCase();
    if (verifiedUserId.isEmpty) return false;

    try {
      await c
          .from('poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', verifiedUserId);
      return true;
    } catch (e) {
      debugPrint('PollService.retractVote error: $e');
      return false;
    }
  }
}
