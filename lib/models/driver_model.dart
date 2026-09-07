import 'package:flutter/material.dart';

enum DriverVehicleType {
  motorcycle, // Sepeda Motor
  electricMotor, // Motor Listrik Eco
  tossaCart, // Tossa Roda Tiga / Gerobak Motor
  pickupBox, // Mobil Bak Terbuka / Pickup
}

extension DriverVehicleTypeExtension on DriverVehicleType {
  String get label {
    switch (this) {
      case DriverVehicleType.motorcycle:
        return 'Motor Bensin (Reguler)';
      case DriverVehicleType.electricMotor:
        return 'Motor Listrik Eco (Ramah Lingkungan)';
      case DriverVehicleType.tossaCart:
        return 'Tossa Roda Tiga (Kapasitas Sedang)';
      case DriverVehicleType.pickupBox:
        return 'Mobil Pickup / GranMax (Kapasitas Besar)';
    }
  }

  IconData get icon {
    switch (this) {
      case DriverVehicleType.motorcycle:
        return Icons.two_wheeler;
      case DriverVehicleType.electricMotor:
        return Icons.electric_moped;
      case DriverVehicleType.tossaCart:
        return Icons.electric_rickshaw;
      case DriverVehicleType.pickupBox:
        return Icons.local_shipping;
    }
  }

  double get maxCapacityKg {
    switch (this) {
      case DriverVehicleType.motorcycle:
        return 35.0;
      case DriverVehicleType.electricMotor:
        return 40.0;
      case DriverVehicleType.tossaCart:
        return 150.0;
      case DriverVehicleType.pickupBox:
        return 600.0;
    }
  }
}

enum DriverOrderStatus {
  pending, // Menunggu Kurir Menerima
  accepted, // Diterima Driver
  headingToUser, // Sedang Menuju Lokasi Warga
  arrivedAtLocation, // Sudah Tiba di Alamat
  weighingAndVerify, // Sedang Menimbang & Cek Sampah
  completed, // Penjemputan Selesai
  cancelled, // Dibatalkan
}

extension DriverOrderStatusExtension on DriverOrderStatus {
  String get label {
    switch (this) {
      case DriverOrderStatus.pending:
        return 'Menunggu Penjemputan';
      case DriverOrderStatus.accepted:
        return 'Kurir Ditugaskan';
      case DriverOrderStatus.headingToUser:
        return 'Menuju Lokasi';
      case DriverOrderStatus.arrivedAtLocation:
        return 'Tiba di Lokasi';
      case DriverOrderStatus.weighingAndVerify:
        return 'Penimbangan Sampah';
      case DriverOrderStatus.completed:
        return 'Selesai';
      case DriverOrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case DriverOrderStatus.pending:
        return Colors.orange;
      case DriverOrderStatus.accepted:
        return Colors.blue;
      case DriverOrderStatus.headingToUser:
        return const Color(0xFF2E7D32);
      case DriverOrderStatus.arrivedAtLocation:
        return const Color(0xFF0D6938);
      case DriverOrderStatus.weighingAndVerify:
        return Colors.purple;
      case DriverOrderStatus.completed:
        return const Color(0xFF0D6938);
      case DriverOrderStatus.cancelled:
        return Colors.red;
    }
  }
}

class DriverProfileModel {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;
  final double rating;
  final int totalReviews;
  final String vehiclePlate;
  final DriverVehicleType vehicleType;
  final bool isOnline;
  final double walletBalance; // IDR
  final int completedPickupsToday;
  final double totalKgToday;
  final double operationalRadiusKm;

  const DriverProfileModel({
    this.id = 'T2C-8842',
    this.name = 'Budi Santoso',
    this.phone = '+62 812-3456-7890',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
    this.rating = 4.9,
    this.totalReviews = 142,
    this.vehiclePlate = 'B 1234 XYZ',
    this.vehicleType = DriverVehicleType.electricMotor,
    this.isOnline = true,
    this.walletBalance = 145000.0,
    this.completedPickupsToday = 6,
    this.totalKgToday = 34.5,
    this.operationalRadiusKm = 5.0,
  });

  DriverProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatarUrl,
    double? rating,
    int? totalReviews,
    String? vehiclePlate,
    DriverVehicleType? vehicleType,
    bool? isOnline,
    double? walletBalance,
    int? completedPickupsToday,
    double? totalKgToday,
    double? operationalRadiusKm,
  }) {
    return DriverProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      isOnline: isOnline ?? this.isOnline,
      walletBalance: walletBalance ?? this.walletBalance,
      completedPickupsToday:
          completedPickupsToday ?? this.completedPickupsToday,
      totalKgToday: totalKgToday ?? this.totalKgToday,
      operationalRadiusKm: operationalRadiusKm ?? this.operationalRadiusKm,
    );
  }
}

class DriverOrderItemModel {
  int? dbId;
  final String transactionId;
  final String userName;
  final String userPhone;
  final String userAddress;
  final double distanceKm;
  final String wasteName;
  final String wasteType; // 'Organik' or 'Non-Organik'
  final double estimatedWeightKg;
  double? actualWeightKg;
  final double ratePerKg;
  final double estimatedReward;
  double? actualReward;
  final double deliveryFee; // Komisi kurir, misal Rp 15.000
  final String pickupDate;
  final String pickupTime;
  final String? pickupNotes;
  final String verificationPin; // e.g. '8842'
  DriverOrderStatus status;
  final String createdAt;
  String? proofPhotoPath;

  DriverOrderItemModel({
    this.dbId,
    required this.transactionId,
    this.userName = 'Warga TrashToCash',
    this.userPhone = '0812-8899-7766',
    required this.userAddress,
    this.distanceKm = 1.4,
    required this.wasteName,
    required this.wasteType,
    required this.estimatedWeightKg,
    this.actualWeightKg,
    required this.ratePerKg,
    required this.estimatedReward,
    this.actualReward,
    this.deliveryFee = 15000.0,
    required this.pickupDate,
    required this.pickupTime,
    this.pickupNotes,
    this.verificationPin = '8842',
    this.status = DriverOrderStatus.pending,
    required this.createdAt,
    this.proofPhotoPath,
  });

  DriverOrderItemModel copyWith({
    int? dbId,
    String? transactionId,
    String? userName,
    String? userPhone,
    String? userAddress,
    double? distanceKm,
    String? wasteName,
    String? wasteType,
    double? estimatedWeightKg,
    double? actualWeightKg,
    double? ratePerKg,
    double? estimatedReward,
    double? actualReward,
    double? deliveryFee,
    String? pickupDate,
    String? pickupTime,
    String? pickupNotes,
    String? verificationPin,
    DriverOrderStatus? status,
    String? createdAt,
    String? proofPhotoPath,
  }) {
    return DriverOrderItemModel(
      dbId: dbId ?? this.dbId,
      transactionId: transactionId ?? this.transactionId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userAddress: userAddress ?? this.userAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      wasteName: wasteName ?? this.wasteName,
      wasteType: wasteType ?? this.wasteType,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      estimatedReward: estimatedReward ?? this.estimatedReward,
      actualReward: actualReward ?? this.actualReward,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      verificationPin: verificationPin ?? this.verificationPin,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      proofPhotoPath: proofPhotoPath ?? this.proofPhotoPath,
    );
  }
}
