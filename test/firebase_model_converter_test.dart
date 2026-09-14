import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashtocash/models/firestore_date_time_converter.dart';
import 'package:trashtocash/models/user_model_firebase.dart';

void main() {
  group('Firestore DateTime Converter Tests (Step 2)', () {
    test('dateTimeFromJson converts Timestamp correctly', () {
      final now = DateTime(2026, 3, 10, 14, 30);
      final timestamp = Timestamp.fromDate(now);

      final converted = dateTimeFromJson(timestamp);
      expect(converted.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('dateTimeFromJson converts ISO String correctly', () {
      final isoString = '2026-03-10T14:30:00.000';
      final converted = dateTimeFromJson(isoString);
      expect(converted.year, 2026);
      expect(converted.month, 3);
      expect(converted.day, 10);
    });

    test('dateTimeToJson converts DateTime to Timestamp', () {
      final now = DateTime(2026, 3, 10, 14, 30);
      final timestamp = dateTimeToJson(now);
      expect(timestamp, isA<Timestamp>());
      expect(timestamp.toDate().millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });

  group('UserModelFirebase Serialization Tests (Step 2)', () {
    test('UserModelFirebase toMap and fromMap serialization', () {
      final date = DateTime(2026, 3, 10, 12, 0);
      final user = UserModelFirebase(
        uid: 'test_uid_123',
        name: 'Andrea Surya',
        email: 'andrea@example.com',
        createdAt: date,
      );

      final map = user.toMap();
      expect(map['uid'], 'test_uid_123');
      expect(map['name'], 'Andrea Surya');
      expect(map['email'], 'andrea@example.com');
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = UserModelFirebase.fromMap(map);
      expect(deserialized.uid, 'test_uid_123');
      expect(deserialized.name, 'Andrea Surya');
      expect(deserialized.email, 'andrea@example.com');
      expect(deserialized.createdAt.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
    });
  });
}
