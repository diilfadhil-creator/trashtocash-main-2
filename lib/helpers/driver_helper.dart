import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/helpers/trash_calculator_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';

class DriverHelper {
  static final DriverHelper instance = DriverHelper._internal();
  DriverHelper._internal() {
    _initializeDriverData();
  }

  // Notifiers for Reactive UI
  final ValueNotifier<DriverProfileModel> profileNotifier =
      ValueNotifier<DriverProfileModel>(const DriverProfileModel());

  final ValueNotifier<List<DriverOrderItemModel>> availableOrdersNotifier =
      ValueNotifier<List<DriverOrderItemModel>>([]);

  final ValueNotifier<DriverOrderItemModel?> activeOrderNotifier =
      ValueNotifier<DriverOrderItemModel?>(null);

  final ValueNotifier<List<DriverOrderItemModel>> completedOrdersNotifier =
      ValueNotifier<List<DriverOrderItemModel>>([]);

  final ValueNotifier<List<Map<String, dynamic>>> driverTransactionsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  final ValueNotifier<bool> isDriverModeActive = ValueNotifier<bool>(false);

  Future<void> _initializeDriverData() async {
    await loadDriverProfile();
    await loadOrdersFromDatabase();
    await loadDriverTransactions();
  }

  // Load Driver Profile from SQLite / SharedPreferences
  Future<void> loadDriverProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('driverName') ?? 'Budi Santoso';
      final phone = prefs.getString('driverPhone') ?? '+62 812-3456-7890';
      final plate = prefs.getString('driverPlate') ?? 'B 1234 XYZ';
      final isOnline = prefs.getBool('driverIsOnline') ?? true;
      final wallet = prefs.getDouble('driverWalletBalance') ?? 145000.0;
      final completed = prefs.getInt('driverCompletedCount') ?? 6;
      final totalKg = prefs.getDouble('driverTotalKg') ?? 34.5;
      final radius = prefs.getDouble('driverRadiusKm') ?? 5.0;
      final vehicleIdx = prefs.getInt('driverVehicleType') ?? 1;

      // Also check SQLite driver_profiles
      final dbProfile = await DatabaseHelper.instance.getDriverProfile('T2C-8842');
      if (dbProfile != null) {
        final dbWallet = (dbProfile['wallet_balance'] as num?)?.toDouble() ?? wallet;
        final dbCompleted = (dbProfile['completed_pickups'] as num?)?.toInt() ?? completed;
        final dbTotalKg = (dbProfile['total_kg'] as num?)?.toDouble() ?? totalKg;

        profileNotifier.value = DriverProfileModel(
          id: 'T2C-8842',
          name: dbProfile['name'] ?? name,
          phone: dbProfile['phone'] ?? phone,
          vehiclePlate: dbProfile['vehicle_plate'] ?? plate,
          vehicleType: DriverVehicleType.electricMotor,
          isOnline: dbProfile['is_online'] == 1,
          walletBalance: dbWallet,
          completedPickupsToday: dbCompleted,
          totalKgToday: dbTotalKg,
          operationalRadiusKm: (dbProfile['operational_radius'] as num?)?.toDouble() ?? radius,
        );
        return;
      }

      DriverVehicleType vehicle = DriverVehicleType.electricMotor;
      if (vehicleIdx >= 0 && vehicleIdx < DriverVehicleType.values.length) {
        vehicle = DriverVehicleType.values[vehicleIdx];
      }

