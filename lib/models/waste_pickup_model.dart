class WastePickupModel {
  final int? id;
  final String transactionId;
  final int? userId;
  final String? userEmail;
  final String wasteName;
  final String wasteType; // 'Organik' or 'Non-Organik'
  final double weightKg;
  final double ratePerKg;
  final double totalReward;
  final String method; // 'Jemput Sampah' or 'Drop-off'
  final String? pickupAddress;
  final String? pickupDate;
  final String? pickupTime;
  final String? pickupNotes;
  final String? dropPointName;
  final String status; // 'Menunggu Penjemputan', 'Diproses', 'Selesai', 'Dibatalkan'
  final String createdAt;

  const WastePickupModel({
    this.id,
    required this.transactionId,
    this.userId,
    this.userEmail,
    required this.wasteName,
    required this.wasteType,
    required this.weightKg,
    required this.ratePerKg,
    required this.totalReward,
    required this.method,
    this.pickupAddress,
    this.pickupDate,
    this.pickupTime,
    this.pickupNotes,
    this.dropPointName,
    this.status = 'Menunggu Penjemputan',
    required this.createdAt,
  });

  // Convert model to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      if (userEmail != null) 'user_email': userEmail,
      'waste_name': wasteName,
      'waste_type': wasteType,
      'weight_kg': weightKg,
      'rate_per_kg': ratePerKg,
      'total_reward': totalReward,
      'method': method,
      'pickup_address': pickupAddress,
      'pickup_date': pickupDate,
      'pickup_time': pickupTime,
      'pickup_notes': pickupNotes,
      'drop_point_name': dropPointName,
      'status': status,
      'created_at': createdAt,
    };
  }

  // Create model from SQLite Map
  factory WastePickupModel.fromMap(Map<String, dynamic> map) {
    return WastePickupModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      userId: map['user_id'] as int?,
      userEmail: map['user_email'] as String?,
      wasteName: map['waste_name'] as String,
      wasteType: map['waste_type'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      ratePerKg: (map['rate_per_kg'] as num).toDouble(),
      totalReward: (map['total_reward'] as num).toDouble(),
      method: map['method'] as String,
      pickupAddress: map['pickup_address'] as String?,
      pickupDate: map['pickup_date'] as String?,
      pickupTime: map['pickup_time'] as String?,
      pickupNotes: map['pickup_notes'] as String?,
      dropPointName: map['drop_point_name'] as String?,
      status: (map['status'] ?? 'Menunggu Penjemputan') as String,
      createdAt: map['created_at'] as String,
    );
  }
}
