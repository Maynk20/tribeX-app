import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/report_service.dart';
import 'package:myapp/state/activities_state.dart';

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
  });
}
