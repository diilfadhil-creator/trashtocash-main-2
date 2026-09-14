import 'firestore_date_time_converter.dart';

class UserModelFirebase {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  UserModelFirebase({
    required this.uid,
    this.name = '',
    this.email = '',
    required this.createdAt,
  });

  factory UserModelFirebase.fromJson(Map<String, dynamic> json) {
    return UserModelFirebase(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']),
    );
  }

  factory UserModelFirebase.fromMap(Map<String, dynamic> map) =>
      UserModelFirebase.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': dateTimeToJson(createdAt),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  UserModelFirebase copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return UserModelFirebase(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
