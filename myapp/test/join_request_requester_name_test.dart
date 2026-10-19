import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/state/auth_state.dart';
import 'package:myapp/widgets/activity/manage_requests_modal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Part B: JoinRequest Model Deserialization & Profile Resolution', () {
    test('JoinRequest.fromJson correctly parses nested user Map', () {
      final json = {
        'id': 'req_001',
        'activity_id': 'act_001',
        'user_id': 'user_001',
        'status': 'pending',
        'created_at': '2026-10-18T10:00:00Z',
        'user': {
          'id': 'user_001',
          'full_name': 'Priya Sharma',
          'username': 'priya_s',
          'avatar_url': 'https://example.com/priya.jpg',
        },
      };

      final req = JoinRequest.fromJson(json);

      expect(req.id, equals('req_001'));
      expect(req.activityId, equals('act_001'));
      expect(req.userId, equals('user_001'));
      expect(req.user, isNotNull);
      expect(req.user!.fullName, equals('Priya Sharma'));
      expect(req.user!.username, equals('priya_s'));
      expect(req.user!.avatarUrl, equals('https://example.com/priya.jpg'));
    });

    test(
        'JoinRequest.fromJson handles profiles or profiles_public returned as Map or List',
        () {
      // Test when Supabase joins profiles as a single-element list
      final jsonList = {
        'id': 'req_002',
        'activity_id': 'act_001',
        'user_id': 'user_002',
        'status': 'pending',
        'profiles_public': [
          {
            'id': 'user_002',
            'full_name': 'Karan Singh',
            'username': 'karan_s',
            'avatar_url': null,
          }
        ],
      };

      final req = JoinRequest.fromJson(jsonList);

      expect(req.user, isNotNull);
      expect(req.user!.fullName, equals('Karan Singh'));
      expect(req.user!.username, equals('karan_s'));
    });

    test('JoinRequest handles missing or inaccessible profile gracefully', () {
      final json = {
        'id': 'req_003',
        'activity_id': 'act_001',
        'user_id': 'user_003',
        'status': 'pending',
        'user': null,
      };

      final req = JoinRequest.fromJson(json);

      expect(req.id, equals('req_003'));
      expect(req.userId, equals('user_003'));
      expect(req.user, isNull);
    });
  });

  group('Part B: Display Name & Placeholder Cleanup Resolution', () {
    test(
        'Resolves actual full name when valid, ignoring placeholder Squad Mate or User',
        () {
      // Requester with valid full name
      final prof1 = UserProfile(
        id: 'u1',
        fullName: 'Vikram Malhotra',
        username: 'vikram_m',
      );
      expect(
        ManageRequestsModal.resolveRequesterName(prof1),
        equals('Vikram Malhotra'),
      );

      // Requester with only username (fullName is generic "Squad Mate")
      final prof2 = UserProfile(
        id: 'u2',
        fullName: 'Squad Mate',
        username: 'speedy_runner',
      );
      expect(
        ManageRequestsModal.resolveRequesterName(prof2),
        equals('speedy_runner'),
      );

      // Requester with generic "User" as fullName
      final prof3 = UserProfile(
        id: 'u3',
        fullName: 'User',
        username: 'mumbai_trekker',
      );
      expect(
        ManageRequestsModal.resolveRequesterName(prof3),
        equals('mumbai_trekker'),
      );

      // Requester with empty fullName and only username
      final prof4 = UserProfile(
        id: 'u4',
        fullName: '',
        username: 'nature_lover',
      );
      expect(
        ManageRequestsModal.resolveRequesterName(prof4),
        equals('nature_lover'),
      );

      // Null profile falls back to Unknown user
      expect(
        ManageRequestsModal.resolveRequesterName(null),
        equals('Unknown user'),
      );
    });

    test('Initial avatar letter derived from resolved display name', () {
      final prof1 = UserProfile(
        id: 'u1',
        fullName: 'Aarav Mehta',
        username: 'aarav_m',
      );
      final name1 = ManageRequestsModal.resolveRequesterName(prof1);
      final initial1 = name1.isNotEmpty ? name1[0].toUpperCase() : 'U';
      expect(initial1, equals('A'));

      // When fullName is generic "Squad Mate", username "kavita" provides initial 'K'
      final prof2 = UserProfile(
        id: 'u2',
        fullName: 'Squad Mate',
        username: 'kavita',
      );
      final name2 = ManageRequestsModal.resolveRequesterName(prof2);
      final initial2 = name2.isNotEmpty ? name2[0].toUpperCase() : 'U';
      expect(initial2, equals('K'));
    });
  });

  group('Part B: ActivitiesState Profile Enrichment & Multi-Requester Separation',
      () {
    test(
        'Separate requesters display distinct profiles and host is not confused with requester',
        () {
      // Host profile
      final host = UserProfile(
        id: 'host_99',
        fullName: 'Host Rahul',
        username: 'rahul_host',
      );

      // Activity
      final activity = Activity(
        id: 'act_100',
        title: 'Morning Turf Cricket',
        description: 'Cricket match at Bandra Turf',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Bandra, Mumbai',
        hostId: host.id,
        host: host,
        category: 'Sports',
        totalSlots: 10,
        slotsLeft: 5,
        costPerHead: 0,
      );

      // Requester 1
      final req1 = JoinRequest(
        id: 'req_1',
        activityId: activity.id,
        userId: 'user_1',
        status: JoinStatus.pending,
        requestedAt: DateTime.now(),
        user: UserProfile(
          id: 'user_1',
          fullName: 'Arjun Kapoor',
          username: 'arjun_k',
          avatarUrl: 'https://example.com/arjun.jpg',
        ),
      );

      // Requester 2
      final req2 = JoinRequest(
        id: 'req_2',
        activityId: activity.id,
        userId: 'user_2',
        status: JoinStatus.pending,
        requestedAt: DateTime.now(),
        user: UserProfile(
          id: 'user_2',
          fullName: '',
          username: 'sneha_dancer',
        ),
      );

      // Verify IDs remain distinct
      expect(activity.hostId, isNot(equals(req1.userId)));
      expect(activity.hostId, isNot(equals(req2.userId)));
      expect(req1.userId, isNot(equals(req2.userId)));

      // Verify names resolved independently
      expect(
        ManageRequestsModal.resolveRequesterName(req1.user),
        equals('Arjun Kapoor'),
      );
      expect(
        ManageRequestsModal.resolveRequesterName(req2.user),
        equals('sneha_dancer'),
      );
    });

    test('cacheUserProfile enriches in-memory join requests dynamically',
        () {
      final actState = ActivitiesState();

      final initialReq = JoinRequest(
        id: 'req_dyn',
        activityId: 'act_dyn',
        userId: 'user_dyn',
        status: JoinStatus.pending,
        requestedAt: DateTime.now(),
        user: null, // initially null before enrichment
      );

      actState.setJoinRequestsForTest([initialReq]);

      final beforeFetch = actState.getRequestsForActivity('act_dyn');
      expect(beforeFetch.first.user, isNull);

      // Profile is fetched and cached
      final fetchedProfile = UserProfile(
        id: 'user_dyn',
        fullName: 'Sameer Joshi',
        username: 'sameer_j',
        avatarUrl: 'https://example.com/sameer.jpg',
      );
      actState.cacheUserProfile(fetchedProfile);

      final afterFetch = actState.getRequestsForActivity('act_dyn');
      expect(afterFetch.first.user, isNotNull);
      expect(afterFetch.first.user!.fullName, equals('Sameer Joshi'));
      expect(afterFetch.first.user!.username, equals('sameer_j'));
    });
  });

  group('Part B: ManageRequestsModal Widget Test', () {
    testWidgets('Renders actual requester name and avatar in ManageRequestsModal',
        (tester) async {
      final actState = ActivitiesState();
      final authState = AuthState();

      final host = UserProfile(
        id: 'host_main',
        fullName: 'Captain Vikram',
        username: 'captain_v',
      );

      final activity = Activity(
        id: 'act_test',
        title: 'Board Games Night',
        description: 'Fun strategy games',
        dateTime: DateTime.now().add(const Duration(hours: 4)),
        location: 'Khar, Mumbai',
        hostId: host.id,
        host: host,
        category: 'Social',
        totalSlots: 8,
        slotsLeft: 4,
        costPerHead: 0,
      );

      final requester = UserProfile(
        id: 'requester_42',
        fullName: 'Ananya Deshmukh',
        username: 'ananya_d',
        avatarUrl: null, // Will use initial letter 'A'
      );

      final joinReq = JoinRequest(
        id: 'req_test_42',
        activityId: activity.id,
        userId: requester.id,
        status: JoinStatus.pending,
        requestedAt: DateTime.now(),
        user: requester,
      );

      actState.setJoinRequestsForTest([joinReq]);
      actState.cacheUserProfile(requester);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ActivitiesState>.value(value: actState),
            ChangeNotifierProvider<AuthState>.value(value: authState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ManageRequestsModal(
                activityId: activity.id,
                activityTitle: activity.title,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the requester's actual name appears on screen
      expect(find.text('Ananya Deshmukh'), findsOneWidget);

      // Verify generic "Squad Mate" does NOT appear
      expect(find.text('Squad Mate'), findsNothing);

      // Verify Accept and Decline buttons are present for this request
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });
}
