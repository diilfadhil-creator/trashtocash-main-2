import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateTimeFromJson(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

Timestamp dateTimeToJson(DateTime value) => Timestamp.fromDate(value);
