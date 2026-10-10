import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/state/chat_state.dart';
import 'package:myapp/widgets/chat/poll_card_widget.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Poll System Regression Tests', () {
    test('Poll model normalizes voter user IDs and enforces single choice', () {
      final pollJson = {
        'id': 'poll_101',
        'activity_id': 'act_101',
        'created_by': 'User_Creator_UUID',
        'question': 'Which location for weekend meetup?',
        'options': ['Bandra', 'Juhu', 'Colaba'],
        'poll_votes': [
          {'poll_id': 'poll_101', 'user_id': 'USER_ALICE', 'option_index': 0},
          {'poll_id': 'poll_101', 'user_id': 'user_alice', 'option_index': 1}, // Latest vote by Alice
          {'poll_id': 'poll_101', 'user_id': 'USER_BOB', 'option_index': 0},
        ],
      };

      final poll = Poll.fromJson(pollJson);

      expect(poll.id, 'poll_101');
      expect(poll.totalVotes, 2); // 1 vote from Alice + 1 vote from Bob
      expect(poll.hasVoted('user_alice'), isTrue);
      expect(poll.hasVoted('USER_ALICE'), isTrue);
      expect(poll.userVotedOptionId('USER_ALICE'), '1'); // Alice's latest pick is option index 1 (Juhu)
      expect(poll.options[0].votes, 1); // Bob on Bandra
      expect(poll.options[1].votes, 1); // Alice on Juhu
      expect(poll.options[2].votes, 0); // Colaba
    });

    test('ChatState retractPollVote removes vote and updates percentages', () async {
      final chatState = ChatState();
      final initialPoll = Poll(
        id: 'poll_202',
        activityId: 'act_202',
        creatorId: 'user_host',
        question: 'Dinner choice?',
        options: [
          PollOption(id: '0', text: 'Pizza', voterIds: ['user_me', 'user_other']),
          PollOption(id: '1', text: 'Sushi', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      chatState.setPollForTesting(initialPoll);

      expect(chatState.getPoll('poll_202')?.totalVotes, 2);
      expect(chatState.getPoll('poll_202')?.userVotedOptionId('USER_ME'), '0');

      // Local retraction simulation
      final success = await chatState.retractPollVote('poll_202', 'USER_ME');
      expect(success, isTrue);

      final updatedPoll = chatState.getPoll('poll_202')!;
      expect(updatedPoll.userVotedOptionId('USER_ME'), isNull);
      expect(updatedPoll.options[0].votes, 1); // Only user_other remains
      expect(updatedPoll.totalVotes, 1);
    });

    testWidgets('PollCardWidget allows tapping selected option to retract vote', (tester) async {
      final chatState = ChatState();
      final poll = Poll(
        id: 'poll_303',
        activityId: 'act_303',
        creatorId: 'user_host',
        question: 'Best time?',
        options: [
          PollOption(id: '0', text: '5 PM', voterIds: ['user_test']),
          PollOption(id: '1', text: '7 PM', voterIds: []),
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
                pollId: 'poll_303',
                currentUserId: 'user_test',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('5 PM'), findsOneWidget);
      expect(find.text('100% (1)'), findsOneWidget);

      // Tap on option 0 ('5 PM'), which is currently selected by user_test
      await tester.tap(find.text('5 PM'));
      await tester.pump();

      // State should update optimistically to retract user_test's vote
      final afterTapPoll = chatState.getPoll('poll_303')!;
      expect(afterTapPoll.hasVoted('user_test'), isFalse);
      expect(afterTapPoll.totalVotes, 0);
    });
  });
}
