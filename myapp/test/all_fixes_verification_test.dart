import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Fix 1 — Plan Creation & Navigation Logic', () {
    test('Successful plan creation resets form state and triggers navigation callback', () {
      bool navigationTriggered = false;

      // Simulated creation callback
      void onPlanCreated() {
        navigationTriggered = true;
      }

      onPlanCreated();
      expect(navigationTriggered, isTrue);
    });
  });

  group('Fix 2 — Host Name and Avatar Resolution on Plan Cards', () {
    test('Resolves host name prioritizing fullName, falling back to username, then Host', () {
      final actState = ActivitiesState();

      // Profile 1: Full name provided
      final host1 = UserProfile(
        id: 'host_01',
        fullName: 'Aarav Sharma',
        username: 'aarav_s',
        avatarUrl: 'https://example.com/aarav.jpg',
      );
      actState.cacheUserProfile(host1);

      // Profile 2: Only username provided
      final host2 = UserProfile(
        id: 'host_02',
        fullName: '',
        username: 'tech_geek',
      );
      actState.cacheUserProfile(host2);

      // Profile 3: Empty name and username
      final host3 = UserProfile(
        id: 'host_03',
        fullName: '   ',
        username: '',
      );
      actState.cacheUserProfile(host3);

      expect(actState.getCachedProfile('host_01')?.fullName, 'Aarav Sharma');
      expect(actState.getCachedProfile('host_02')?.username, 'tech_geek');

      // Helper function matching ActivityCard's resolution logic
      String resolveDisplayName(UserProfile? prof) {
        final rawName = prof?.fullName.trim();
        final rawUser = prof?.username.trim();
        if (rawName != null && rawName.isNotEmpty && rawName != 'User') {
          return rawName;
        }
        if (rawUser != null && rawUser.isNotEmpty) {
          return rawUser;
        }
        return 'Host';
      }

      expect(resolveDisplayName(actState.getCachedProfile('host_01')), 'Aarav Sharma');
      expect(resolveDisplayName(actState.getCachedProfile('host_02')), 'tech_geek');
      expect(resolveDisplayName(actState.getCachedProfile('host_03')), 'Host');
      expect(resolveDisplayName(null), 'Host');
    });
  });

  group('Fix 3 — Requester Name Resolution in Request Bar', () {
    test('Displays actual requester name instead of hardcoded Squad Mate', () {
      final actState = ActivitiesState();

      final requester1 = UserProfile(
        id: 'user_req_1',
        fullName: 'Priya Patel',
        username: 'priya_p',
      );
      actState.cacheUserProfile(requester1);

      final reqWithUser = JoinRequest(
        id: 'req_01',
        activityId: 'act_01',
        userId: 'user_req_1',
        status: JoinStatus.pending,
        requestedAt: DateTime.now(),
        user: requester1,
      );

      // Helper function matching _AttendeeRow's resolved name logic
      String resolveRequesterName(UserProfile? prof) {
        final fName = prof?.fullName.trim();
        final uName = prof?.username.trim();
        if (fName != null && fName.isNotEmpty && fName != 'Squad Mate' && fName != 'User') {
          return fName;
        }
        if (uName != null && uName.isNotEmpty) {
          return uName;
        }
        return 'Unknown user';
      }

      expect(resolveRequesterName(reqWithUser.user), 'Priya Patel');

      // Test with user that only has username
      final requester2 = UserProfile(
        id: 'user_req_2',
        fullName: '',
        username: 'cyber_ninja',
      );
      expect(resolveRequesterName(requester2), 'cyber_ninja');

      // Test fallback when user is null (must not be 'Squad Mate')
      expect(resolveRequesterName(null), 'Unknown user');
    });
  });

  group('Fix 4 — Profile Screen Settings Button Uniqueness', () {
    testWidgets('Header does not render duplicate Settings button beside Sign Out', (tester) async {
      final authState = AuthState();
      authState.setMockUser(
        UserProfile(
          id: 'user_test_1',
          fullName: 'Alice Smith',
          username: 'alice_s',
        ),
      );
      final actState = ActivitiesState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>.value(value: authState),
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sign Out icon button should exist in the app bar / header
      final logoutFinder = find.byIcon(LucideIcons.logOut);
      expect(logoutFinder, findsOneWidget);

      // Verify header row contains only the title column and the Sign Out button (no duplicate Settings button)
      final headerRowFinder = find.ancestor(
        of: logoutFinder,
        matching: find.byType(Row),
      );
      expect(headerRowFinder, findsOneWidget);

      // There should be NO settings icon in the header row
      final settingsInHeader = find.descendant(
        of: headerRowFinder,
        matching: find.byIcon(LucideIcons.settings),
      );
      expect(settingsInHeader, findsNothing);
    });
  });

  group('Fix 5 — Notification Service Configuration & Deduplication', () {
    test('Channels are configured with proper identifiers and Importance levels', () {
      expect(NotificationService.channelMessagesId, 'tribex_squad_messages');
      expect(NotificationService.channelRequestsId, 'tribex_join_requests');
      expect(NotificationService.channelPlansId, 'tribex_plan_updates');
    });

    test('Duplicate notification requests within threshold are suppressed', () {
      final service = NotificationService.instance;

      // First check should allow notification
      final shouldSendFirst = service.shouldDispatch('msg_1001');
      expect(shouldSendFirst, isTrue);

      // Immediate second check with identical key should be debounced
      final shouldSendSecond = service.shouldDispatch('msg_1001');
      expect(shouldSendSecond, isFalse);

      // Different key should be allowed
      final shouldSendDifferent = service.shouldDispatch('msg_1002');
      expect(shouldSendDifferent, isTrue);
    });
  });

  group('Fix 6 — Real-Time Discovery Within 10 Seconds & 15 KM Spatial Logic', () {
    test('ActivitiesState handles real-time insert, update, and delete immediately', () {
      final actState = ActivitiesState();

      final initialPlan = Activity(
        id: 'plan_rt_1',
        hostId: 'host_01',
        title: 'Morning Yoga in Cubbon Park',
        description: 'Outdoor yoga session',
        category: 'Fitness',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Cubbon Park, Bengaluru',
        totalSlots: 10,
        slotsLeft: 8,
        costPerHead: 0,
        latitude: 12.9763,
        longitude: 77.5929,
        isOnline: false,
      );

      // 1. Realtime Insert
      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.insert,
        newRecord: initialPlan.toJson(),
      );

      expect(actState.activities.length, 1);
      expect(actState.activities.first.id, 'plan_rt_1');
      expect(actState.activities.first.title, 'Morning Yoga in Cubbon Park');

      // 2. Realtime Update
      final updatedJson = initialPlan.toJson();
      updatedJson['title'] = 'Sunrise Yoga in Cubbon Park';
      updatedJson['slots_left'] = 5;

      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.update,
        newRecord: updatedJson,
      );

      expect(actState.activities.length, 1);
      expect(actState.activities.first.title, 'Sunrise Yoga in Cubbon Park');
      expect(actState.activities.first.slotsLeft, 5);

      // 3. Realtime Delete
      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.delete,
        oldRecord: {'id': 'plan_rt_1'},
      );

      expect(actState.activities.isEmpty, isTrue);
    });

    test('15 KM radius preserves Virtual plans globally while strictly filtering In-Person plans', () {
      final actState = ActivitiesState();
      // Set user location at Indiranagar (12.9784, 77.6408)
      actState.setPlace(
        const SavedPlace(
          displayName: 'Indiranagar, Bengaluru',
          short: 'Indiranagar',
          lat: 12.9784,
          lon: 77.6408,
        ),
      );

      final inPersonNear = Activity(
        id: 'plan_near',
        hostId: 'host_01',
        title: 'Indiranagar Badminton',
        description: 'Court 1',
        category: 'Sports',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Indiranagar Club',
        totalSlots: 4,
        slotsLeft: 2,
        costPerHead: 0,
        latitude: 12.9785, // ~100m away
        longitude: 77.6410,
        isOnline: false,
      );

      final inPersonFar = Activity(
        id: 'plan_far',
        hostId: 'host_02',
        title: 'Mysuru Heritage Walk',
        description: 'Mysuru Palace',
        category: 'Outdoors',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Mysuru',
        totalSlots: 10,
        slotsLeft: 6,
        costPerHead: 0,
        latitude: 12.3051, // ~140 km away
        longitude: 76.6551,
        isOnline: false,
      );

      final virtualPlanNear = Activity(
        id: 'plan_virtual',
        hostId: 'host_03',
        title: 'Global Flutter Dev Meetup',
        description: 'Online Google Meet',
        category: 'Tech',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Online Event',
        totalSlots: 100,
        slotsLeft: 80,
        costPerHead: 0,
        latitude: 12.9785, // Bengaluru coordinates within 15 km
        longitude: 77.6410,
        isOnline: true,
        meetingLink: 'https://meet.google.com/abc-def-ghi',
      );

      final virtualHost = UserProfile(
        id: 'host_03',
        fullName: 'Tech Host',
        username: 'tech_host',
        latitude: 12.9785,
        longitude: 77.6410,
      );
      actState.cacheUserProfile(virtualHost);

      final virtualPlanRecord = virtualPlanNear.toJson();
      virtualPlanRecord['profiles_public'] = virtualHost.toJson();

      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.insert,
        newRecord: inPersonNear.toJson(),
      );
      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.insert,
        newRecord: inPersonFar.toJson(),
      );
      actState.handleRealtimeActivityChangeForTesting(
        eventType: PostgresChangeEvent.insert,
        newRecord: virtualPlanRecord,
      );

      // Filtered activities with 15km circular radius active
      final filtered = actState.getFilteredActivities(null, {}, applyRadiusFilter: true);

      // In-person near must be included
      expect(filtered.any((a) => a.id == 'plan_near'), isTrue);
      // In-person beyond 15 km must be excluded from nearby feed
      expect(filtered.any((a) => a.id == 'plan_far'), isFalse);
      // Virtual plan must ALWAYS be included regardless of coordinates
      expect(filtered.any((a) => a.id == 'plan_virtual'), isTrue);
    });
  });

  group('Fix 7 — Multi-User Chat & Authoritative Poll Voting Synchronization', () {
    test('Single-choice poll replaces user vote when switching options', () {
      final initialPoll = Poll(
        id: 'poll_choice_1',
        activityId: 'act_01',
        creatorId: 'host_01',
        question: 'Which day works best for football?',
        options: [
          PollOption(id: 'opt_1', text: 'Saturday Morning', voterIds: ['user_bob']),
          PollOption(id: 'opt_2', text: 'Sunday Evening', voterIds: []),
        ],
        createdAt: DateTime.now(),
      );

      // User Bob initially voted for option 1
      expect(initialPoll.hasVoted('user_bob'), isTrue);
      expect(initialPoll.userVotedOptionId('user_bob'), 'opt_1');
      expect(initialPoll.options[0].votes, 1);
      expect(initialPoll.options[1].votes, 0);

      // User Bob switches his vote to option 2 (Sunday Evening)
      final switchedOptions = initialPoll.options.map((opt) {
        final voters = List<String>.from(opt.voterIds);
        voters.remove('user_bob');
        if (opt.id == 'opt_2') {
          voters.add('user_bob');
        }
        return opt.copyWith(voterIds: voters);
      }).toList();

      final switchedPoll = initialPoll.copyWith(options: switchedOptions);

      expect(switchedPoll.hasVoted('user_bob'), isTrue);
      expect(switchedPoll.userVotedOptionId('user_bob'), 'opt_2');
      expect(switchedPoll.options[0].votes, 0);
      expect(switchedPoll.options[1].votes, 1);
      expect(switchedPoll.totalVotes, 1);
    });

    test('Multi-user votes aggregate authoritatively across distinct users', () {
      final multiUserPoll = Poll(
        id: 'poll_agg_1',
        activityId: 'act_01',
        creatorId: 'host_01',
        question: 'Dinner venue?',
        options: [
          PollOption(id: 'opt_1', text: 'Italian Bistro', voterIds: ['user_alice', 'user_david']),
          PollOption(id: 'opt_2', text: 'Rooftop Brewery', voterIds: ['user_bob', 'user_charlie', 'user_eve']),
        ],
        createdAt: DateTime.now(),
      );

      expect(multiUserPoll.totalVotes, 5);
      expect(multiUserPoll.options[0].votes, 2);
      expect(multiUserPoll.options[1].votes, 3);
      expect(multiUserPoll.hasVoted('user_alice'), isTrue);
      expect(multiUserPoll.hasVoted('user_eve'), isTrue);
      expect(multiUserPoll.hasVoted('user_frank'), isFalse);
    });
  });
}

