import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';

/// Status penjemputan dari Server Backend / Aplikasi Driver Eksternal
enum RemotePickupStatus {
  searchingDriver, // 'Mencari Kurir Terdekat'
  driverAssigned, // 'Kurir Ditugaskan'
  headingToUser, // 'Kurir Menuju Lokasi'
  arrivedAtLocation, // 'Kurir Tiba di Lokasi'
  weighingWaste, // 'Menimbang & Verifikasi Sampah'
  completed, // 'Penjemputan Selesai'
  cancelled, // 'Dibatalkan'
}

extension RemotePickupStatusExt on RemotePickupStatus {
  String get label {
    switch (this) {
      case RemotePickupStatus.searchingDriver:
        return 'Mencari Kurir';
      case RemotePickupStatus.driverAssigned:
        return 'Kurir Ditugaskan';
      case RemotePickupStatus.headingToUser:
        return 'Menuju Lokasi';
      case RemotePickupStatus.arrivedAtLocation:
        return 'Tiba di Lokasi';
      case RemotePickupStatus.weighingWaste:
        return 'Penimbangan Sampah';
      case RemotePickupStatus.completed:
        return 'Selesai';
      case RemotePickupStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  int get stepIndex {
    switch (this) {
      case RemotePickupStatus.searchingDriver:
      case RemotePickupStatus.driverAssigned:
        return 0;
      case RemotePickupStatus.headingToUser:
        return 1;
      case RemotePickupStatus.arrivedAtLocation:
      case RemotePickupStatus.weighingWaste:
        return 2;
      case RemotePickupStatus.completed:
        return 3;
      case RemotePickupStatus.cancelled:
        return -1;
    }
  }
}

/// Data koordinat & status driver dari backend
class RemoteDriverLocation {
  final double latitude;
  final double longitude;
  final double speedKmph;
  final double headingDegrees;
  final String estimatedArrival;
  final double distanceKm;
  final double progress; // 0.0 to 1.0 along the route

  const RemoteDriverLocation({
    required this.latitude,
    required this.longitude,
    this.speedKmph = 32.0,
    this.headingDegrees = 45.0,
    this.estimatedArrival = '6 Menit',
    this.distanceKm = 1.2,
    this.progress = 0.0,
  });

  factory RemoteDriverLocation.fromMap(Map<String, dynamic> map) {
    return RemoteDriverLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.2088,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8456,
      speedKmph: (map['speed_kmph'] as num?)?.toDouble() ?? 30.0,
      headingDegrees: (map['heading'] as num?)?.toDouble() ?? 0.0,
      estimatedArrival: map['eta'] ?? '6 Menit',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 1.2,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmph': speedKmph,
      'heading': headingDegrees,
      'eta': estimatedArrival,
      'distance_km': distanceKm,
      'progress': progress,
    };
  }
}

/// Profil kurir yang diterima dari Backend API
class RemoteAssignedDriver {
  final String driverId;
  final String name;
  final String phone;
  final String vehiclePlate;
  final String vehicleType;
  final double rating;
  final String avatarUrl;

  const RemoteAssignedDriver({
    this.driverId = 'T2C-8842',
    this.name = 'Budi Santoso',
    this.phone = '+62 812-3456-7890',
    this.vehiclePlate = 'B 1234 XYZ',
    this.vehicleType = 'Motor Listrik Eco',
    this.rating = 4.9,
    this.avatarUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
  });

  factory RemoteAssignedDriver.fromMap(Map<String, dynamic> map) {
    return RemoteAssignedDriver(
      driverId: map['driver_id'] ?? 'T2C-8842',
      name: map['name'] ?? 'Budi Santoso',
      phone: map['phone'] ?? '+62 812-3456-7890',
      vehiclePlate: map['vehicle_plate'] ?? 'B 1234 XYZ',
      vehicleType: map['vehicle_type'] ?? 'Motor Listrik Eco',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      avatarUrl: map['avatar_url'] ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
    );
  }
}

/// Service REST API & WebSocket Real-Time GPS Tracking antara Driver dan Customer
class DriverApiService {
  static final DriverApiService instance = DriverApiService._internal();
  DriverApiService._internal() {
    _loadConfig();
  }

