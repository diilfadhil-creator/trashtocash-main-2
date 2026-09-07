class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role; // 'customer' or 'driver'
  final String? phone;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? address;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? ewalletType;
  final String? ewalletNumber;
  final String? ewalletAccountHolder;
  final String? preferredPayoutMethod; // 'ewallet' or 'bank'
  final String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'customer',
    this.phone,
    this.vehicleType,
    this.vehiclePlate,
    this.address,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.ewalletType,
    this.ewalletNumber,
    this.ewalletAccountHolder,
    this.preferredPayoutMethod,
    required this.createdAt,
  });

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isCustomer => role.toLowerCase() == 'customer';

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? phone,
    String? vehicleType,
    String? vehiclePlate,
    String? address,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    String? ewalletType,
    String? ewalletNumber,
    String? ewalletAccountHolder,
    String? preferredPayoutMethod,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      address: address ?? this.address,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      ewalletType: ewalletType ?? this.ewalletType,
      ewalletNumber: ewalletNumber ?? this.ewalletNumber,
      ewalletAccountHolder: ewalletAccountHolder ?? this.ewalletAccountHolder,
      preferredPayoutMethod: preferredPayoutMethod ?? this.preferredPayoutMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert UserModel object into a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'address': address,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_holder': bankAccountHolder,
      'ewallet_type': ewalletType,
      'ewallet_number': ewalletNumber,
      'ewallet_account_holder': ewalletAccountHolder,
      'preferred_payout_method': preferredPayoutMethod,
      'created_at': createdAt,
    };
  }

  // Convert Map from SQLite into a UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      phone: map['phone'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      vehiclePlate: map['vehicle_plate'] as String?,
      address: map['address'] as String?,
      bankName: map['bank_name'] as String?,
      bankAccountNumber: map['bank_account_number'] as String?,
      bankAccountHolder: map['bank_account_holder'] as String?,
      ewalletType: map['ewallet_type'] as String?,
      ewalletNumber: map['ewallet_number'] as String?,
      ewalletAccountHolder: map['ewallet_account_holder'] as String?,
      preferredPayoutMethod: map['preferred_payout_method'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
