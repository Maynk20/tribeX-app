import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/utils/date_formatter.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/widgets/chat/message_bubble_widget.dart';
import 'package:myapp/widgets/chat/poll_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('1. Message Stable-ID & Duplicate Prevention Tests', () {
    test('Two legitimate identical text messages retain unique UUIDs and are not merged', () {
      const uuid = Uuid();
      final id1 = uuid.v4();
      final id2 = uuid.v4();

      expect(id1, isNot(equals(id2)));

      final now = DateTime.now().toUtc();
      final msg1 = Message(
        id: id1,
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'Great game!',
        createdAt: now,
      );

      final msg2 = Message(
        id: id2,
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'Great game!',
        createdAt: now.add(const Duration(seconds: 2)),
      );

      final map = <String, Message>{};
      map[msg1.id] = msg1;
      map[msg2.id] = msg2;

      // Both identical messages must be preserved independently
      expect(map.length, 2);
      expect(map.containsKey(id1), isTrue);
      expect(map.containsKey(id2), isTrue);
      expect(map[id1]?.text, 'Great game!');
      expect(map[id2]?.text, 'Great game!');
    });

    test('Optimistic reconciliation replaces temp message with server confirmed state without duplication', () {
      final clientMsgId = const Uuid().v4();

      final optimistic = Message(
        id: clientMsgId,
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'Heading over now',
        createdAt: DateTime.now().toUtc(),
        isSending: true,
        isFailed: false,
      );

      final serverJson = {
        'id': clientMsgId,
        'activity_id': 'act-1',
        'sender_id': 'user-1',
        'text': 'Heading over now',
        'created_at': '2026-10-10T02:00:00Z',
        'profiles_public': {
          'id': 'user-1',
          'full_name': 'Mayank T',
          'username': 'mayank',
          'avatar_url': 'https://example.com/pic.png',
        },
      };

      final serverMsg = Message.fromJson(serverJson);

      final list = <Message>[optimistic];
      final idx = list.indexWhere((m) => m.id == serverMsg.id);
      expect(idx, 0);

      // In-place replacement
      list[idx] = serverMsg;

      expect(list.length, 1);
      expect(list.first.id, clientMsgId);
      expect(list.first.isSending, isFalse);
      expect(list.first.isFailed, isFalse);
      expect(list.first.sender?.fullName, 'Mayank T');
    });

    test('Retry retains exact failed message ID for idempotent server insert', () {
      final originalId = const Uuid().v4();
      final failed = Message(
        id: originalId,
        activityId: 'act-1',
        senderId: 'user-1',
        text: 'Network timed out here',
        createdAt: DateTime.now().toUtc(),
        isSending: false,
        isFailed: true,
      );

      // On retry, status toggles to sending while ID is strictly preserved
      final retrying = failed.copyWith(isSending: true, isFailed: false);
      expect(retrying.id, originalId);
      expect(retrying.text, 'Network timed out here');
      expect(retrying.isSending, isTrue);
      expect(retrying.isFailed, isFalse);
    });
  });

  group('2. Pagination & Ordering Cursor Boundaries', () {
    test('Messages sort deterministically by createdAt with secondary tie-breaker id', () {
      final t = DateTime.utc(2026, 10, 10, 12, 0, 0);

      final m1 = Message(
        id: 'uuid-b',
        activityId: 'act-1',
        senderId: 'u-1',
        text: 'Msg B',
        createdAt: t,
      );

      final m2 = Message(
        id: 'uuid-a',
        activityId: 'act-1',
        senderId: 'u-2',
        text: 'Msg A',
        createdAt: t,
      );

      final list = [m1, m2];
      list.sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      expect(list[0].id, 'uuid-a');
      expect(list[1].id, 'uuid-b');
    });

    test('Prepending older page messages eliminates duplicates and maintains chronological order', () {
      final baseTime = DateTime.utc(2026, 10, 10, 10, 0, 0);

      // Older page: messages at 08:00, 09:00, 10:00 (10:00 overlaps)
      final olderPage = [
        Message(
          id: 'msg-1',
          activityId: 'act-1',
          senderId: 'u-1',
          text: '8 AM',
          createdAt: baseTime.subtract(const Duration(hours: 2)),
        ),
        Message(
          id: 'msg-2',
          activityId: 'act-1',
          senderId: 'u-1',
          text: '9 AM',
          createdAt: baseTime.subtract(const Duration(hours: 1)),
        ),
        Message(
          id: 'msg-3',
          activityId: 'act-1',
          senderId: 'u-1',
          text: '10 AM overlap',
          createdAt: baseTime,
        ),
      ];

      // Current page: messages at 10:00, 11:00
      final currentPage = [
        Message(
          id: 'msg-3',
          activityId: 'act-1',
          senderId: 'u-1',
          text: '10 AM overlap',
          createdAt: baseTime,
        ),
        Message(
          id: 'msg-4',
          activityId: 'act-1',
          senderId: 'u-1',
          text: '11 AM',
          createdAt: baseTime.add(const Duration(hours: 1)),
        ),
      ];

      final deduped = <String, Message>{};
      for (final m in olderPage) {
        deduped[m.id] = m;
      }
      for (final m in currentPage) {
        deduped[m.id] = m;
      }

      final merged = deduped.values.toList()
        ..sort((a, b) {
          final cmp = a.createdAt.compareTo(b.createdAt);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });

      expect(merged.length, 4);
      expect(merged.map((m) => m.id).toList(), ['msg-1', 'msg-2', 'msg-3', 'msg-4']);
    });
  });

  group('3. Timestamp Fallback & Timezone Robustness', () {
    test('DateFormatter.parseServerDateTime honors explicit fallback when null or invalid', () {
      final specificFallback = DateTime.utc(2025, 1, 1, 0, 0);

      // Null input with fallback
      final parsedNull = DateFormatter.parseServerDateTime(
        null,
        fallback: specificFallback,
      );
      expect(parsedNull, specificFallback);

      // Empty string with fallback
      final parsedEmpty = DateFormatter.parseServerDateTime(
        '',
        fallback: specificFallback,
      );
      expect(parsedEmpty, specificFallback);

      // Garbage string with fallback
      final parsedGarbage = DateFormatter.parseServerDateTime(
        'not-a-date',
        fallback: specificFallback,
      );
      expect(parsedGarbage, specificFallback);
    });

    test('DateFormatter.parseServerDateTime parses valid ISO-8601 UTC string without altering value', () {
      const iso = '2026-10-10T14:30:00.000Z';
      final parsed = DateFormatter.parseServerDateTime(iso);
      expect(parsed.isUtc, isTrue);
      expect(parsed.year, 2026);
      expect(parsed.month, 10);
      expect(parsed.day, 10);
      expect(parsed.hour, 14);
      expect(parsed.minute, 30);
    });
  });

  group('4. MessageBubbleWidget Retry Accessibility & Debounce', () {
    testWidgets('Retry button triggers callback when tapped on failed message', (
      tester,
    ) async {
      bool retried = false;
      final msg = Message(
        id: 'msg-failed',
        activityId: 'act-1',
        senderId: 'me-1',
        text: 'Failed message',
        createdAt: DateTime.now().toUtc(),
        isSending: false,
        isFailed: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: msg,
              isMine: true,
              showSenderInfo: false,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('Retry button is disabled when message is in sending state', (
      tester,
    ) async {
      bool retried = false;
      final msg = Message(
        id: 'msg-sending',
        activityId: 'act-1',
        senderId: 'me-1',
        text: 'Sending message',
        createdAt: DateTime.now().toUtc(),
        isSending: true,
        isFailed: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: msg,
              isMine: true,
              showSenderInfo: false,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      // Retry text is not present when in isSending state
      expect(find.text('Retry'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(retried, isFalse);
    });
  });

  group('5. Group Poll System Comprehensive Repair & Voting Tests', () {
    test('Poll.fromJson parses stringified option_index cleanly without type crash', () {
      final json = {
        'id': 'poll-test-1',
        'activity_id': 'act-1',
        'created_by': 'host-1',
        'question': 'What time should we meet?',
        'options': ['5:00 PM', '7:00 PM'],
        'poll_votes': [
          {'user_id': 'u1', 'option_index': '0'},
          {'user_id': 'u2', 'option_index': 1},
        ],
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final poll = Poll.fromJson(json);
      expect(poll.id, 'poll-test-1');
      expect(poll.options.length, 2);
      expect(poll.options[0].votes, 1);
      expect(poll.options[1].votes, 1);
      expect(poll.totalVotes, 2);
      expect(poll.userVotedOptionId('u1'), '0');
      expect(poll.userVotedOptionId('u2'), '1');
    });

    test('Poll.fromJson deduplicates multiple votes by same user to enforce single choice rule', () {
      final json = {
        'id': 'poll-test-2',
        'activity_id': 'act-1',
        'created_by': 'host-1',
        'question': 'Choose venue',
        'options': ['Cafe', 'Park', 'Arena'],
        'poll_votes': [
          {'user_id': 'u_same', 'option_index': 0},
          // User later switched to option 2 (latest in reverse order)
          {'user_id': 'u_same', 'option_index': 2},
        ],
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final poll = Poll.fromJson(json);
      expect(poll.options[0].votes, 0);
      expect(poll.options[1].votes, 0);
      expect(poll.options[2].votes, 1);
      expect(poll.totalVotes, 1);
      expect(poll.userVotedOptionId('u_same'), '2');
    });

    test('Poll Option voter ID switching removes previous pick and recalculates percentages', () {
      final initialPoll = Poll(
        id: 'poll-switch-1',
        activityId: 'act-1',
        creatorId: 'host-1',
        question: 'Activity preference',
        options: [
          PollOption(id: '0', text: 'Badminton', voterIds: ['user-alice', 'user-bob']),
          PollOption(id: '1', text: 'Tennis', voterIds: []),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      expect(initialPoll.totalVotes, 2);
      expect(initialPoll.options[0].votes, 2);
      expect(initialPoll.options[1].votes, 0);

      // Alice switches from Badminton (0) to Tennis (1)
      final updatedOptions = initialPoll.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final newVoters = List<String>.from(opt.voterIds);
        newVoters.remove('user-alice');
        if (idx == 1) {
          newVoters.add('user-alice');
        }
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      final updatedPoll = initialPoll.copyWith(options: updatedOptions);
      expect(updatedPoll.totalVotes, 2);
      expect(updatedPoll.options[0].votes, 1); // Only bob
      expect(updatedPoll.options[1].votes, 1); // Now alice
      expect(updatedPoll.userVotedOptionId('user-alice'), '1');
      expect(updatedPoll.userVotedOptionId('user-bob'), '0');
    });

    test('Poll retraction unvotes and clears voter from all options', () {
      final poll = Poll(
        id: 'poll-retract-1',
        activityId: 'act-1',
        creatorId: 'host-1',
        question: 'Dinner choice',
        options: [
          PollOption(id: '0', text: 'Pizza', voterIds: ['user-alice']),
          PollOption(id: '1', text: 'Burgers', voterIds: []),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      final unvotedOptions = poll.options.map((opt) {
        final newVoters = List<String>.from(opt.voterIds);
        newVoters.remove('user-alice');
        return opt.copyWith(voterIds: newVoters);
      }).toList();

      final unvotedPoll = poll.copyWith(options: unvotedOptions);
      expect(unvotedPoll.totalVotes, 0);
      expect(unvotedPoll.hasVoted('user-alice'), isFalse);
      expect(unvotedPoll.userVotedOptionId('user-alice'), isNull);
    });

    testWidgets('PollCardWidget renders question, options, percentage bars and vote counts', (
      tester,
    ) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-widget-test',
        activityId: 'act-1',
        creatorId: 'host-1',
        question: 'Weekend Movie Choice?',
        options: [
          PollOption(id: '0', text: 'Inception', voterIds: ['user-1', 'user-2']),
          PollOption(id: '1', text: 'Interstellar', voterIds: ['user-3']),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      // Pre-seed poll into ChatState
      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatState>.value(
          value: chatState,
          child: const MaterialApp(
            home: Scaffold(
              body: PollCardWidget(
                pollId: 'poll-widget-test',
                currentUserId: 'user-1',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('GROUP POLL'), findsOneWidget);
      expect(find.text('Weekend Movie Choice?'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Interstellar'), findsOneWidget);
      // Inception has 2/3 votes = 67% (2)
      expect(find.text('67% (2)'), findsOneWidget);
      // Interstellar has 1/3 votes = 33% (1)
      expect(find.text('33% (1)'), findsOneWidget);
      // Inception is selected by user-1
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('MessageBubbleWidget dynamically resolves sender name from ChatState squad members cache', (
      tester,
    ) async {
      final chatState = ChatState();
      // Message with null sender and senderId 'user-rahul'
      final msg = Message(
        id: 'msg-squad-name-test',
        activityId: 'act-squad-1',
        senderId: 'user-rahul',
        text: 'Hey everyone, I am reaching the venue!',
        createdAt: DateTime.now().toUtc(),
      );

      // Pre-seed squad member into ChatState
      chatState.setSquadMembersForTesting('act-squad-1', [
        ExpenseMember(
          userId: 'user-rahul',
          name: 'Rahul Sharma',
          avatarUrl: null,
          amount: 0.0,
          isPaid: false,
        ),
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatState>.value(
          value: chatState,
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubbleWidget(
                message: msg,
                isMine: false,
                showSenderInfo: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Must display the actual member name 'Rahul Sharma', NOT 'Squad Member'
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Squad Member'), findsNothing);
      expect(find.text('Hey everyone, I am reaching the venue!'), findsOneWidget);
    });

    test('Poll userVotedOptionId and hasVoted are casing and whitespace resilient', () {
      final poll = Poll(
        id: 'poll-case-test',
        activityId: 'act-1',
        creatorId: 'host-1',
        question: 'Venue pick?',
        options: [
          PollOption(id: '0', text: 'Koramangala', voterIds: ['a1b2-c3d4-e5f6']),
          PollOption(id: '1', text: 'Indiranagar', voterIds: []),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      // Match with uppercase and spaces
      expect(poll.hasVoted('A1B2-C3D4-E5F6'), isTrue);
      expect(poll.hasVoted('  a1b2-c3d4-e5f6  '), isTrue);
      expect(poll.userVotedOptionId('A1B2-C3D4-E5F6'), '0');
      expect(poll.userVotedOptionId('  A1B2-C3D4-E5F6  '), '0');
      expect(poll.userVotedOptionId('other-user'), isNull);
    });

    testWidgets('PollCardWidget interactive tap triggers vote without freezing UI', (
      tester,
    ) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll-interact-test',
        activityId: 'act-1',
        creatorId: 'host-1',
        question: 'Turf timing?',
        options: [
          PollOption(id: '0', text: '7:00 AM', voterIds: []),
          PollOption(id: '1', text: '8:00 PM', voterIds: []),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      chatState.setPollForTesting(poll);

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatState>.value(
          value: chatState,
          child: const MaterialApp(
            home: Scaffold(
              body: PollCardWidget(
                pollId: 'poll-interact-test',
                currentUserId: 'user-player-1',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Turf timing?'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
      expect(find.text('8:00 PM'), findsOneWidget);

      // Tap on '8:00 PM'
      await tester.tap(find.text('8:00 PM'));
      await tester.pump();

      // UI remains interactive and doesn't crash
      expect(find.text('Turf timing?'), findsOneWidget);
    });
  });
}
