import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/widgets/chat/edit_poll_modal.dart';
import 'package:myapp/widgets/chat/poll_card_widget.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Poll Model & Legacy Compatibility Tests', () {
    test('Standard Poll.fromJson correctly parses options, votes, and metadata', () {
      final json = {
        'id': 'poll-uuid-001',
        'activity_id': 'act-uuid-100',
        'created_by': 'user-alice-id',
        'question': 'What time should we meet at the turf?',
        'options': ['5:00 PM', '6:30 PM', '8:00 PM'],
        'poll_votes': [
          {'poll_id': 'poll-uuid-001', 'user_id': 'user-bob', 'option_index': 0},
          {'poll_id': 'poll-uuid-001', 'user_id': 'user-charlie', 'option_index': 1},
        ],
        'created_at': '2026-10-10T12:00:00Z',
      };

      final poll = Poll.fromJson(json);

      expect(poll.id, 'poll-uuid-001');
      expect(poll.activityId, 'act-uuid-100');
      expect(poll.creatorId, 'user-alice-id');
      expect(poll.question, 'What time should we meet at the turf?');
      expect(poll.options.length, 3);
      expect(poll.options[0].text, '5:00 PM');
      expect(poll.options[0].votes, 1);
      expect(poll.options[1].votes, 1);
      expect(poll.options[2].votes, 0);
      expect(poll.totalVotes, 2);
      expect(poll.isClosed, isFalse);
      expect(poll.isDeleted, isFalse);
    });

    test('Legacy compatibility: parses JSON-encoded strings and alternative key names', () {
      final legacyJson = {
        'id': 'legacy-poll-999',
        'activity_id': 'act-legacy',
        'creator_id': 'host-999',
        'question': 'Which cafe for weekend brunch?',
        'options': '["Blue Tokai", "Subko", "Third Wave"]', // encoded string
        'votes': [
          {'user_id': 'user-dave', 'option_index': 0},
        ],
        'closed_at': '2026-10-10T15:00:00Z',
      };

      final poll = Poll.fromJson(legacyJson);

      expect(poll.id, 'legacy-poll-999');
      expect(poll.creatorId, 'host-999');
      expect(poll.options.length, 3);
      expect(poll.options[0].text, 'Blue Tokai');
      expect(poll.options[0].votes, 1);
      expect(poll.isClosed, isTrue);
    });

    test('Single-choice enforcement: retains latest vote and normalizes user IDs', () {
      final json = {
        'id': 'poll-single-choice',
        'activity_id': 'act-1',
        'created_by': 'host-1',
        'question': 'Preferred court?',
        'options': ['Court A', 'Court B'],
        'poll_votes': [
          {'user_id': 'USER_ALICE', 'option_index': 0},
          {'user_id': 'user_alice', 'option_index': 1}, // Alice switched pick to Court B
        ],
      };

      final poll = Poll.fromJson(json);

      expect(poll.totalVotes, 1); // Strictly 1 active vote
      expect(poll.hasVoted('user_alice'), isTrue);
      expect(poll.hasVoted('USER_ALICE'), isTrue);
      expect(poll.userVotedOptionId('user_alice'), '1');
      expect(poll.options[0].votes, 0);
      expect(poll.options[1].votes, 1);
    });

    test('Poll.copyWith allows reopening a closed poll via clearClosedAt', () {
      final closedPoll = Poll(
        id: 'poll-reopen',
        activityId: 'act-1',
        creatorId: 'user-host',
        question: 'Reopen test',
        options: [PollOption(id: '0', text: 'Yes'), PollOption(id: '1', text: 'No')],
        closedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(closedPoll.isClosed, isTrue);

      final reopenedPoll = closedPoll.copyWith(clearClosedAt: true);
      expect(reopenedPoll.isClosed, isFalse);
      expect(reopenedPoll.closedAt, isNull);
    });

    test('Poll helper methods: isCreator and canVote behave accurately', () {
      final poll = Poll(
        id: 'poll-helpers',
        activityId: 'act-1',
        creatorId: 'user_alice',
        question: 'Test',
        options: [PollOption(id: '0', text: 'A'), PollOption(id: '1', text: 'B')],
        createdAt: DateTime.now(),
      );

      expect(poll.isCreator('USER_ALICE'), isTrue);
      expect(poll.isCreator('user-bob'), isFalse);
      expect(poll.canVote('user-bob'), isTrue);
      expect(poll.canVote(null), isFalse);

      final closed = poll.copyWith(closedAt: DateTime.now());
      expect(closed.canVote('user-bob'), isFalse);

      final deleted = poll.copyWith(isDeleted: true);
      expect(deleted.canVote('user-bob'), isFalse);
    });
  });

  group('2. Poll CRUD & State Management Tests', () {
    test('ChatState manages poll caching, creation and fetching', () async {
      final chatState = ChatState();

      final poll = Poll(
        id: 'poll-crud-1',
        activityId: 'act-101',
        creatorId: 'user-me',
        question: 'Dinner place?',
        options: [
          PollOption(id: '0', text: 'Pizza', voterIds: []),
          PollOption(id: '1', text: 'Burgers', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      chatState.setPollForTesting(poll);

      expect(chatState.getPoll('poll-crud-1'), isNotNull);
      expect(chatState.getPoll('poll-crud-1')?.question, 'Dinner place?');
    });

    test('ChatState.updatePoll optimistically modifies question and synchronizes messages', () async {
      final chatState = ChatState();

      final poll = Poll(
        id: 'poll-edit-1',
        activityId: 'act-102',
        creatorId: 'user-me',
        question: 'Old Question',
        options: [
          PollOption(id: '0', text: 'Opt 1', voterIds: []),
          PollOption(id: '1', text: 'Opt 2', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      final ok = await chatState.updatePoll(
        pollId: 'poll-edit-1',
        creatorId: 'user-me',
        question: 'New Updated Question?',
      );
      expect(ok, isTrue);

      // Local update takes effect optimistically
      final updated = chatState.getPoll('poll-edit-1');
      expect(updated?.question, 'New Updated Question?');
    });

    test('ChatState.togglePollClosed closes and reopens poll', () async {
      final chatState = ChatState();

      final poll = Poll(
        id: 'poll-toggle-1',
        activityId: 'act-103',
        creatorId: 'user-me',
        question: 'Status Test',
        options: [
          PollOption(id: '0', text: 'A', voterIds: []),
          PollOption(id: '1', text: 'B', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      // Close poll
      await chatState.togglePollClosed(
        pollId: 'poll-toggle-1',
        creatorId: 'user-me',
        close: true,
      );
      expect(chatState.getPoll('poll-toggle-1')?.isClosed, isTrue);

      // Reopen poll
      await chatState.togglePollClosed(
        pollId: 'poll-toggle-1',
        creatorId: 'user-me',
        close: false,
      );
      expect(chatState.getPoll('poll-toggle-1')?.isClosed, isFalse);
    });

    test('ChatState.deletePoll marks poll as deleted', () async {
      final chatState = ChatState();

      final poll = Poll(
        id: 'poll-del-1',
        activityId: 'act-104',
        creatorId: 'user-me',
        question: 'Delete Test',
        options: [
          PollOption(id: '0', text: 'A', voterIds: []),
          PollOption(id: '1', text: 'B', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      await chatState.deletePoll(
        pollId: 'poll-del-1',
        creatorId: 'user-me',
        activityId: 'act-104',
      );

      expect(chatState.getPoll('poll-del-1')?.isDeleted, isTrue);
    });
  });

  group('3. Voting Engine & Concurrency Tests', () {
    test('Voting for option increments vote and records user selection', () async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-vote-1',
        activityId: 'act-201',
        creatorId: 'user-host',
        question: 'Movie?',
        options: [
          PollOption(id: '0', text: 'Action', voterIds: []),
          PollOption(id: '1', text: 'Comedy', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      final voted = await chatState.votePoll('poll-vote-1', '0', 'user-voter-1');
      expect(voted, isTrue);

      final afterVote = chatState.getPoll('poll-vote-1')!;
      expect(afterVote.totalVotes, 1);
      expect(afterVote.hasVoted('user-voter-1'), isTrue);
      expect(afterVote.userVotedOptionId('user-voter-1'), '0');
      expect(afterVote.options[0].votes, 1);
      expect(afterVote.options[1].votes, 0);
    });

    test('Switching vote changes selection without inflating total votes', () async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-switch-1',
        activityId: 'act-202',
        creatorId: 'user-host',
        question: 'Drink?',
        options: [
          PollOption(id: '0', text: 'Coffee', voterIds: ['user-voter-1']),
          PollOption(id: '1', text: 'Tea', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      // User switches from 0 to 1
      final switched = await chatState.votePoll('poll-switch-1', '1', 'user-voter-1');
      expect(switched, isTrue);

      final afterSwitch = chatState.getPoll('poll-switch-1')!;
      expect(afterSwitch.totalVotes, 1); // Total remains 1
      expect(afterSwitch.userVotedOptionId('user-voter-1'), '1'); // Switched to 1
      expect(afterSwitch.options[0].votes, 0);
      expect(afterSwitch.options[1].votes, 1);
    });

    test('Retracting vote removes selection and reduces count to zero', () async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-retract-1',
        activityId: 'act-203',
        creatorId: 'user-host',
        question: 'Snack?',
        options: [
          PollOption(id: '0', text: 'Nachos', voterIds: ['user-voter-1']),
          PollOption(id: '1', text: 'Fries', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      final retracted = await chatState.retractPollVote('poll-retract-1', 'user-voter-1');
      expect(retracted, isTrue);

      final afterRetract = chatState.getPoll('poll-retract-1')!;
      expect(afterRetract.totalVotes, 0);
      expect(afterRetract.hasVoted('user-voter-1'), isFalse);
      expect(afterRetract.userVotedOptionId('user-voter-1'), isNull);
    });

    test('Voting on closed poll is prevented', () async {
      final chatState = ChatState();
      final closedPoll = Poll(
        id: 'poll-closed-vote',
        activityId: 'act-204',
        creatorId: 'user-host',
        question: 'Closed Poll',
        options: [
          PollOption(id: '0', text: 'A', voterIds: []),
          PollOption(id: '1', text: 'B', voterIds: []),
        ],
        closedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(closedPoll);

      final result = await chatState.votePoll('poll-closed-vote', '0', 'user-voter-1');
      expect(result, isFalse);
      expect(chatState.getPoll('poll-closed-vote')?.totalVotes, 0);
    });
  });

  group('4. UI Widget & Interaction Tests', () {
    testWidgets('PollCardWidget renders options, votes, and highlights user choice', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-widget-1',
        activityId: 'act-301',
        creatorId: 'user-other',
        question: 'Meeting Location?',
        options: [
          PollOption(id: '0', text: 'HQ Mumbai', voterIds: ['user-me']),
          PollOption(id: '1', text: 'BKC Cafe', voterIds: ['user-other', 'user-friend']),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatState>.value(
              value: chatState,
              child: const PollCardWidget(
                pollId: 'poll-widget-1',
                currentUserId: 'user-me',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Meeting Location?'), findsOneWidget);
      expect(find.text('HQ Mumbai'), findsOneWidget);
      expect(find.text('BKC Cafe'), findsOneWidget);
      expect(find.text('33% (1)'), findsOneWidget);
      expect(find.text('67% (2)'), findsOneWidget);
      expect(find.text('3 votes · tap option to vote or switch'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Selected checkmark
    });

    testWidgets('PollCardWidget renders tombstone when poll is marked deleted', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-del-widget',
        activityId: 'act-302',
        creatorId: 'user-host',
        question: 'Will be deleted',
        options: [PollOption(id: '0', text: 'A'), PollOption(id: '1', text: 'B')],
        createdAt: DateTime.now(),
        isDeleted: true,
      );
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatState>.value(
              value: chatState,
              child: const PollCardWidget(
                pollId: 'poll-del-widget',
                currentUserId: 'user-me',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('This poll was removed by the creator'), findsOneWidget);
      expect(find.text('Will be deleted'), findsNothing);
    });

    testWidgets('PollCardWidget displays Closed badge and voting is closed footer when closed', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-closed-widget',
        activityId: 'act-303',
        creatorId: 'user-other',
        question: 'Final Decision',
        options: [
          PollOption(id: '0', text: 'Yes', voterIds: ['user-1']),
          PollOption(id: '1', text: 'No', voterIds: []),
        ],
        closedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatState>.value(
              value: chatState,
              child: const PollCardWidget(
                pollId: 'poll-closed-widget',
                currentUserId: 'user-me',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('1 vote · voting is closed'), findsOneWidget);
    });

    testWidgets('PollCardWidget displays creator management menu for poll creator', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-creator-widget',
        activityId: 'act-304',
        creatorId: 'user-me', // User is creator
        question: 'Host Managed Poll',
        options: [PollOption(id: '0', text: 'A'), PollOption(id: '1', text: 'B')],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatState>.value(
              value: chatState,
              child: const PollCardWidget(
                pollId: 'poll-creator-widget',
                currentUserId: 'user-me',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('EditPollModal renders poll data and allows updating fields', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-modal-test',
        activityId: 'act-305',
        creatorId: 'user-me',
        question: 'Can we change this question?',
        options: [
          PollOption(id: '0', text: 'Choice 1'),
          PollOption(id: '1', text: 'Choice 2'),
        ],
        createdAt: DateTime.now(),
      );
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatState>.value(
              value: chatState,
              child: EditPollModal(
                poll: poll,
                currentUserId: 'user-me',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manage Poll'), findsOneWidget);
      expect(find.text('Poll is Open for Voting'), findsOneWidget);
      expect(find.text('Choice 1'), findsOneWidget);
      expect(find.text('Choice 2'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('5. Chat Integration & Regression Tests', () {
    test('Message model parses standard and legacy poll tokens without corruption', () {
      final stdMsg = Message(
        id: 'msg-std',
        activityId: 'act-1',
        senderId: 'user-1',
        text: '[[poll:poll-uuid-abc]] What game tonight?',
        createdAt: DateTime.now(),
      );
      expect(stdMsg.pollId, 'poll-uuid-abc');
      expect(stdMsg.isSystemEvent, isFalse);

      final legacyMsg = Message(
        id: 'msg-leg',
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'POLL:poll-uuid-xyz Best pizza place',
        createdAt: DateTime.now(),
      );
      expect(legacyMsg.pollId, 'poll-uuid-xyz');
      expect(legacyMsg.isSystemEvent, isFalse);
    });

    test('Regular chat messages, system events, and expenses remain unaffected', () {
      final textMsg = Message(
        id: 'msg-text',
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'Regular chat message',
        createdAt: DateTime.now(),
      );
      expect(textMsg.pollId, isNull);
      expect(textMsg.expenseId, isNull);
      expect(textMsg.isSystemEvent, isFalse);

      final expMsg = Message(
        id: 'msg-exp',
        activityId: 'act-1',
        senderId: 'user-1',
        text: '[[expense:exp-123]] Split turf fee',
        createdAt: DateTime.now(),
      );
      expect(expMsg.expenseId, 'exp-123');
      expect(expMsg.pollId, isNull);

      final sysMsg = Message(
        id: 'msg-sys',
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'SYSTEM: User joined the squad',
        createdAt: DateTime.now(),
      );
      expect(sysMsg.isSystemEvent, isTrue);
      expect(sysMsg.systemDisplayText, 'User joined the squad');
    });
  });
}
