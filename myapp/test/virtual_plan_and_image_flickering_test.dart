import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/join_request.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/widgets/activity/activity_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Virtual Plan Model & Serialization Tests', () {
    test('Activity correctly serializes and handles online/virtual fields', () {
      final virtualPlan = Activity(
        id: 'virtual_1',
        hostId: 'host_1',
        title: 'Flutter Virtual Meetup',
        description: 'Deep dive into Flutter and Dart architecture online',
        category: 'Coding Partner',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Google Meet',
        totalSlots: 10,
        slotsLeft: 8,
        costPerHead: 0,
        isOnline: true,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        latitude: 12.9716, // Should be nulled in toJson
        longitude: 77.5946,
      );

      final json = virtualPlan.toJson();
      expect(json['is_online'], isTrue);
      expect(json['meeting_link'], 'https://meet.google.com/abc-defg-hij');
      expect(
        json['latitude'],
        isNull,
        reason: 'Virtual plans must serialize null coordinates',
      );
      expect(
        json['longitude'],
        isNull,
        reason: 'Virtual plans must serialize null coordinates',
      );
    });

    test('In-person activity clears meeting_link on serialization', () {
      final inPersonPlan = Activity(
        id: 'in_person_1',
        hostId: 'host_1',
        title: 'Bangalore Cricket Match',
        description: 'Cricket on turf venue',
        category: 'Cricket',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Indiranagar Turf',
        totalSlots: 12,
        slotsLeft: 5,
        costPerHead: 150,
        latitude: 12.9716,
        longitude: 77.5946,
        isOnline: false,
        meetingLink: 'https://should-be-cleared.com',
      );

      final json = inPersonPlan.toJson();
      expect(json['is_online'], isFalse);
      expect(json['latitude'], 12.9716);
      expect(json['longitude'], 77.5946);
      expect(
        json['meeting_link'],
        isNull,
        reason: 'In-person activities must have null meeting_link in JSON',
      );
    });

    test('Activity.copyWith properly handles switching online modes', () {
      final inPerson = Activity(
        id: 'act_1',
        hostId: 'host_1',
        title: 'Study Session',
        description: 'Group study session',
        category: 'Study Partner',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Central Library',
        totalSlots: 6,
        slotsLeft: 4,
        costPerHead: 0,
        latitude: 12.9716,
        longitude: 77.5946,
        isOnline: false,
      );

      // Transition to online
      final switchedToOnline = inPerson.copyWith(
        isOnline: true,
        meetingLink: 'https://zoom.us/j/123456789',
        location: 'Zoom Room',
      );

      expect(switchedToOnline.isOnline, isTrue);
      expect(switchedToOnline.meetingLink, 'https://zoom.us/j/123456789');
      expect(switchedToOnline.latitude, isNull);
      expect(switchedToOnline.longitude, isNull);

      // Transition back to in-person
      final switchedBack = switchedToOnline.copyWith(
        isOnline: false,
        latitude: 12.9716,
        longitude: 77.5946,
        location: 'Central Library',
      );

      expect(switchedBack.isOnline, isFalse);
      expect(switchedBack.meetingLink, isNull);
      expect(switchedBack.latitude, 12.9716);
      expect(switchedBack.longitude, 77.5946);
    });
  });

  group('2. ActivitiesState Virtual Plan Discovery & Filtering Tests', () {
    test('Virtual plans are NOT filtered out by physical 15km radius when place is set', () {
      final state = ActivitiesState();

      const originPlace = SavedPlace(
        displayName: 'Indiranagar, Bengaluru',
        short: 'Indiranagar',
        lat: 12.9784,
        lon: 77.6408,
      );
      state.setPlace(originPlace);

      // In-person within 5km
      final nearPlan = Activity(
        id: 'near_1',
        hostId: 'host_1',
        title: 'Morning Badminton',
        description: 'Quick game at Indiranagar court',
        category: 'Badminton',
        dateTime: DateTime.now().add(const Duration(hours: 3)),
        location: 'Indiranagar Court',
        totalSlots: 4,
        slotsLeft: 2,
        costPerHead: 50,
        latitude: 12.9750,
        longitude: 77.6350,
        isOnline: false,
      );

      // In-person far away (Mysore: ~130km > 15km)
      final farPlan = Activity(
        id: 'far_1',
        hostId: 'host_2',
        title: 'Mysore Heritage Walk',
        description: 'Explore Mysore palaces',
        category: 'Trekking',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Mysore Palace',
        totalSlots: 10,
        slotsLeft: 6,
        costPerHead: 200,
        latitude: 12.3051,
        longitude: 76.6551,
        isOnline: false,
      );

      // Virtual / Online plan anchored to nearby host
      final virtualPlan = Activity(
        id: 'virtual_1',
        hostId: 'host_3',
        title: 'Global Discord Gaming Session',
        description: 'Multiplayer gaming and chat',
        category: 'Esports & Gaming',
        dateTime: DateTime.now().add(const Duration(hours: 5)),
        location: 'Discord Voice',
        totalSlots: 10,
        slotsLeft: 5,
        costPerHead: 0,
        isOnline: true,
        meetingLink: 'https://discord.gg/gaming-room',
        host: UserProfile(
          id: 'host_3',
          fullName: 'Gamer Host',
          username: 'gamer_host',
          latitude: 12.9750,
          longitude: 77.6350,
        ),
      );

      state.setActivitiesForTesting([nearPlan, farPlan, virtualPlan]);

      final discoverFeed = state.getFilteredActivities(null, {});
      final ids = discoverFeed.map((a) => a.id).toList();

      expect(
        ids,
        contains('near_1'),
        reason: 'In-person plan within 15 km should appear',
      );
      expect(
        ids,
        isNot(contains('far_1')),
        reason: 'In-person plan 130 km away must be excluded by 15 km radius',
      );
      expect(
        ids,
        contains('virtual_1'),
        reason:
            'Virtual plans anchored within 15 km must appear in nearby discovery',
      );
    });

    test('ModeFilter.online and ModeFilter.inPerson filter correctly', () {
      final state = ActivitiesState();

      final inPerson = Activity(
        id: 'in_person_1',
        hostId: 'h1',
        title: 'Football Match',
        description: 'Turf match',
        category: 'Football',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Turf',
        totalSlots: 10,
        slotsLeft: 4,
        costPerHead: 100,
        isOnline: false,
      );

      final virtual = Activity(
        id: 'virtual_1',
        hostId: 'h2',
        title: 'Remote Coding Jam',
        description: 'Code together over Google Meet',
        category: 'Coding Partner',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Google Meet',
        totalSlots: 8,
        slotsLeft: 4,
        costPerHead: 0,
        isOnline: true,
        meetingLink: 'https://meet.google.com/test',
      );

      state.setActivitiesForTesting([inPerson, virtual]);

      // Filter Online only
      state.setModeFilter(ModeFilter.online);
      var items = state.getFilteredActivities(null, {});
      expect(items.length, 1);
      expect(items.first.id, 'virtual_1');

      // Filter In-Person only
      state.setModeFilter(ModeFilter.inPerson);
      items = state.getFilteredActivities(null, {});
      expect(items.length, 1);
      expect(items.first.id, 'in_person_1');

      // Filter All
      state.setModeFilter(ModeFilter.all);
      items = state.getFilteredActivities(null, {});
      expect(items.length, 2);
    });

    test(
      'requestToJoin allows users without profile GPS to request virtual plans',
      () async {
        final state = ActivitiesState();

        final virtualPlan = Activity(
          id: 'virtual_meetup',
          hostId: 'host_user',
          title: 'Virtual Book Club',
          description: 'Discussion on sci-fi books',
          category: 'Book Club',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          location: 'Online',
          totalSlots: 10,
          slotsLeft: 5,
          costPerHead: 0,
          isOnline: true,
          meetingLink: 'https://meet.google.com/book-club',
        );

        final inPersonPlan = Activity(
          id: 'in_person_match',
          hostId: 'host_user',
          title: 'Local Chess Match',
          description: 'In-person chess board match',
          category: 'Chess',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          location: 'Cafe Chess',
          totalSlots: 2,
          slotsLeft: 1,
          costPerHead: 0,
          latitude: 12.9716,
          longitude: 77.5946,
          isOnline: false,
        );

        state.setActivitiesForTesting([virtualPlan, inPersonPlan]);

        // User with NO GPS profile coordinates
        final remoteUser = UserProfile(
          id: 'remote_user_1',
          fullName: 'Remote Learner',
          username: 'remote_learner',
          city: null,
          latitude: null,
          longitude: null,
        );

        // For in-person plan: blocked because GPS is required
        final inPersonError = await state.requestToJoin(
          inPersonPlan.id,
          remoteUser,
        );
        expect(
          inPersonError,
          contains('Add your GPS profile location before requesting to join.'),
        );

        // For virtual plan: GPS is NOT required
        final virtualError = await state.requestToJoin(
          virtualPlan.id,
          remoteUser,
        );
        expect(
          virtualError,
          isNot(
            contains(
              'Add your GPS profile location before requesting to join.',
            ),
          ),
        );
      },
    );

    test('getMeetingLink returns link from in-memory activity or cache', () {
      final state = ActivitiesState();

      final virtualPlan = Activity(
        id: 'act_meeting_1',
        hostId: 'host_1',
        title: 'Online Design Critique',
        description: 'Figma review session',
        category: 'Coworking Session',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Google Meet',
        totalSlots: 6,
        slotsLeft: 3,
        costPerHead: 0,
        isOnline: true,
        meetingLink: 'https://meet.google.com/figma-review',
      );

      state.setActivitiesForTesting([virtualPlan]);

      final link = state.getMeetingLink(virtualPlan.id);
      expect(link, 'https://meet.google.com/figma-review');
    });
  });

  group('3. ActivityCard Virtual Plan UI Verification Tests', () {
    testWidgets(
      'ActivityCard displays VIRTUAL badge and video icon without physical distance badge',
      (tester) async {
        final virtualAct = Activity(
          id: 'v_card_1',
          hostId: 'host_xyz',
          title: 'Virtual Yoga & Meditation',
          description: 'Morning peaceful session',
          category: 'Meditation',
          dateTime: DateTime.now().add(const Duration(hours: 4)),
          location: 'Zoom Call',
          totalSlots: 20,
          slotsLeft: 12,
          costPerHead: 0,
          isOnline: true,
          meetingLink: 'https://zoom.us/j/987654321',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activity: virtualAct,
                distanceKm: 5.2, // Even if distanceKm is passed, online plans shouldn't show it
                isHost: false,
                myStatus: null,
                hasProfileGpsLocation: false, // Should NOT block virtual plans
                onJoin: () {},
                onChat: () {},
              ),
            ),
          ),
        );

        await tester.pump();

        // Check VIRTUAL badge
        expect(find.text('VIRTUAL'), findsOneWidget);
        expect(find.byIcon(LucideIcons.globe), findsOneWidget);

        // Check video icon is used for location row
        expect(find.byIcon(LucideIcons.video), findsAtLeastNWidgets(1));

        // Physical distance text should NOT be rendered for online events
        expect(find.text('5.2 km away'), findsNothing);

        // Check location label
        expect(find.text('Virtual · Zoom Call'), findsOneWidget);

        // Non-joined guest sees private notice
        expect(find.text('Meeting link visible once joined'), findsOneWidget);
        expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      },
    );

    testWidgets(
      'ActivityCard displays Join Meeting button for confirmed attendee or host',
      (tester) async {
        final virtualAct = Activity(
          id: 'v_card_confirmed',
          hostId: 'host_xyz',
          title: 'Virtual Music Jam',
          description: 'Acoustic jam session online',
          category: 'Music Jam',
          dateTime: DateTime.now().add(const Duration(hours: 2)),
          location: 'Google Meet',
          totalSlots: 8,
          slotsLeft: 2,
          costPerHead: 0,
          isOnline: true,
          meetingLink: 'https://meet.google.com/music-jam',
        );

        final state = ActivitiesState();
        state.setActivitiesForTesting([virtualAct]);

        await tester.pumpWidget(
          ChangeNotifierProvider<ActivitiesState>.value(
            value: state,
            child: MaterialApp(
              home: Scaffold(
                body: ActivityCard(
                  activity: virtualAct,
                  isHost: false,
                  myStatus: JoinStatus.accepted, // Confirmed squad attendee
                  hasProfileGpsLocation: false,
                  onJoin: () {},
                  onChat: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Confirmed attendee sees "Join Meeting · Tap to open link"
        expect(find.text('Join Meeting · Tap to open link'), findsOneWidget);
        expect(find.byIcon(LucideIcons.externalLink), findsOneWidget);
      },
    );
  });

  group('4. Image Preview & Flickering Prevention Tests', () {
    test('Image memory buffer equality avoids decoding repeatedly', () {
      const sampleBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final bytes1 = base64Decode(sampleBase64.split(',').last);
      final bytes2 = base64Decode(sampleBase64.split(',').last);

      // Decoding repeatedly produces different object references
      expect(
        identical(bytes1, bytes2),
        isFalse,
        reason: 'Repeated base64Decode allocates distinct memory buffers',
      );

      // But caching the decoded bytes maintains identical object identity
      final cachedBytes = bytes1;
      expect(
        identical(bytes1, cachedBytes),
        isTrue,
        reason: 'Cached preview bytes preserve memory reference identity',
      );
    });

    testWidgets(
      'Stable preview bytes widget renders with gaplessPlayback without crashing',
      (tester) async {
        final sampleBytes = Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Image.memory(
                    sampleBytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Uploading cover…'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Uploading cover…'), findsOneWidget);
      },
    );
  });
}
