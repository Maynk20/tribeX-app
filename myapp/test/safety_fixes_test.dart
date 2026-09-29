import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/activity.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/poll.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/report_service.dart';
import 'package:myapp/state/activities_state.dart';
import 'package:myapp/widgets/common/place_search_dialog.dart';

/// Focused tests for the safety and RPC fixes.
void main() {
  group('CheckInResult', () {
    test('isSuccess is true only for checked_in status', () {
      const ok = CheckInResult(status: 'checked_in', distanceM: 42.0);
      expect(ok.isSuccess, isTrue);
      expect(ok.isAlready, isFalse);
      expect(ok.isTooFar, isFalse);
      expect(ok.isError, isFalse);
      expect(ok.distanceM, 42.0);
    });

    test('isTooFar is true for too_far status', () {
      const far = CheckInResult(status: 'too_far', distanceM: 312.5);
      expect(far.isTooFar, isTrue);
      expect(far.isSuccess, isFalse);
      expect(far.distanceM, 312.5);
    });

    test('isAlready is true for already status', () {
      const already = CheckInResult(status: 'already', distanceM: 0);
      expect(already.isAlready, isTrue);
      expect(already.isSuccess, isFalse);
    });

    test('isError is true for error status', () {
      const err = CheckInResult(
        status: 'error',
        errorMessage: 'Sign in to check in',
      );
      expect(err.isError, isTrue);
      expect(err.isSuccess, isFalse);
      expect(err.errorMessage, contains('Sign in'));
    });
  });

  group('LocationResult', () {
    test('success factory sets lat/lon and no error', () {
      final ok = LocationResult.success(28.6139, 77.2090);
      expect(ok.isSuccess, isTrue);
      expect(ok.latitude, 28.6139);
      expect(ok.longitude, 77.2090);
      expect(ok.error, isNull);
    });

    test('failure factory sets error and null coordinates', () {
      final err = LocationResult.failure('GPS disabled');
      expect(err.isSuccess, isFalse);
      expect(err.latitude, isNull);
      expect(err.longitude, isNull);
      expect(err.error, 'GPS disabled');
    });
  });

  group('ReportService', () {
    test('submitReport returns false when client is null', () async {
      // SupabaseService.client returns null when not initialized.
      // This verifies the fix: previously it returned true even with null client.
      final result = await ReportService.submitReport(
        reporterId: 'user_123',
        targetType: 'user',
        targetId: 'target_456',
        reason: ReportReason.spam,
      );
      expect(result, isFalse);
    });

    test('ReportReason extensions map properly to db strings', () {
      expect(ReportReason.harassment.dbValue, 'harassment');
      expect(ReportReason.unsafeBehavior.dbValue, 'unsafe_behavior');
      expect(ReportReason.fakeProfile.dbValue, 'fake_profile');
      expect(ReportReason.inappropriateContent.dbValue, 'inappropriate_content');
      expect(ReportReason.spam.dbValue, 'spam');
      expect(ReportReason.other.dbValue, 'other');
    });
  });

  group('Expense & ExpenseMember Schema Compatibility', () {
    test('ExpenseMember parses Supabase columns: amount, status', () {
      final json = {
        'user_id': 'user_1',
        'amount': 250.0,
        'status': 'paid',
        'profiles_public': {'full_name': 'Aarav Patel'},
      };
      final member = ExpenseMember.fromJson(json);
      expect(member.userId, 'user_1');
      expect(member.name, 'Aarav Patel');
      expect(member.amount, 250.0);
      expect(member.isPaid, isTrue);

      final out = member.toJson();
      expect(out['amount'], 250.0);
      expect(out['status'], 'paid');
    });

    test('ExpenseMember parses legacy columns: share_amount, is_paid', () {
      final json = {
        'user_id': 'user_2',
        'share_amount': 150.0,
        'is_paid': false,
      };
      final member = ExpenseMember.fromJson(json);
      expect(member.amount, 150.0);
      expect(member.isPaid, isFalse);
    });

    test('Expense parses created_by from Supabase', () {
      final json = {
        'id': 'exp_1',
        'activity_id': 'act_1',
        'created_by': 'host_123',
        'description': 'Dinner split',
        'total_amount': 500.0,
        'expense_shares': [
          {'user_id': 'user_1', 'amount': 250.0, 'status': 'paid'},
          {'user_id': 'user_2', 'amount': 250.0, 'status': 'pending'},
        ],
      };
      final exp = Expense.fromJson(json);
      expect(exp.id, 'exp_1');
      expect(exp.creatorId, 'host_123');
      expect(exp.totalAmount, 500.0);
      expect(exp.members.length, 2);
      expect(exp.paidCount, 1);
      expect(exp.perHead, 250.0);

      final out = exp.toJson();
      expect(out['created_by'], 'host_123');
    });
  });

  group('Poll Schema Compatibility', () {
    test('Poll parses created_by and poll_votes with option_index', () {
      final json = {
        'id': 'poll_1',
        'activity_id': 'act_1',
        'created_by': 'user_abc',
        'question': 'What time should we meet?',
        'options': ['5:00 PM', '6:00 PM', '7:00 PM'],
        'poll_votes': [
          {'poll_id': 'poll_1', 'user_id': 'u1', 'option_index': 0},
          {'poll_id': 'poll_1', 'user_id': 'u2', 'option_index': 0},
          {'poll_id': 'poll_1', 'user_id': 'u3', 'option_index': 1},
        ],
      };
      final poll = Poll.fromJson(json);
      expect(poll.id, 'poll_1');
      expect(poll.creatorId, 'user_abc');
      expect(poll.options.length, 3);
      expect(poll.options[0].text, '5:00 PM');
      expect(poll.options[0].votes, 2);
      expect(poll.options[1].votes, 1);
      expect(poll.options[2].votes, 0);
      expect(poll.totalVotes, 3);

      final out = poll.toJson();
      expect(out['created_by'], 'user_abc');
    });
  });

  group('PlaceItem & LocationService', () {
    test('PlaceItem correctly holds venue title and coordinates', () {
      const place = PlaceItem(
        title: 'Turf Arena',
        subtitle: 'Indiranagar, Bengaluru',
        lat: 12.9716,
        lon: 77.5946,
      );
      expect(place.title, 'Turf Arena');
      expect(place.subtitle, 'Indiranagar, Bengaluru');
      expect(place.lat, 12.9716);
      expect(place.lon, 77.5946);
    });
  });

  group('Distance Sorting Priority', () {
    test('Activities with coordinates sort ahead of activities without coordinates', () {
      final withCoords = Activity(
        id: '1',
        hostId: 'h1',
        title: 'Football',
        description: 'Match',
        category: 'Sports',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        location: 'Turf A',
        totalSlots: 10,
        slotsLeft: 5,
        costPerHead: 100,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      final withoutCoords = Activity(
        id: '2',
        hostId: 'h2',
        title: 'Board Games',
        description: 'Fun night',
        category: 'Social',
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        location: 'Online',
        totalSlots: 6,
        slotsLeft: 2,
        costPerHead: 0,
        latitude: null,
        longitude: null,
      );

      final list = [withoutCoords, withCoords];
      list.sort((a, b) {
        final aHasCoords = a.latitude != null && a.longitude != null;
        final bHasCoords = b.latitude != null && b.longitude != null;
        if (aHasCoords && !bHasCoords) return -1;
        if (!aHasCoords && bHasCoords) return 1;
        return 0;
      });

      expect(list.first.id, '1');
      expect(list.last.id, '2');
    });
  });
}
