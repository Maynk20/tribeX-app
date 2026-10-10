import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/utils/date_formatter.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/widgets/chat/message_bubble_widget.dart';

void main() {
  group('1. Timestamp & Timezone Verification Tests', () {
    test('DateFormatter.formatTime converts UTC time to local device time', () {
      // 2026-10-09 14:30:00 UTC
      final utcTime = DateTime.utc(2026, 10, 9, 14, 30);
      final formattedTime = DateFormatter.formatTime(utcTime);

      // Verify that the formatted string matches the local representation of that moment
      final expectedLocalTime = utcTime.toLocal();
      final expectedHour = expectedLocalTime.hour > 12
          ? expectedLocalTime.hour - 12
          : (expectedLocalTime.hour == 0 ? 12 : expectedLocalTime.hour);
      final expectedPeriod = expectedLocalTime.hour >= 12 ? 'PM' : 'AM';
      final expectedMinuteStr = expectedLocalTime.minute.toString().padLeft(
        2,
        '0',
      );

      expect(formattedTime, '$expectedHour:$expectedMinuteStr $expectedPeriod');
    });

    test('DateFormatter.isSameDay handles local vs UTC boundary correctly', () {
      final now = DateTime.now();
      final todayUtc = now.toUtc();
      expect(DateFormatter.isSameDay(now, todayUtc), isTrue);

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.isSameDay(now, yesterday), isFalse);
    });

    test('DateFormatter.formatDateSeparator returns Today, Yesterday or date string', () {
      final now = DateTime.now();
      expect(DateFormatter.formatDateSeparator(now), 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.formatDateSeparator(yesterday), 'Yesterday');

      final olderDate = DateTime(2024, 1, 15, 12, 0);
      expect(DateFormatter.formatDateSeparator(olderDate), contains('2024'));
    });

    test(
      'DateFormatter.parseServerDateTime safely parses ISO, millis, and nulls',
      () {
        const isoStr = '2026-10-09T14:30:00.000Z';
        final parsed = DateFormatter.parseServerDateTime(isoStr);
        expect(parsed.isUtc, isTrue);
        expect(parsed.year, 2026);
        expect(parsed.month, 10);
        expect(parsed.day, 9);
        expect(parsed.hour, 14);

        // Null should not crash
        final parsedNull = DateFormatter.parseServerDateTime(null);
        expect(parsedNull.isUtc, isTrue);

        // Empty string should not crash
        final parsedEmpty = DateFormatter.parseServerDateTime('');
        expect(parsedEmpty.isUtc, isTrue);

        // Millis epoch
        final parsedMillis = DateFormatter.parseServerDateTime(1600000000000);
        expect(parsedMillis.isUtc, isTrue);
      },
    );
  });

  group('2. Message Model & System Events Tests', () {
    test('Message.fromJson parses profiles and created_at correctly', () {
      final json = {
        'id': 'msg-123',
        'activity_id': 'act-456',
        'sender_id': 'user-789',
        'text': 'Hello tribeX squad!',
        'created_at': '2026-10-09T10:00:00Z',
        'profiles_public': {
          'id': 'user-789',
          'full_name': 'Aarav Sharma',
          'username': 'aarav',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.id, 'msg-123');
      expect(msg.activityId, 'act-456');
      expect(msg.senderId, 'user-789');
      expect(msg.text, 'Hello tribeX squad!');
      expect(msg.sender?.fullName, 'Aarav Sharma');
      expect(msg.createdAt.isUtc, isTrue);
      expect(msg.isSystemEvent, isFalse);
    });

    test('Message correctly identifies and formats system events', () {
      final sysMsg1 = Message(
        id: 'sys-1',
        activityId: 'act-1',
        senderId: 'host-1',
        text: 'SYSTEM: Aarav Sharma joined the squad',
        createdAt: DateTime.now().toUtc(),
      );
      expect(sysMsg1.isSystemEvent, isTrue);
      expect(sysMsg1.systemDisplayText, 'Aarav Sharma joined the squad');

      final sysMsg2 = Message(
        id: 'sys-2',
        activityId: 'act-1',
        senderId: 'host-1',
        text: 'EVENT: Host updated the plan details',
        createdAt: DateTime.now().toUtc(),
      );
      expect(sysMsg2.isSystemEvent, isTrue);
      expect(sysMsg2.systemDisplayText, 'Host updated the plan details');
    });

    test('Message correctly extracts expenseId and pollId tokens', () {
      final expMsg = Message(
        id: 'msg-exp',
        activityId: 'act-1',
        senderId: 'u-1',
        text: '[[expense:exp-999]]',
        createdAt: DateTime.now().toUtc(),
      );
      expect(expMsg.expenseId, 'exp-999');
      expect(expMsg.pollId, isNull);

      final pollMsg = Message(
        id: 'msg-poll',
        activityId: 'act-1',
        senderId: 'u-1',
        text: '[[poll:poll-888]]',
        createdAt: DateTime.now().toUtc(),
      );
      expect(pollMsg.pollId, 'poll-888');
      expect(pollMsg.expenseId, isNull);
    });
  });

  group('3. Conversation Architecture: Virtual vs In-Person Plans', () {
    test('Activity distinguishes Virtual and In-Person plans', () {
      final virtualPlan = Activity(
        id: 'virt-1',
        hostId: 'host-1',
        title: 'Virtual Gaming Night',
        description: 'Online Valorant and Among Us session',
        category: 'gaming',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Online',
        totalSlots: 10,
        slotsLeft: 5,
        costPerHead: 0,
        isOnline: true,
        meetingLink: 'https://meet.google.com/xyz-abc-def',
      );

      expect(virtualPlan.isVirtual, isTrue);
      expect(virtualPlan.isOnline, isTrue);
      expect(virtualPlan.meetingLink, isNotNull);

      final inPersonPlan = Activity(
        id: 'inp-1',
        hostId: 'host-1',
        title: 'Turf Football Match',
        description: '5v5 box cricket and football',
        category: 'sports',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Koramangala Sports Arena, Bengaluru',
        totalSlots: 10,
        slotsLeft: 2,
        costPerHead: 250,
        latitude: 12.9352,
        longitude: 77.6245,
        isOnline: false,
      );

      expect(inPersonPlan.isVirtual, isFalse);
      expect(inPersonPlan.isOnline, isFalse);
      expect(inPersonPlan.latitude, 12.9352);
    });
  });

  group('4. Expense System: Deterministic Minor-Unit Arithmetic', () {
    test('Expense.calculateEqualSplit distributes remainders down to exact paisa', () {
      final members = [
        ExpenseMember(userId: 'u1', name: 'User 1', amount: 0),
        ExpenseMember(userId: 'u2', name: 'User 2', amount: 0),
        ExpenseMember(userId: 'u3', name: 'User 3', amount: 0),
      ];

      // ₹100 split among 3:
      // 100.00 * 100 = 10000 paise
      // 10000 ~/ 3 = 3333 paise (₹33.33)
      // 10000 % 3 = 1 remainder paisa
      // Person 1 gets 3334 paise (₹33.34), Person 2 & 3 get 3333 paise (₹33.33)
      // Total sum = 33.34 + 33.33 + 33.33 = 100.00 exactly!
      final split = Expense.calculateEqualSplit(
        participants: members,
        totalAmount: 100.0,
        payerId: 'u1',
      );

      expect(split.length, 3);
      expect(split[0].amount, 33.34);
      expect(split[1].amount, 33.33);
      expect(split[2].amount, 33.33);

      final totalSum = split.fold<double>(0.0, (acc, m) => acc + m.amount);
      expect((totalSum * 100).round(), 10000);

      // Payer is marked as paid
      expect(split[0].isPaid, isTrue);
      expect(split[1].isPaid, isFalse);
      expect(split[2].isPaid, isFalse);
    });
  });

  group('5. Message Ordering & Tie-Breakers', () {
    test('Deterministic sort by createdAt and secondary tie-breaker id', () {
      final t1 = DateTime.utc(2026, 10, 9, 12, 0, 0);
      final t2 = DateTime.utc(2026, 10, 9, 12, 0, 0); // exact same second

      final m1 = Message(
        id: 'msg-b',
        activityId: 'act-1',
        senderId: 'u1',
        text: 'Message B',
        createdAt: t1,
      );

      final m2 = Message(
        id: 'msg-a',
        activityId: 'act-1',
        senderId: 'u2',
        text: 'Message A',
        createdAt: t2,
      );

      final list = [m1, m2];
      list.sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      // Since createdAt matches, 'msg-a' must sort before 'msg-b' deterministically
      expect(list[0].id, 'msg-a');
      expect(list[1].id, 'msg-b');
    });
  });

  group('6. Message Bubble Widget & Consecutive Grouping Tests', () {
    testWidgets('MessageBubbleWidget renders outgoing message cleanly', (
      tester,
    ) async {
      final msg = Message(
        id: 'msg-out',
        activityId: 'act-1',
        senderId: 'me-1',
        text: 'See everyone at 6 PM!',
        createdAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: msg,
              isMine: true,
              showSenderInfo: false,
            ),
          ),
        ),
      );

      expect(find.text('See everyone at 6 PM!'), findsOneWidget);
      expect(
        find.text(DateFormatter.formatTime(msg.createdAt)),
        findsOneWidget,
      );
    });

    testWidgets(
      'MessageBubbleWidget renders incoming message with avatar and name on first in group',
      (tester) async {
        final msg = Message(
          id: 'msg-in',
          activityId: 'act-1',
          senderId: 'user-2',
          text: 'Count me in for the match!',
          createdAt: DateTime.now().toUtc(),
          sender: UserProfile(
            id: 'user-2',
            username: 'rohit',
            fullName: 'Rohit Verma',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubbleWidget(
                message: msg,
                isMine: false,
                showSenderInfo: true,
              ),
            ),
          ),
        );

        expect(find.text('Rohit Verma'), findsOneWidget);
        expect(find.text('Count me in for the match!'), findsOneWidget);
        expect(find.text('RV'), findsOneWidget); // Initials avatar
      },
    );

    testWidgets(
      'MessageBubbleWidget suppresses name and avatar when showSenderInfo is false',
      (tester) async {
        final msg = Message(
          id: 'msg-in-2',
          activityId: 'act-1',
          senderId: 'user-2',
          text: 'And bringing a friend too.',
          createdAt: DateTime.now().toUtc(),
          sender: UserProfile(
            id: 'user-2',
            username: 'rohit',
            fullName: 'Rohit Verma',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubbleWidget(
                message: msg,
                isMine: false,
                showSenderInfo: false,
              ),
            ),
          ),
        );

        // Header name is suppressed to avoid visual repetition
        expect(find.text('Rohit Verma'), findsNothing);
        expect(find.text('And bringing a friend too.'), findsOneWidget);
      },
    );

    testWidgets(
      'MessageBubbleWidget renders system event pill instead of message bubble',
      (tester) async {
        final sysMsg = Message(
          id: 'msg-sys',
          activityId: 'act-1',
          senderId: 'host-1',
          text: 'SYSTEM: Priya joined the squad',
          createdAt: DateTime.now().toUtc(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubbleWidget(
                message: sysMsg,
                isMine: false,
                showSenderInfo: true,
              ),
            ),
          ),
        );

        expect(find.text('Priya joined the squad'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      },
    );
  });
}