      profileNotifier.value = DriverProfileModel(
        id: 'T2C-8842',
        name: name,
        phone: phone,
        vehiclePlate: plate,
        vehicleType: vehicle,
        isOnline: isOnline,
        walletBalance: wallet,
        completedPickupsToday: completed,
        totalKgToday: totalKg,
        operationalRadiusKm: radius,
      );
    } catch (e) {
      debugPrint('Error loading driver profile: $e');
    }
  }

  // Save Driver Profile updates to SQLite & SharedPreferences
  Future<void> updateDriverProfile(DriverProfileModel updated) async {
    profileNotifier.value = updated;
    try {
      // 1. SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driverName', updated.name);
      await prefs.setString('driverPhone', updated.phone);
      await prefs.setString('driverPlate', updated.vehiclePlate);
      await prefs.setBool('driverIsOnline', updated.isOnline);
      await prefs.setDouble('driverWalletBalance', updated.walletBalance);
      await prefs.setInt('driverCompletedCount', updated.completedPickupsToday);
      await prefs.setDouble('driverTotalKg', updated.totalKgToday);
      await prefs.setDouble('driverRadiusKm', updated.operationalRadiusKm);
      await prefs.setInt('driverVehicleType', updated.vehicleType.index);

      // 2. SQLite Database Persistence
      await DatabaseHelper.instance.saveDriverProfile({
        'id': updated.id,
        'name': updated.name,
        'phone': updated.phone,
        'vehicle_plate': updated.vehiclePlate,
        'vehicle_type': updated.vehicleType.label,
        'is_online': updated.isOnline ? 1 : 0,
        'wallet_balance': updated.walletBalance,
        'completed_pickups': updated.completedPickupsToday,
        'total_kg': updated.totalKgToday,
        'operational_radius': updated.operationalRadiusKm,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving driver profile: $e');
    }
  }

  // Load Driver Wallet Transactions from SQLite
  Future<void> loadDriverTransactions() async {
    try {
      final list = await DatabaseHelper.instance.getDriverWalletTransactions(
        driverId: profileNotifier.value.id,
      );
      driverTransactionsNotifier.value = list;
    } catch (e) {
      debugPrint('Error loading driver wallet transactions: $e');
    }
  }

  // Toggle Driver Online / Offline Status
  Future<void> toggleOnlineStatus() async {
    final current = profileNotifier.value;
    final updated = current.copyWith(isOnline: !current.isOnline);
    await updateDriverProfile(updated);
    if (updated.isOnline) {
      HapticFeedback.mediumImpact();
    }
  }

  // Load Real Orders from SQLite Database
  Future<void> loadOrdersFromDatabase() async {
    try {
      final pickups = await DatabaseHelper.instance.getAllWastePickups();
      final List<DriverOrderItemModel> available = [];
      final List<DriverOrderItemModel> completed = [];

      for (final p in pickups) {
        if (p.method != 'Jemput Sampah') continue;

        final isCompleted = p.status == 'Selesai';
        final isCancelled = p.status == 'Dibatalkan';
        final isProcessing =
            p.status == 'Diproses' ||
            p.status == 'Menuju Lokasi' ||
            p.status == 'Tiba di Lokasi';

        DriverOrderStatus orderStatus = DriverOrderStatus.pending;
        if (isCompleted) {
          orderStatus = DriverOrderStatus.completed;
        } else if (isCancelled) {
          orderStatus = DriverOrderStatus.cancelled;
        } else if (p.status == 'Menuju Lokasi') {
          orderStatus = DriverOrderStatus.headingToUser;
        } else if (p.status == 'Tiba di Lokasi') {
          orderStatus = DriverOrderStatus.arrivedAtLocation;
        } else if (isProcessing) {
          orderStatus = DriverOrderStatus.accepted;
        }

        final orderItem = DriverOrderItemModel(
          dbId: p.id,
          transactionId: p.transactionId,
          userName: 'Warga TrashToCash (${p.pickupAddress?.split(' ').take(2).join(' ') ?? 'User'})',
          userPhone: '0812-9988-7722',
          userAddress: p.pickupAddress ?? 'Jl. Melati Blok C2 No. 15, Jakarta',
          distanceKm: 1.2,
          wasteName: p.wasteName,
          wasteType: p.wasteType,
          estimatedWeightKg: p.weightKg,
          ratePerKg: p.ratePerKg,
          estimatedReward: p.totalReward,
          deliveryFee: 15000.0,
          pickupDate: p.pickupDate ?? 'Hari Ini',
          pickupTime: p.pickupTime ?? '14:00',
          pickupNotes: p.pickupNotes,
          verificationPin: '8842',
          status: orderStatus,
          createdAt: p.createdAt,
        );

        if (isCompleted) {
          completed.add(orderItem);
        } else if (!isCancelled) {
          if (isProcessing && activeOrderNotifier.value == null) {
            activeOrderNotifier.value = orderItem;
          } else {
            available.add(orderItem);
          }
        }
      }

      // Add default mock orders if database has no active orders
      if (available.isEmpty && activeOrderNotifier.value == null) {
        _seedMockAvailableOrders(available);
      }

      availableOrdersNotifier.value = available;
      completedOrdersNotifier.value = completed;
    } catch (e) {
      debugPrint('Error loading orders from database: $e');
    }
  }

  void _seedMockAvailableOrders(List<DriverOrderItemModel> list) {
    list.addAll([
      DriverOrderItemModel(
        transactionId: 'TRX-JMP-901',
        userName: 'Siti Rahmawati',
        userPhone: '0812-7766-5544',
        userAddress: 'Jl. Anggrek No. 42, RT 03/RW 05, Kebayoran Baru',
        distanceKm: 0.8,
        wasteName: 'Plastik PET (Botol Bening)',
        wasteType: 'Non-Organik',
        estimatedWeightKg: 4.5,
        ratePerKg: 10000.0,
        estimatedReward: 45000.0,
        deliveryFee: 15000.0,
        pickupDate: 'Hari Ini',
        pickupTime: '14:30 WIB',
        pickupNotes: 'Kantong plastik besar di dekat pagar hitam.',
        verificationPin: '8842',
        status: DriverOrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      ),
      DriverOrderItemModel(
        transactionId: 'TRX-JMP-902',
        userName: 'Ahmad Fauzi',
        userPhone: '0813-2233-4455',
        userAddress: 'Komplek Permata Hijau Blok D4 No. 12',
        distanceKm: 2.1,
        wasteName: 'Kardus & Kertas Karton',
        wasteType: 'Non-Organik',
        estimatedWeightKg: 12.0,
        ratePerKg: 8000.0,
        estimatedReward: 96000.0,
        deliveryFee: 18000.0,
        pickupDate: 'Hari Ini',
        pickupTime: '15:00 WIB',
        pickupNotes: 'Sudah diikat tali rafia rapi.',
        verificationPin: '8842',
        status: DriverOrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      ),
      DriverOrderItemModel(
        transactionId: 'TRX-JMP-903',
        userName: 'Ibu Ratna Dewi',
        userPhone: '0857-1122-3344',
        userAddress: 'Jl. Mawar Merah No. 8, Cilandak',
        distanceKm: 3.5,
        wasteName: 'Sisa Buah & Sayur Segar (Kompos)',
        wasteType: 'Organik',
        estimatedWeightKg: 6.0,
        ratePerKg: 5000.0,
        estimatedReward: 30000.0,
        deliveryFee: 15000.0,
        pickupDate: 'Hari Ini',
        pickupTime: '15:30 WIB',
        pickupNotes: 'Ember tertutup di garasi samping.',
        verificationPin: '8842',
        status: DriverOrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
      ),
    ]);
  }

  // Hook when user places a pickup order in user app
  void notifyNewPickupOrder(WastePickupModel pickup) {
    final newOrder = DriverOrderItemModel(
      dbId: pickup.id,
      transactionId: pickup.transactionId,
      userName: 'Warga TrashToCash',
      userPhone: '0812-8899-7766',
      userAddress: pickup.pickupAddress ?? 'Alamat Pemesan',
      distanceKm: 1.1,
      wasteName: pickup.wasteName,
      wasteType: pickup.wasteType,
      estimatedWeightKg: pickup.weightKg,
      ratePerKg: pickup.ratePerKg,
      estimatedReward: pickup.totalReward,
      deliveryFee: 15000.0,
      pickupDate: pickup.pickupDate ?? 'Hari Ini',
      pickupTime: pickup.pickupTime ?? '14:00',
      pickupNotes: pickup.pickupNotes,
      verificationPin: '8842',
      status: DriverOrderStatus.pending,
      createdAt: pickup.createdAt,
    );

    final currentAvailable = List<DriverOrderItemModel>.from(availableOrdersNotifier.value);
    currentAvailable.insert(0, newOrder);
    availableOrdersNotifier.value = currentAvailable;

    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  // Driver Accepts an Order & Persists to SQLite Database
  Future<void> acceptOrder(DriverOrderItemModel order, {BuildContext? context}) async {
    order.status = DriverOrderStatus.accepted;
    activeOrderNotifier.value = order;

    // Remove from available radar feed
    final currentAvailable = List<DriverOrderItemModel>.from(availableOrdersNotifier.value);
    currentAvailable.removeWhere((o) => o.transactionId == order.transactionId);
    availableOrdersNotifier.value = currentAvailable;

    try {
      // Check if order exists in SQLite
      final existing = await DatabaseHelper.instance.getWastePickupByTransactionId(order.transactionId);
      if (existing != null) {
        await DatabaseHelper.instance.acceptWastePickupByDriver(
          transactionId: order.transactionId,
          driverId: profileNotifier.value.id,
          driverName: profileNotifier.value.name,
        );
      } else {
        // Insert as real row into SQLite waste_pickups table
        final newPickup = WastePickupModel(
          transactionId: order.transactionId,
          wasteName: order.wasteName,
          wasteType: order.wasteType,
          weightKg: order.estimatedWeightKg,
          ratePerKg: order.ratePerKg,
          totalReward: order.estimatedReward,
          method: 'Jemput Sampah',
          pickupAddress: order.userAddress,
          pickupDate: order.pickupDate,
          pickupTime: order.pickupTime,
          pickupNotes: order.pickupNotes,
          status: 'Diproses',
          createdAt: order.createdAt,
        );
        final insertedId = await DatabaseHelper.instance.insertWastePickup(newPickup);
        order.dbId = insertedId;
      }
    } catch (e) {
      debugPrint('Error persisting accepted order to database: $e');
    }

    HapticFeedback.mediumImpact();

    if (context != null && context.mounted) {
      NotificationHelper.triggerNotification(
        context: context,
        type: NotificationType.pickupStatus,
        title: 'Order Penjemputan Diterima! 🚚',
        message: 'Anda menerima order penjemputan dari ${order.userName}. Silakan menuju lokasi.',
        showInAppBanner: true,
      );
    }
  }

  // Driver Updates Step (Heading to User, Arrived, etc.) & Persists to SQLite
  Future<void> updateActiveOrderStatus(
    DriverOrderStatus newStatus, {
    BuildContext? context,
  }) async {
    final active = activeOrderNotifier.value;
    if (active == null) return;

    active.status = newStatus;
    activeOrderNotifier.value = active.copyWith(status: newStatus);

    String dbStatus = 'Diproses';
    if (newStatus == DriverOrderStatus.headingToUser) {
      dbStatus = 'Menuju Lokasi';
    } else if (newStatus == DriverOrderStatus.arrivedAtLocation) {
      dbStatus = 'Tiba di Lokasi';
    } else if (newStatus == DriverOrderStatus.completed) {
      dbStatus = 'Selesai';
    }

    try {
      if (active.dbId != null) {
        await DatabaseHelper.instance.updatePickupStatus(active.dbId!, dbStatus);
      } else {
        await DatabaseHelper.instance.updatePickupStatusByTransactionId(
          active.transactionId,
          dbStatus,
        );
      }
    } catch (e) {
      debugPrint('Error updating order status in SQLite: $e');
    }

    HapticFeedback.lightImpact();

    if (context != null && context.mounted) {
      if (newStatus == DriverOrderStatus.headingToUser) {
        NotificationHelper.triggerNotification(
          context: context,
          type: NotificationType.pickupStatus,
          title: 'Status: Menuju Lokasi 🗺️',
          message: 'Navigasi aktif. Harap utamakan keselamatan berkendara.',
          showInAppBanner: false,
        );
      } else if (newStatus == DriverOrderStatus.arrivedAtLocation) {
        NotificationHelper.triggerNotification(
          context: context,
          type: NotificationType.pickupStatus,
          title: 'Status: Tiba di Lokasi 📍',
          message: 'Anda telah tiba di alamat warga. Siapkan timbangan digital.',
          showInAppBanner: true,
        );
      }
    }
  }

  // Driver Verifies Weight & PIN and Completes Pickup in Database
  Future<bool> verifyAndCompletePickup({
    required double actualWeightKg,
    required String enteredPin,
    String? proofPhotoPath,
    BuildContext? context,
  }) async {
    final active = activeOrderNotifier.value;
    if (active == null) return false;

    // Check PIN: Allow '8842' or active order pin
    if (enteredPin.trim() != active.verificationPin && enteredPin.trim() != '8842') {
      return false;
    }

    final userPoints = await DatabaseHelper.instance.getUserEcoPoints();
    final calcResult = TrashToCashCalculator.calculateResult(
      weightKg: actualWeightKg,
      ratePerKg: active.ratePerKg,
      method: CollectionMethod.pickup,
      currentMemberPoints: userPoints,
    );

    final finalReward = calcResult.finalTCashReward;
    active.actualWeightKg = actualWeightKg;
    active.actualReward = finalReward;
    active.proofPhotoPath = proofPhotoPath;
    active.status = DriverOrderStatus.completed;

    // 1. Update SQLite waste_pickups to Selesai
    try {
      await DatabaseHelper.instance.completeWastePickupByDriver(
        transactionId: active.transactionId,
        actualWeightKg: actualWeightKg,
        totalReward: finalReward,
        proofPhotoPath: proofPhotoPath,
        driverId: profileNotifier.value.id,
      );
    } catch (e) {
      debugPrint('Error completing pickup in SQLite: $e');
    }

    // 1b. Credit Customer Wallet in SQLite using TrashToCash official calculation
    try {
      await DatabaseHelper.instance.creditUserBalance(
        amount: calcResult.finalTCashReward,
        title: 'Setor Sampah ${active.wasteName}',
        description:
            '${actualWeightKg.toStringAsFixed(1)} kg • Dijemput Kurir (${calcResult.tier.nameLabel})',
        transactionId: active.transactionId,
        ecoPoints: calcResult.finalEcoPoints,
        weightKg: actualWeightKg,
        channel: 'Jemput Sampah',
      );
    } catch (e) {
      debugPrint('Error crediting customer wallet in SQLite: $e');
    }

    // 2. Insert Commission Transaction to SQLite driver_wallet_transactions
    try {
      await DatabaseHelper.instance.insertDriverWalletTransaction(
        driverId: profileNotifier.value.id,
        transactionId: active.transactionId,
        type: 'commission',
        title: 'Komisi Penjemputan ${active.wasteName}',
        description: 'Penjemputan ${actualWeightKg.toStringAsFixed(1)} kg (${active.userName})',
        amount: active.deliveryFee,
        status: 'success',
      );
      await loadDriverTransactions();
    } catch (e) {
      debugPrint('Error saving commission to SQLite: $e');
    }

    // 3. Update Driver Earnings & Profile in SQLite
    final curProfile = profileNotifier.value;
    final updatedProfile = curProfile.copyWith(
      walletBalance: curProfile.walletBalance + active.deliveryFee,
      completedPickupsToday: curProfile.completedPickupsToday + 1,
      totalKgToday: curProfile.totalKgToday + actualWeightKg,
    );
    await updateDriverProfile(updatedProfile);

    // 4. Move active order to completed list
    final completedList = List<DriverOrderItemModel>.from(completedOrdersNotifier.value);
    completedList.insert(0, active);
    completedOrdersNotifier.value = completedList;
    activeOrderNotifier.value = null;

    // 5. Play Coin celebration sound
    await SoundHelper.playCoinSound(force: true);

    if (context != null && context.mounted) {
      NotificationHelper.triggerNotification(
        context: context,
        type: NotificationType.rewardDeposit,
        title: 'Penjemputan Sukses! +Rp 15.000 Masuk Dompet 💰',
        message: 'Komisi penjemputan ${active.wasteName} (${actualWeightKg.toStringAsFixed(1)} kg) berhasil dicairkan.',
        showInAppBanner: true,
      );
    }

    return true;
  }

  // Withdraw Driver Earnings & Persist to SQLite
  Future<bool> withdrawEarnings({
    required double amount,
    required String bankOrWalletName,
    required String accountNumber,
    BuildContext? context,
  }) async {
    final curProfile = profileNotifier.value;
    if (amount <= 0 || amount > curProfile.walletBalance) {
      return false;
    }

    // 1. Insert Withdrawal Record to SQLite driver_wallet_transactions
    try {
      await DatabaseHelper.instance.insertDriverWalletTransaction(
        driverId: curProfile.id,
        type: 'withdrawal',
        title: 'Penarikan Saldo ke $bankOrWalletName',
        description: 'Rekening / No. E-Wallet: $accountNumber',
        amount: -amount,
        channel: '$bankOrWalletName ($accountNumber)',
        status: 'success',
      );
      await loadDriverTransactions();
    } catch (e) {
      debugPrint('Error saving withdrawal to SQLite: $e');
    }

    // 2. Update Profile & Balance in SQLite
    final updated = curProfile.copyWith(
      walletBalance: curProfile.walletBalance - amount,
    );
    await updateDriverProfile(updated);
    await SoundHelper.playWithdrawalSuccessSound(force: true);

    if (context != null && context.mounted) {
      NotificationHelper.triggerNotification(
        context: context,
        type: NotificationType.withdrawalSuccess,
        title: 'Penarikan Komisi Berhasil! 💸',
        message: 'Penarikan Rp ${amount.toStringAsFixed(0)} ke $bankOrWalletName ($accountNumber) berhasil dikirim.',
        showInAppBanner: true,
      );
    }

    return true;
  }
}
