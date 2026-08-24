import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/expense.dart';
import '../models/poll.dart';
import '../models/rating_item.dart';
import '../models/user_profile.dart';
import 'mock_data.dart';

class ChatState extends ChangeNotifier {
  final List<Message> _messages = MockData.getInitialMessages();
  final List<Expense> _expenses = MockData.getInitialExpenses();
  final List<Poll> _polls = MockData.getInitialPolls();
  final List<RatingItem> _ratings = [];

  List<Message> getMessagesForActivity(String activityId) {
    return _messages.where((m) => m.activityId == activityId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Expense? getExpense(String expenseId) {
    try {
      return _expenses.firstWhere((e) => e.id == expenseId);
    } catch (_) {
      return null;
    }
  }

  Poll? getPoll(String pollId) {
    try {
      return _polls.firstWhere((p) => p.id == pollId);
    } catch (_) {
      return null;
    }
  }

  void sendMessage({
    required String activityId,
    required String senderId,
    required String text,
    UserProfile? sender,
  }) {
    final msg = Message(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      activityId: activityId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      sender: sender,
    );
    _messages.add(msg);
    notifyListeners();
  }

  void createExpense({
    required String activityId,
    required String creatorId,
    required String creatorName,
    required String description,
    required double totalAmount,
    String? upiId,
    required List<ExpenseMember> members,
    UserProfile? creator,
  }) {
    final expId = "exp_${DateTime.now().millisecondsSinceEpoch}";
    final exp = Expense(
      id: expId,
      activityId: activityId,
      creatorId: creatorId,
      creatorName: creatorName,
      description: description,
      totalAmount: totalAmount,
      upiId: upiId,
      members: members,
      createdAt: DateTime.now(),
    );
    _expenses.add(exp);

    // Post special message into chat stream
    sendMessage(
      activityId: activityId,
      senderId: creatorId,
      text: "EXPENSE:$expId",
      sender: creator,
    );
  }

  void toggleMemberPaid(String expenseId, String userId) {
    final idx = _expenses.indexWhere((e) => e.id == expenseId);
    if (idx != -1) {
      final exp = _expenses[idx];
      final nextMembers = exp.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(isPaid: !m.isPaid);
        }
        return m;
      }).toList();

      _expenses[idx] = exp.copyWith(members: nextMembers);
      notifyListeners();
    }
  }

  void createPoll({
    required String activityId,
    required String creatorId,
    required String question,
    required List<String> optionTexts,
    UserProfile? creator,
  }) {
    final pollId = "poll_${DateTime.now().millisecondsSinceEpoch}";
    final options = optionTexts.asMap().entries.map((e) {
      return PollOption(id: "opt_${e.key + 1}", text: e.value);
    }).toList();

    final poll = Poll(
      id: pollId,
      activityId: activityId,
      creatorId: creatorId,
      question: question,
      options: options,
      createdAt: DateTime.now(),
    );
    _polls.add(poll);

    // Post special message into chat stream
    sendMessage(
      activityId: activityId,
      senderId: creatorId,
      text: "POLL:$pollId",
      sender: creator,
    );
  }

  void votePoll(String pollId, String optionId, String userId) {
    final idx = _polls.indexWhere((p) => p.id == pollId);
    if (idx != -1) {
      final poll = _polls[idx];
      final nextOptions = poll.options.map((opt) {
        final voters = List<String>.from(opt.voterIds);
        if (opt.id == optionId) {
          if (!voters.contains(userId)) voters.add(userId);
        } else {
          voters.remove(userId);
        }
        return opt.copyWith(voterIds: voters);
      }).toList();

      _polls[idx] = poll.copyWith(options: nextOptions);
      notifyListeners();
    }
  }

  void submitRating(RatingItem rating) {
    final idx = _ratings.indexWhere(
      (r) =>
          r.planId == rating.planId &&
          r.revieweeId == rating.revieweeId &&
          r.reviewerId == rating.reviewerId,
    );
    if (idx != -1) {
      _ratings[idx] = rating;
    } else {
      _ratings.add(rating);
    }
    notifyListeners();
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
}