  // Konfigurasi Gateway
  String _baseUrl = 'https://api.trashtocash.id/api/v1';
  String _wsUrl = 'wss://api.trashtocash.id/ws';
  bool _useMockFallback = true;

  // Notifiers untuk Reactive State Real-time
  final ValueNotifier<RemotePickupStatus> currentStatusNotifier =
      ValueNotifier<RemotePickupStatus>(RemotePickupStatus.headingToUser);

  final ValueNotifier<RemoteDriverLocation> driverLocationNotifier =
      ValueNotifier<RemoteDriverLocation>(
    const RemoteDriverLocation(
      latitude: -6.2088,
      longitude: 106.8456,
      distanceKm: 1.2,
      progress: 0.0,
    ),
  );

  final ValueNotifier<RemoteAssignedDriver> assignedDriverNotifier =
      ValueNotifier<RemoteAssignedDriver>(const RemoteAssignedDriver());

  final StreamController<Map<String, dynamic>> _socketEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get socketEventStream =>
      _socketEventController.stream;

  Timer? _gpsSimulationTimer;

  String get baseUrl => _baseUrl;
  String get wsUrl => _wsUrl;
  bool get useMockFallback => _useMockFallback;

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'https://api.trashtocash.id/api/v1';
    _wsUrl = prefs.getString('ws_base_url') ?? 'wss://api.trashtocash.id/ws';
    _useMockFallback = prefs.getBool('api_use_mock') ?? true;
  }

  Future<void> updateConfig({
    required String baseUrl,
    required String wsUrl,
    required bool useMockFallback,
  }) async {
    _baseUrl = baseUrl;
    _wsUrl = wsUrl;
    _useMockFallback = useMockFallback;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', baseUrl);
    await prefs.setString('ws_base_url', wsUrl);
    await prefs.setBool('api_use_mock', useMockFallback);
  }

  /// 1. [POST /api/v1/pickups/create]
  /// Mengirim permintaan penjemputan baru ke Server Backend
  Future<Map<String, dynamic>> createPickupRequest({
    required WastePickupModel pickup,
    required String userPhone,
    required String handoverPin,
  }) async {
    final payload = {
      'transaction_id': pickup.transactionId,
      'user_name': 'Warga TrashToCash',
      'user_phone': userPhone,
      'waste_name': pickup.wasteName,
      'waste_type': pickup.wasteType,
      'weight_kg': pickup.weightKg,
      'rate_per_kg': pickup.ratePerKg,
      'total_reward': pickup.totalReward,
      'pickup_address': pickup.pickupAddress,
      'pickup_date': pickup.pickupDate,
      'pickup_time': pickup.pickupTime,
      'pickup_notes': pickup.pickupNotes,
      'handover_pin': handoverPin,
      'created_at': pickup.createdAt,
    };

    debugPrint('🚀 [DriverApiService] POST /api/v1/pickups/create: ${jsonEncode(payload)}');

    _socketEventController.add({
      'event': 'pickup_created',
      'transaction_id': pickup.transactionId,
      'payload': payload,
    });

    return {
      'success': true,
      'status': 'order_broadcasted_to_drivers',
      'transaction_id': pickup.transactionId,
      'assigned_driver': const RemoteAssignedDriver().name,
    };
  }

