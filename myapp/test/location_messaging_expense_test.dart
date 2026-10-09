import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/expense.dart';
import 'package:myapp/models/message.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/state/activities_state.dart';

void main() {
  group('1. India-Wide Location Search & Boundary Validation', () {
    test('Validates coordinates across Indian States, UTs, and Regions', () {
      final representativeIndiaLocations = <String, ({double lat, double lon})>{
        // South India
        'Bengaluru, Karnataka': (lat: 12.9716, lon: 77.5946),
        'Indiranagar, Bengaluru (560038)': (lat: 12.9784, lon: 77.6408),
        'Chennai, Tamil Nadu': (lat: 13.0827, lon: 80.2707),
        'Kanyakumari, Tamil Nadu (Southern tip)': (lat: 8.0883, lon: 77.5385),
        'Munnar, Kerala (685612)': (lat: 10.0889, lon: 77.0595),
        'Hyderabad, Telangana': (lat: 17.3850, lon: 78.4867),
        'Visakhapatnam, Andhra Pradesh': (lat: 17.6868, lon: 83.2185),

        // West India
        'Mumbai, Maharashtra (400050)': (lat: 19.0760, lon: 72.8777),
        'Pune, Maharashtra': (lat: 18.5204, lon: 73.8567),
        'Ahmedabad, Gujarat (380054)': (lat: 23.0225, lon: 72.5714),
        'Madhapar, Bhuj, Kutch (370020)': (lat: 23.2304, lon: 69.6588),
        'Panaji, Goa': (lat: 15.4909, lon: 73.8278),

        // North India
        'Connaught Place, New Delhi (110001)': (lat: 28.6304, lon: 77.2177),
        'Jaipur, Rajasthan': (lat: 26.9124, lon: 75.7873),
        'Lucknow, Uttar Pradesh': (lat: 26.8467, lon: 80.9462),
        'Chandigarh, Punjab/Haryana': (lat: 30.7333, lon: 76.7794),
        'Shimla, Himachal Pradesh': (lat: 31.1048, lon: 77.1734),
        'Srinagar, Jammu & Kashmir': (lat: 34.0837, lon: 74.7973),
        'Leh, Ladakh (194101)': (lat: 34.1526, lon: 77.5771),
        'Dehradun, Uttarakhand': (lat: 30.3165, lon: 78.0322),

        // East & Central India
        'Kolkata, West Bengal': (lat: 22.5726, lon: 88.3639),
        'Bhopal, Madhya Pradesh': (lat: 23.2599, lon: 77.4126),
        'Patna, Bihar': (lat: 25.6127, lon: 85.1432),
        'Ranchi, Jharkhand': (lat: 23.3441, lon: 85.3096),
        'Bhubaneswar, Odisha': (lat: 20.2961, lon: 85.8245),
        'Raipur, Chhattisgarh': (lat: 21.2514, lon: 81.6296),

        // Northeast India
        'Guwahati / Dispur, Assam': (lat: 26.1445, lon: 91.7362),
        'Shillong / Sohra, Meghalaya (793108)': (lat: 25.5788, lon: 91.8933),
        'Itanagar, Arunachal Pradesh': (lat: 27.0844, lon: 93.6053),
        'Kohima, Nagaland': (lat: 25.6751, lon: 94.1086),
        'Imphal, Manipur': (lat: 24.8170, lon: 93.9368),
        'Aizawl, Mizoram': (lat: 23.7271, lon: 92.7176),
        'Agartala, Tripura': (lat: 23.8315, lon: 91.2868),
        'Gangtok, Sikkim': (lat: 27.3389, lon: 88.6065),

        // Islands & Union Territories
        'Port Blair, Andaman & Nicobar (744101)': (lat: 11.6234, lon: 92.7265),
        'Kavaratti, Lakshadweep': (lat: 10.5669, lon: 72.6420),
        'Puducherry': (lat: 11.9416, lon: 79.8083),
        'Daman, D&NH & D&D': (lat: 20.3974, lon: 72.8328),
      };

      for (final entry in representativeIndiaLocations.entries) {
        final loc = entry.value;
        final isValid = LocationService.isInIndia(
          loc.lat,
          loc.lon,
          countryCode: 'IN',
          country: 'India',
        );
        expect(
          isValid,
          isTrue,
          reason:
              'Expected ${entry.key} (${loc.lat}, ${loc.lon}) to be recognized as India',
        );
      }
    });

    test('Strictly rejects international and overseas locations', () {
      final foreignLocations =
          <String, ({double lat, double lon, String code})>{
            'New York, USA': (lat: 40.7128, lon: -74.0060, code: 'US'),
            'London, UK': (lat: 51.5074, lon: -0.1278, code: 'GB'),
            'Paris, France': (lat: 48.8566, lon: 2.3522, code: 'FR'),
            'Tokyo, Japan': (lat: 35.6762, lon: 139.6503, code: 'JP'),
            'Sydney, Australia': (lat: -33.8688, lon: 151.2093, code: 'AU'),
            'Salem, Massachusetts, USA (name collision with Salem TN)': (
              lat: 42.5195,
              lon: -70.8967,
              code: 'US',
            ),
            'Kochi, Japan (name collision with Kochi Kerala)': (
              lat: 33.5597,
              lon: 133.5311,
              code: 'JP',
            ),
            'Richmond, Virginia, USA': (
              lat: 37.5407,
              lon: -77.4360,
              code: 'US',
            ),
            'Dubai, UAE': (lat: 25.2048, lon: 55.2708, code: 'AE'),
            'Singapore': (lat: 1.3521, lon: 103.8198, code: 'SG'),
          };

      for (final entry in foreignLocations.entries) {
        final loc = entry.value;
        final isValid = LocationService.isInIndia(
          loc.lat,
          loc.lon,
          countryCode: loc.code,
        );
        expect(
          isValid,
          isFalse,
          reason:
              'Expected foreign place ${entry.key} to be rejected from India search',
        );
      }
    });

    test(
      'Indian 6-digit postal code regex correctly detects and extracts PINs',
      () {
        final pinRegex = RegExp(r'\b\d{6}\b');

        expect(pinRegex.firstMatch('560038')?.group(0), equals('560038'));
        expect(
          pinRegex.firstMatch('Indiranagar 560038')?.group(0),
          equals('560038'),
        );
        expect(
          pinRegex.firstMatch('Near 110001 CP Delhi')?.group(0),
          equals('110001'),
        );
        expect(pinRegex.firstMatch('370020 Bhuj')?.group(0), equals('370020'));
        expect(pinRegex.firstMatch('Koramangala')?.group(0), isNull);
        expect(
          pinRegex.firstMatch('12345')?.group(0),
          isNull,
        ); // 5 digit US zip
        expect(
          pinRegex.firstMatch('1234567')?.group(0),
          isNull,
        ); // 7 digit phone prefix
      },
    );
  });

  group('2. 15 KM Default Discovery Radius Preservation', () {
    test('15 km constant is properly configured and defaults correctly', () {
      expect(ActivitiesState.defaultRadiusKm, equals(15.0));
      final state = ActivitiesState();
      expect(state.radiusKm, equals(15.0));
    });

    test(
      'Validates distance boundary points: 5 km, 14.9 km, 15.0 km vs 15.1 km',
      () {
        const centerLat = 12.9716;
        const centerLon = 77.5946;

        // Offsets along meridian (~111 km per degree latitude):
        // 5 km ≈ 0.04505 deg
        // 14.9 km ≈ 0.13423 deg
        // 15.0 km ≈ 0.13514 deg
        // 15.1 km ≈ 0.13604 deg

        final d5 = LocationService.calculateDistance(
          centerLat,
          centerLon,
          centerLat + (5.0 / 111.0),
          centerLon,
        );
        final d14_9 = LocationService.calculateDistance(
          centerLat,
          centerLon,
          centerLat + (14.9 / 111.0),
          centerLon,
        );
        final d15 = LocationService.calculateDistance(
          centerLat,
          centerLon,
          centerLat + (15.0 / 111.0),
          centerLon,
        );
        final d15_1 = LocationService.calculateDistance(
          centerLat,
          centerLon,
          centerLat + (15.1 / 111.0),
          centerLon,
        );

        expect(d5, lessThanOrEqualTo(15.0));
        expect(d14_9, lessThanOrEqualTo(15.0));
        expect(d15, closeTo(15.0, 0.05));
        expect(d15_1, greaterThan(15.0));
      },
    );
  });

  group('3. Messaging Dual-Format Compatibility & State Management', () {
    test(
      'Parses TanStack web format [[expense:<uuid>]] and [[poll:<uuid>]]',
      () {
        final expMsg = Message(
          id: 'm1',
          activityId: 'act1',
          senderId: 'u1',
          text: '[[expense:11111111-2222-3333-4444-555555555555]] Turf rent · ₹1200.00',
          createdAt: DateTime.now(),
        );
        expect(
          expMsg.expenseId,
          equals('11111111-2222-3333-4444-555555555555'),
        );

        final pollMsg = Message(
          id: 'm2',
          activityId: 'act1',
          senderId: 'u1',
          text: '[[poll:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee]] What time should we start?',
          createdAt: DateTime.now(),
        );
        expect(pollMsg.pollId, equals('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'));
      },
    );

    test('Parses legacy Flutter formats EXPENSE:<id> and POLL:<id>', () {
      final expMsg = Message(
        id: 'm1',
        activityId: 'act1',
        senderId: 'u1',
        text: 'EXPENSE:11111111-2222-3333-4444-555555555555',
        createdAt: DateTime.now(),
      );
      expect(expMsg.expenseId, equals('11111111-2222-3333-4444-555555555555'));

      final pollMsg = Message(
        id: 'm2',
        activityId: 'act1',
        senderId: 'u1',
        text: 'POLL:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        createdAt: DateTime.now(),
      );
      expect(pollMsg.pollId, equals('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'));
    });

    test('Plain text messages return null for expenseId and pollId', () {
      final msg = Message(
        id: 'm3',
        activityId: 'act1',
        senderId: 'u1',
        text: 'Hey squad, see you all at 6 PM!',
        createdAt: DateTime.now(),
      );
      expect(msg.expenseId, isNull);
      expect(msg.pollId, isNull);
    });

    test('Message state transitions: sending, failure, and retry preserve message text', () {
      final optimistic = Message(
        id: 'temp_123',
        activityId: 'act1',
        senderId: 'u1',
        text: 'Critical message that must not be lost',
        createdAt: DateTime.now(),
        isSending: true,
        isFailed: false,
      );
      expect(optimistic.isSending, isTrue);
      expect(optimistic.isFailed, isFalse);

      // Backend failed
      final failed = optimistic.copyWith(isSending: false, isFailed: true);
      expect(failed.isSending, isFalse);
      expect(failed.isFailed, isTrue);
      expect(failed.text, equals('Critical message that must not be lost'));

      // User hits Retry
      final retrying = failed.copyWith(isSending: true, isFailed: false);
      expect(retrying.isSending, isTrue);
      expect(retrying.isFailed, isFalse);
      expect(retrying.text, equals('Critical message that must not be lost'));
    });
  });

  group('4. Squad Chat Expense Splitting Math & Remainder Distribution', () {
    test('Splits ₹100.00 equally between 2 members (exact half)', () {
      final members = [
        ExpenseMember(userId: 'u1', name: 'Alice', amount: 0),
        ExpenseMember(userId: 'u2', name: 'Bob', amount: 0),
      ];

      final split = Expense.calculateEqualSplit(
        participants: members,
        totalAmount: 100.0,
        payerId: 'u1',
      );

      expect(split.length, equals(2));
      expect(split[0].amount, equals(50.00));
      expect(split[1].amount, equals(50.00));
      expect(split[0].isPaid, isTrue); // Payer is marked paid
      expect(split[1].isPaid, isFalse);
      final totalSum = split.fold<double>(0, (sum, m) => sum + m.amount);
      expect(totalSum, closeTo(100.0, 0.001));
    });

    test('Splits ₹100.00 equally between 3 members with exact remainder distribution', () {
      final members = [
        ExpenseMember(userId: 'u1', name: 'Alice', amount: 0),
        ExpenseMember(userId: 'u2', name: 'Bob', amount: 0),
        ExpenseMember(userId: 'u3', name: 'Charlie', amount: 0),
      ];

      final split = Expense.calculateEqualSplit(
        participants: members,
        totalAmount: 100.0,
        payerId: 'u1',
      );

      expect(split.length, equals(3));
      // 10000 paise / 3 = 3333 paise (₹33.33) with remainder 1 paisa (₹0.01) assigned to member 1
      expect(split[0].amount, equals(33.34));
      expect(split[1].amount, equals(33.33));
      expect(split[2].amount, equals(33.33));
      final totalSum = split.fold<double>(0, (sum, m) => sum + m.amount);
      expect(totalSum, equals(100.00));
    });

    test('Splits ₹1000.00 equally among 7 members with exact paisa sum', () {
      final members = List.generate(
        7,
        (i) => ExpenseMember(userId: 'u$i', name: 'Member $i', amount: 0),
      );

      final split = Expense.calculateEqualSplit(
        participants: members,
        totalAmount: 1000.0,
        payerId: 'u0',
      );

      expect(split.length, equals(7));
      // 100000 paise / 7 = 14285 paise (142.85) remainder 5 paise -> 5 get 142.86, 2 get 142.85
      for (int i = 0; i < 5; i++) {
        expect(split[i].amount, equals(142.86));
      }
      for (int i = 5; i < 7; i++) {
        expect(split[i].amount, equals(142.85));
      }

      final totalSum = split.fold<double>(0, (sum, m) => sum + m.amount);
      expect(double.parse(totalSum.toStringAsFixed(2)), equals(1000.00));
    });

    test(
      'Splits ₹100.03 equally among 10 members without losing fractional paise',
      () {
        final members = List.generate(
          10,
          (i) => ExpenseMember(userId: 'u$i', name: 'Member $i', amount: 0),
        );

        final split = Expense.calculateEqualSplit(
          participants: members,
          totalAmount: 100.03,
          payerId: 'u0',
        );

        expect(split.length, equals(10));
        // 10003 paise / 10 = 1000 paise (10.00) remainder 3 paise -> 3 get 10.01, 7 get 10.00
        for (int i = 0; i < 3; i++) {
          expect(split[i].amount, equals(10.01));
        }
        for (int i = 3; i < 10; i++) {
          expect(split[i].amount, equals(10.00));
        }

        final totalSum = split.fold<double>(0, (sum, m) => sum + m.amount);
        expect(double.parse(totalSum.toStringAsFixed(2)), equals(100.03));
      },
    );

    test(
      'Handles empty participants or 0.0 amount safely without throwing',
      () {
        final emptySplit = Expense.calculateEqualSplit(
          participants: [],
          totalAmount: 500.0,
        );
        expect(emptySplit, isEmpty);

        final zeroSplit = Expense.calculateEqualSplit(
          participants: [ExpenseMember(userId: 'u1', name: 'Alice', amount: 0)],
          totalAmount: 0.0,
        );
        expect(zeroSplit.first.amount, equals(0.0));
      },
    );
  });
}
