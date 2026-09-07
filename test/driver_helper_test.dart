import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/chat_sync_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/models/user_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';
import 'package:trashtocash/services/driver_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DriverHelper & DriverModel Tests', () {
    test('Driver profile default values and copyWith test', () {
      const profile = DriverProfileModel(
        id: 'T2C-8842',
        name: 'Budi Santoso',
        walletBalance: 145000.0,
      );

      expect(profile.name, 'Budi Santoso');
      expect(profile.walletBalance, 145000.0);

      final updated = profile.copyWith(
        walletBalance: 160000.0,
        completedPickupsToday: 7,
      );

      expect(updated.walletBalance, 160000.0);
      expect(updated.completedPickupsToday, 7);
      expect(updated.name, 'Budi Santoso');
    });

    test('DriverOrderItemModel lifecycle status test', () {
      final order = DriverOrderItemModel(
        transactionId: 'TRX-TEST-001',
        userAddress: 'Jl. Melati Blok C2 No. 15',
        wasteName: 'Plastik PET',
        wasteType: 'Non-Organik',
        estimatedWeightKg: 4.0,
        ratePerKg: 10.0,
        estimatedReward: 40.0,
        deliveryFee: 15000.0,
        pickupDate: 'Hari Ini',
        pickupTime: '14:00',
        verificationPin: '8842',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(order.status, DriverOrderStatus.pending);
      expect(order.deliveryFee, 15000.0);
      expect(order.verificationPin, '8842');

      final accepted = order.copyWith(status: DriverOrderStatus.accepted);
      expect(accepted.status, DriverOrderStatus.accepted);

      final heading = order.copyWith(status: DriverOrderStatus.headingToUser);
      expect(heading.status.label, 'Menuju Lokasi');

      final arrived = order.copyWith(status: DriverOrderStatus.arrivedAtLocation);
      expect(arrived.status.label, 'Tiba di Lokasi');
    });

    test('DriverHelper notifyNewPickupOrder adds order to radar', () {
      final pickup = WastePickupModel(
        transactionId: 'TRX-RADAR-111',
        wasteName: 'Kardus & Kertas',
        wasteType: 'Non-Organik',
        weightKg: 5.0,
        ratePerKg: 8.0,
        totalReward: 40.0,
        method: 'Jemput Sampah',
        pickupAddress: 'Jl. Anggrek No. 10',
        createdAt: DateTime.now().toIso8601String(),
      );

      final initialCount = DriverHelper.instance.availableOrdersNotifier.value.length;
      DriverHelper.instance.notifyNewPickupOrder(pickup);

      final newCount = DriverHelper.instance.availableOrdersNotifier.value.length;
      expect(newCount, initialCount + 1);

      final latest = DriverHelper.instance.availableOrdersNotifier.value.first;
      expect(latest.transactionId, 'TRX-RADAR-111');
      expect(latest.wasteName, 'Kardus & Kertas');
    });

    test('ChatSyncHelper bidirectional messaging bus test', () {
      final initialCount = ChatSyncHelper.instance.messagesNotifier.value.length;

      ChatSyncHelper.instance.sendMessage(
        senderRole: 'user',
        text: 'Halo pak kurir, saya sudah di depan rumah.',
      );

      final afterUserCount = ChatSyncHelper.instance.messagesNotifier.value.length;
      expect(afterUserCount, initialCount + 1);
      expect(ChatSyncHelper.instance.messagesNotifier.value.last.isFromUser, isTrue);

      ChatSyncHelper.instance.sendMessage(
        senderRole: 'driver',
        text: 'Siap kak, 2 menit lagi sampai.',
      );

      final afterDriverCount = ChatSyncHelper.instance.messagesNotifier.value.length;
      expect(afterDriverCount, afterUserCount + 1);
      expect(ChatSyncHelper.instance.messagesNotifier.value.last.isFromDriver, isTrue);
    });

    test('UserModel role customer and driver serialization test', () {
      final customer = UserModel(
        name: 'Siti Rahmawati',
        email: 'siti@example.com',
        password: 'password123',
        role: 'customer',
        phone: '081234567890',
        address: 'Jl. Mawar No. 12',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(customer.isCustomer, isTrue);
      expect(customer.isDriver, isFalse);

      final customerMap = customer.toMap();
      expect(customerMap['role'], 'customer');
      expect(customerMap['phone'], '081234567890');

      final customerFromMap = UserModel.fromMap(customerMap);
      expect(customerFromMap.name, 'Siti Rahmawati');
      expect(customerFromMap.role, 'customer');

      final driver = UserModel(
        name: 'Budi Santoso',
        email: 'driver@trashtocash.id',
        password: 'password123',
        role: 'driver',
        phone: '081987654321',
        vehicleType: 'Motor Listrik Eco',
        vehiclePlate: 'B 1234 XYZ',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(driver.isDriver, isTrue);
      expect(driver.isCustomer, isFalse);

      final driverMap = driver.toMap();
      expect(driverMap['role'], 'driver');
      expect(driverMap['vehicle_plate'], 'B 1234 XYZ');

      final driverFromMap = UserModel.fromMap(driverMap);
      expect(driverFromMap.name, 'Budi Santoso');
      expect(driverFromMap.isDriver, isTrue);
      expect(driverFromMap.vehiclePlate, 'B 1234 XYZ');
    });

    test('RemoteDriverLocation & RealtimeGpsSyncHelper serialization test', () {
      const loc = RemoteDriverLocation(
        latitude: -6.2088,
        longitude: 106.8456,
        speedKmph: 34.0,
        headingDegrees: 45.0,
        distanceKm: 0.8,
        estimatedArrival: '4 Menit',
        progress: 0.35,
      );

      expect(loc.latitude, -6.2088);
      expect(loc.speedKmph, 34.0);
      expect(loc.estimatedArrival, '4 Menit');
      expect(loc.progress, 0.35);

      final map = loc.toMap();
      expect(map['distance_km'], 0.8);
      expect(map['eta'], '4 Menit');

      final fromMap = RemoteDriverLocation.fromMap(map);
      expect(fromMap.latitude, -6.2088);
      expect(fromMap.speedKmph, 34.0);
      expect(fromMap.progress, 0.35);
    });
  });
}