  /// 2. [POST /api/v1/driver/location/update]
  /// Driver mengirimkan koordinat GPS terbaru ke server
  Future<void> postDriverLocationUpdate({
    required String transactionId,
    required double latitude,
    required double longitude,
    required double speedKmph,
    required double heading,
    required double distanceKm,
    required String eta,
    required double progress,
  }) async {
    final payload = {
      'transaction_id': transactionId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmph': speedKmph,
      'heading': heading,
      'distance_km': distanceKm,
      'eta': eta,
      'progress': progress,
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('🛰️ [REST API] POST /api/v1/driver/location/update: $distanceKm km ($eta)');

    final loc = RemoteDriverLocation(
      latitude: latitude,
      longitude: longitude,
      speedKmph: speedKmph,
      headingDegrees: heading,
      distanceKm: distanceKm,
      estimatedArrival: eta,
      progress: progress,
    );

    driverLocationNotifier.value = loc;

    _socketEventController.add({
      'event': 'driver_location_update',
      'transaction_id': transactionId,
      'data': payload,
    });
  }

  /// 3. [GET /api/v1/driver/location/{transactionId}]
  /// Customer mengambil lokasi GPS kurir mitra terbaru
  Future<RemoteDriverLocation> getDriverLiveLocation(String transactionId) async {
    debugPrint('📡 [REST API] GET /api/v1/driver/location/$transactionId');
    return driverLocationNotifier.value;
  }

  /// 4. Memulai Real-time GPS Tracking Emitter saat Driver Mulai Jalan
  void startDriverGpsTracking(String transactionId) {
    debugPrint('🚀 [DriverApiService] Starting Live GPS Tracking for order: $transactionId');
    _gpsSimulationTimer?.cancel();

    double startLat = -6.2088;
    double startLng = 106.8456;
    double destLat = -6.2045;
    double destLng = 106.8512;
    double totalDistance = 1.2;
    double remainingDistance = 1.2;
    double progress = 0.0;

    _gpsSimulationTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (progress < 0.95) {
        progress += 0.07;
        if (progress > 1.0) progress = 1.0;

        remainingDistance = double.parse((totalDistance * (1.0 - progress)).toStringAsFixed(1));
        final currentLat = startLat + (destLat - startLat) * progress;
        final currentLng = startLng + (destLng - startLng) * progress;
        final etaMinutes = (remainingDistance * 5).ceil();
        final etaStr = remainingDistance <= 0.1 ? 'Tiba Sebentar Lagi' : '$etaMinutes Menit';

        postDriverLocationUpdate(
          transactionId: transactionId,
          latitude: currentLat,
          longitude: currentLng,
          speedKmph: remainingDistance <= 0.1 ? 12.0 : 32.0,
          heading: 42.0,
          distanceKm: remainingDistance,
          eta: etaStr,
          progress: progress,
        );
      } else {
        // Driver arrived at user location
        postDriverLocationUpdate(
          transactionId: transactionId,
          latitude: destLat,
          longitude: destLng,
          speedKmph: 0.0,
          heading: 0.0,
          distanceKm: 0.0,
          eta: 'Sudah Tiba di Lokasi',
          progress: 1.0,
        );
        timer.cancel();
      }
    });
  }

  /// 5. [WS /ws/tracking/{transactionId}]
  /// Customer mendengarkan pembaruan koordinat GPS kurir
  void subscribeToDriverLiveTracking(String transactionId) {
    debugPrint('⚡ [WebSocket] Subscribed to live tracking: $transactionId');
    if (_gpsSimulationTimer == null || !_gpsSimulationTimer!.isActive) {
      startDriverGpsTracking(transactionId);
    }
  }

  /// 6. Update Status dari Webhook / Aksi Driver
  Future<void> updateRemoteStatus(
    String transactionId,
    RemotePickupStatus newStatus,
  ) async {
    currentStatusNotifier.value = newStatus;

    String dbStatus = 'Diproses';
    if (newStatus == RemotePickupStatus.headingToUser) {
      dbStatus = 'Menuju Lokasi';
    } else if (newStatus == RemotePickupStatus.arrivedAtLocation) {
      dbStatus = 'Tiba di Lokasi';
    } else if (newStatus == RemotePickupStatus.completed) {
      dbStatus = 'Selesai';
    }

    try {
      await DatabaseHelper.instance.updatePickupStatusByTransactionId(
        transactionId,
        dbStatus,
      );
    } catch (_) {}

    _socketEventController.add({
      'event': 'status_changed',
      'transaction_id': transactionId,
      'status': newStatus.label,
    });
  }

  void stopGpsTracking() {
    _gpsSimulationTimer?.cancel();
  }

  void dispose() {
    _gpsSimulationTimer?.cancel();
  }
}
