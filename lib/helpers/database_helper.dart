import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/data/waste_seed_data.dart';
import 'package:trashtocash/models/reward_item_model.dart';
import 'package:trashtocash/models/user_model.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';

/// DatabaseHelper powered by Firebase Cloud Firestore Real-time
/// Menggantikan SQFlite dengan sinkronisasi Cloud Firestore secara real-time.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  DatabaseHelper._init() {
    _initRealtimeSync();
  }

  // Stream controller untuk GPS realtime driver
  final StreamController<Map<String, dynamic>> _realtimeGpsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get realtimeGpsStream =>
      _realtimeGpsStreamController.stream;

  // Stream controller untuk Chat realtime kurir-nasabah
  final StreamController<List<Map<String, dynamic>>> _chatStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get chatStream =>
      _chatStreamController.stream;

  // Koleksi Firestore
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _wasteItemsCol =>
      _firestore.collection('waste_items');
  CollectionReference<Map<String, dynamic>> get _wastePickupsCol =>
      _firestore.collection('waste_pickups');
  CollectionReference<Map<String, dynamic>> get _userWalletsCol =>
      _firestore.collection('user_wallets');
  CollectionReference<Map<String, dynamic>> get _userWalletTransactionsCol =>
      _firestore.collection('user_wallet_transactions');
  CollectionReference<Map<String, dynamic>> get _driverProfilesCol =>
      _firestore.collection('driver_profiles');
  CollectionReference<Map<String, dynamic>> get _driverWalletTransactionsCol =>
      _firestore.collection('driver_wallet_transactions');
  CollectionReference<Map<String, dynamic>> get _driverRealtimeGpsCol =>
      _firestore.collection('driver_realtime_gps');
  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _dropPointsCol =>
      _firestore.collection('drop_points');
  CollectionReference<Map<String, dynamic>> get _chatMessagesCol =>
      _firestore.collection('chat_messages');
  CollectionReference<Map<String, dynamic>> get _aiScanHistoryCol =>
      _firestore.collection('ai_scan_history');
  CollectionReference<Map<String, dynamic>> get _userRedeemedRewardsCol =>
      _firestore.collection('user_redeemed_rewards');

  // Inisialisasi Realtime Listeners
  void _initRealtimeSync() {
    try {
      if (Firebase.apps.isEmpty) return;

      // 1. Listen to waste_pickups collection real-time
      _wastePickupsCol.snapshots().listen((snapshot) {
        historyUpdateNotifier.value++;
      }, onError: (e) {
        debugPrint('Firestore pickups stream error: $e');
      });

      // 2. Listen to chat messages real-time
      _chatMessagesCol
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        final messages = snapshot.docs.map((doc) => doc.data()).toList();
        if (!_chatStreamController.isClosed) {
          _chatStreamController.add(messages);
        }
      }, onError: (e) {
        debugPrint('Firestore chat stream error: $e');
      });

      // 3. Listen to realtime GPS
      _driverRealtimeGpsCol.snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final latestDoc = snapshot.docs.last.data();
          if (!_realtimeGpsStreamController.isClosed) {
            _realtimeGpsStreamController.add(latestDoc);
          }
        }
      }, onError: (e) {
        debugPrint('Firestore GPS stream error: $e');
      });
    } catch (e) {
      debugPrint('Error initializing Firestore realtime listeners: $e');
    }
  }

  /// Reaktif Notifier untuk Saldo, Poin, Avatar, dan Profil Pengguna secara Real-Time di seluruh UI
  static final ValueNotifier<double> userBalanceNotifier =
      ValueNotifier<double>(0.0);
  static final ValueNotifier<int> userEcoPointsNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<String> userAvatarNotifier =
      ValueNotifier<String>('');
  static final ValueNotifier<String> userNameNotifier =
      ValueNotifier<String>('TrashToCash Member');
  static final ValueNotifier<int> historyUpdateNotifier = ValueNotifier<int>(0);

  /// Pemicu instan notifikasi perubahan riwayat aktivitas di seluruh UI
  static void notifyHistoryChanged() {
    historyUpdateNotifier.value++;
  }

  /// Helper utility untuk memformat nominal angka menjadi format Rupiah yang rapi
  static String formatRupiah(
    num amount, {
    bool withSymbol = true,
    bool withDecimals = false,
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formatted;
    if (withDecimals && absAmount % 1 != 0) {
      final parts = absAmount.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      formatted = '$intPart,${parts[1]}';
    } else {
      final roundVal = absAmount.round();
      formatted = roundVal.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    }

    if (!withSymbol) {
      return isNegative ? '-$formatted' : formatted;
    }
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }

  Future<String> _resolveUserEmail([String? providedEmail]) async {
    if (providedEmail != null && providedEmail.trim().isNotEmpty) {
      return providedEmail.trim();
    }
    final currentFbUser = FirebaseAuth.instance.currentUser;
    if (currentFbUser?.email != null && currentFbUser!.email!.isNotEmpty) {
      return currentFbUser.email!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ??
          prefs.getString('userEmail') ??
          prefs.getString('registeredEmail');
      if (email != null && email.trim().isNotEmpty) {
        return email.trim();
      }
    } catch (_) {}
    return 'user@email.com';
  }

  // ==========================================
  // 1. KATALOG SAMPAH (WASTE ITEMS)
  // ==========================================

  Future<int> insertWasteItem(WasteItemModel item) async {
    final map = item.toMap();
    final docRef = _wasteItemsCol.doc(item.id?.toString());
    await docRef.set(map);
    return item.id ?? docRef.id.hashCode;
  }

  Future<List<WasteItemModel>> getAllWasteItems() async {
    try {
      final snapshot = await _wasteItemsCol.get();
      if (snapshot.docs.isEmpty) {
        return _seedDefaultWasteItems();
      }
      return snapshot.docs
          .map((doc) => WasteItemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return _seedDefaultWasteItems();
    }
  }

  List<WasteItemModel> _seedDefaultWasteItems() {
    return wasteSeedData.asMap().entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      data['id'] = entry.key + 1;
      try {
        if (Firebase.apps.isNotEmpty) {
          _wasteItemsCol.doc('${entry.key + 1}').set(data).catchError((_) {});
        }
      } catch (_) {}
      return WasteItemModel.fromMap(data);
    }).toList();
  }

  Future<List<WasteItemModel>> getWasteItemsByType(String type) async {
    final all = await getAllWasteItems();
    return all.where((w) => w.type.toLowerCase() == type.toLowerCase()).toList();
  }

  Future<WasteItemModel?> getWasteItemById(int id) async {
    final all = await getAllWasteItems();
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<WasteItemModel>> searchWasteItems(String keyword) async {
    final all = await getAllWasteItems();
    final lower = keyword.toLowerCase();
    return all.where((item) {
      return item.name.toLowerCase().contains(lower) ||
          item.type.toLowerCase().contains(lower) ||
          item.sampleItem.toLowerCase().contains(lower) ||
          item.description.toLowerCase().contains(lower);
    }).toList();
  }

  Future<int> updateWasteItem(WasteItemModel item) async {
    if (item.id == null) return 0;
    await _wasteItemsCol.doc(item.id.toString()).update(item.toMap());
    return 1;
  }

  Future<int> deleteWasteItemsForMigration() async {
    final snapshot = await _wasteItemsCol.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return snapshot.docs.length;
  }

  // ==========================================
  // 2. SETORAN & PENJEMPUTAN SAMPAH (PICKUPS)
  // ==========================================

  Future<int> insertWastePickup(WastePickupModel pickup) async {
    final map = pickup.toMap();
    final docId = pickup.transactionId.isNotEmpty
        ? pickup.transactionId
        : 'TRX-DEP-${DateTime.now().millisecondsSinceEpoch}';
    map['transaction_id'] = docId;
    await _wastePickupsCol.doc(docId).set(map);
    historyUpdateNotifier.value++;
    return docId.hashCode;
  }

  Future<List<WastePickupModel>> getAllWastePickups() async {
    try {
      final snapshot =
          await _wastePickupsCol.orderBy('created_at', descending: true).get();
      return snapshot.docs
          .map((doc) => WastePickupModel.fromMap(doc.data()))
          .toList();
    } catch (_) {
      try {
        final snapshot = await _wastePickupsCol.get();
        final list =
            snapshot.docs.map((doc) => WastePickupModel.fromMap(doc.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<WastePickupModel>> getWastePickupsByUser([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _wastePickupsCol
          .where('user_email', isEqualTo: email)
          .get();
      final list =
          snapshot.docs.map((doc) => WastePickupModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      final all = await getAllWastePickups();
      return all.where((p) => p.userEmail?.toLowerCase() == email.toLowerCase()).toList();
    }
  }

  Future<List<WastePickupModel>> getWastePickupsByType(String wasteType) async {
    final all = await getAllWastePickups();
    return all.where((p) => p.wasteType.toLowerCase() == wasteType.toLowerCase()).toList();
  }

  Future<WastePickupModel?> getWastePickupById(int id) async {
    final all = await getAllWastePickups();
    try {
      return all.firstWhere((p) => p.id == id || p.transactionId.hashCode == id);
    } catch (_) {
      return null;
    }
  }

  Future<WastePickupModel?> getWastePickupByTransactionId(String transactionId) async {
    final doc = await _wastePickupsCol.doc(transactionId).get();
    if (doc.exists && doc.data() != null) {
      return WastePickupModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<int> updatePickupStatus(int id, String status) async {
    final pickup = await getWastePickupById(id);
    if (pickup != null) {
      return await updatePickupStatusByTransactionId(pickup.transactionId, status);
    }
    return 0;
  }

  Future<int> updatePickupStatusByTransactionId(
    String transactionId,
    String status, {
    String? driverId,
    String? driverName,
    double? actualWeight,
    double? totalReward,
    String? proofPhoto,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };
    if (driverId != null) updates['driver_id'] = driverId;
    if (driverName != null) updates['driver_name'] = driverName;
    if (actualWeight != null) updates['actual_weight_kg'] = actualWeight;
    if (totalReward != null) updates['total_reward'] = totalReward;
    if (proofPhoto != null) updates['proof_photo_path'] = proofPhoto;

    await _wastePickupsCol.doc(transactionId).update(updates);
    historyUpdateNotifier.value++;
    return 1;
  }

  Future<int> markLatestPickupAsSuccess() async {
    final all = await getAllWastePickups();
    if (all.isNotEmpty) {
      final latest = all.first;
      return await updatePickupStatusByTransactionId(latest.transactionId, 'Selesai');
    }
    return 0;
  }

  Future<int> updateWastePickup(WastePickupModel pickup) async {
    await _wastePickupsCol.doc(pickup.transactionId).update(pickup.toMap());
    historyUpdateNotifier.value++;
    return 1;
  }

  Future<int> deleteWastePickupById(int id) async {
    final pickup = await getWastePickupById(id);
    if (pickup != null) {
      await _wastePickupsCol.doc(pickup.transactionId).delete();
      historyUpdateNotifier.value++;
      return 1;
    }
    return 0;
  }

  Future<int> deleteWastePickupsForMigration() async {
    final snapshot = await _wastePickupsCol.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    historyUpdateNotifier.value++;
    return snapshot.docs.length;
  }

  Future<int> deleteWastePickupByTransactionId(String transactionId) async {
    await _wastePickupsCol.doc(transactionId).delete();
    historyUpdateNotifier.value++;
    return 1;
  }

  // ==========================================
  // 3. USER ACCOUNTS & AUTH
  // ==========================================

  Future<int> registerUser(UserModel user) async {
    final docId = user.email.toLowerCase().trim();
    final map = user.toMap();
    await _usersCol.doc(docId).set(map, SetOptions(merge: true));
    return docId.hashCode;
  }

  Future<bool> isEmailRegistered(String email) async {
    final doc = await _usersCol.doc(email.toLowerCase().trim()).get();
    if (doc.exists) return true;
    final query = await _usersCol
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final doc = await _usersCol.doc(email.toLowerCase().trim()).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data['password'] == password) {
        return UserModel.fromMap(data);
      }
    }
    final query = await _usersCol
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      if (data['password'] == password) {
        return UserModel.fromMap(data);
      }
    }
    return null;
  }

  Future<UserModel?> loginUserWithRole(
    String email,
    String password,
    String role,
  ) async {
    final user = await loginUser(email, password);
    if (user != null && user.role.toLowerCase() == role.toLowerCase()) {
      return user;
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final doc = await _usersCol.doc(email.toLowerCase().trim()).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    final query = await _usersCol
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<int> updateUserProfile({
    required String email,
    required String name,
    required String phone,
    required String address,
    String? birthDate,
    String? gender,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
    };
    if (birthDate != null) updates['birth_date'] = birthDate;
    if (gender != null) updates['gender'] = gender;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _usersCol.doc(email.toLowerCase().trim()).set(updates, SetOptions(merge: true));
    userNameNotifier.value = name;
    if (avatarUrl != null) userAvatarNotifier.value = avatarUrl;
    return 1;
  }

  Future<Map<String, dynamic>> getUserPaymentAccounts(String email) async {
    final user = await getUserByEmail(email);
    if (user == null) return {};
    return {
      'bank_name': user.bankName,
      'bank_account_number': user.bankAccountNumber,
      'bank_account_holder': user.bankAccountHolder,
      'ewallet_type': user.ewalletType,
      'ewallet_number': user.ewalletNumber,
      'ewallet_account_holder': user.ewalletAccountHolder,
      'preferred_payout_method': user.preferredPayoutMethod,
    };
  }

  // ==========================================
  // 4. DRIVER PORTAL
  // ==========================================

  Future<int> insertDriverWalletTransaction({
    required String driverId,
    String? transactionId,
    required String type,
    required String title,
    String? description,
    required double amount,
    String? channel,
    String status = 'success',
  }) async {
    final data = {
      'driver_id': driverId,
      'transaction_id': transactionId ?? 'TRX-DRV-${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'channel': channel,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };
    final docRef = await _driverWalletTransactionsCol.add(data);
    return docRef.id.hashCode;
  }

  Future<List<Map<String, dynamic>>> getDriverWalletTransactions({
    String driverId = 'T2C-8842',
  }) async {
    final snapshot = await _driverWalletTransactionsCol
        .where('driver_id', isEqualTo: driverId)
        .get();
    final list = snapshot.docs.map((d) => d.data()).toList();
    list.sort((a, b) =>
        (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list;
  }

  Future<List<WastePickupModel>> getPendingDriverPickups() async {
    final all = await getAllWastePickups();
    return all.where((p) {
      return p.method == 'Jemput Sampah' &&
          (p.status == 'Menunggu Penjemputan' || p.status == 'Pending');
    }).toList();
  }

  Future<List<WastePickupModel>> getDriverCompletedPickups({
    String? driverId,
  }) async {
    final all = await getAllWastePickups();
    return all.where((p) {
      return p.status == 'Selesai';
    }).toList();
  }

  Future<int> acceptWastePickupByDriver({
    required String transactionId,
    required String driverId,
    required String driverName,
  }) async {
    await updatePickupStatusByTransactionId(
      transactionId,
      'Diproses',
      driverId: driverId,
      driverName: driverName,
    );
    return 1;
  }

  Future<int> completeWastePickupByDriver({
    required String transactionId,
    double? actualWeight,
    double? actualWeightKg,
    double? totalReward,
    String? proofPhotoPath,
    String? driverId,
  }) async {
    final weight = actualWeightKg ?? actualWeight ?? 0.0;
    await updatePickupStatusByTransactionId(
      transactionId,
      'Selesai',
      actualWeight: weight,
      totalReward: totalReward,
      proofPhoto: proofPhotoPath,
      driverId: driverId,
    );
    return 1;
  }

  Future<void> saveDriverProfile(Map<String, dynamic> profile) async {
    final id = profile['id'] as String? ?? 'T2C-8842';
    await _driverProfilesCol.doc(id).set(profile, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    final doc = await _driverProfilesCol.doc(driverId).get();
    if (doc.exists) return doc.data();
    return {
      'id': driverId,
      'name': 'Budi Santoso',
      'phone': '0812-3456-7890',
      'vehicle_plate': 'B 1234 XYZ',
      'vehicle_type': 'motorcycle',
      'is_online': 1,
      'wallet_balance': 145000.0,
      'completed_pickups': 18,
      'total_kg': 84.5,
      'operational_radius': 5.0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<int> insertOrUpdateDriverGps(Map<String, dynamic> gpsData) async {
    final trxId = gpsData['transaction_id'] as String? ?? 'active_order';
    await _driverRealtimeGpsCol.doc(trxId).set(gpsData, SetOptions(merge: true));
    if (!_realtimeGpsStreamController.isClosed) {
      _realtimeGpsStreamController.add(gpsData);
    }
    return 1;
  }

  Future<Map<String, dynamic>?> getLatestDriverGps(String transactionId) async {
    final doc = await _driverRealtimeGpsCol.doc(transactionId).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<List<Map<String, dynamic>>> getDriverGpsHistory(
      String transactionId) async {
    final doc = await getLatestDriverGps(transactionId);
    return doc != null ? [doc] : [];
  }

  // ==========================================
  // 5. USER WALLETS & ECO POINTS
  // ==========================================

  Future<Map<String, dynamic>> syncUserWalletFromDb([String? userEmail]) async {
    final wallet = await getOrCreateUserWallet(userEmail);
    userBalanceNotifier.value =
        (wallet['balance'] as num?)?.toDouble() ?? 0.0;
    userEcoPointsNotifier.value =
        (wallet['eco_points'] as num?)?.toInt() ?? 0;
    return wallet;
  }

  Future<Map<String, dynamic>> getOrCreateUserWallet([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    final doc = await _userWalletsCol.doc(email).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      userBalanceNotifier.value = (data['balance'] as num?)?.toDouble() ?? 0.0;
      userEcoPointsNotifier.value = (data['eco_points'] as num?)?.toInt() ?? 0;
      return data;
    }

    // Buat data dompet default baru di Firestore
    final initialWallet = {
      'user_id': 1,
      'user_email': email,
      'balance': 850000.0,
      'eco_points': 120,
      'total_deposited_kg': 12.5,
      'completed_deposits': 4,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _userWalletsCol.doc(email).set(initialWallet);
    userBalanceNotifier.value = 850000.0;
    userEcoPointsNotifier.value = 120;
    return initialWallet;
  }

  Future<double> getUserWalletBalance([String? userEmail]) async {
    final wallet = await getOrCreateUserWallet(userEmail);
    return (wallet['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getUserEcoPoints([String? userEmail]) async {
    final wallet = await getOrCreateUserWallet(userEmail);
    return (wallet['eco_points'] as num?)?.toInt() ?? 0;
  }

  Future<bool> creditUserBalance({
    String? userEmail,
    required double amount,
    int? ecoPoints,
    int? earnedEcoPoints,
    double? weightKg,
    double? depositedKg,
    String? transactionId,
    String? wasteName,
    String? title,
    String? description,
    String? channel = 'Setor Sampah',
  }) async {
    final email = await _resolveUserEmail(userEmail);
    final currentWallet = await getOrCreateUserWallet(email);
    final currentBalance = (currentWallet['balance'] as num?)?.toDouble() ?? 0.0;
    final currentPoints = (currentWallet['eco_points'] as num?)?.toInt() ?? 0;
    final currentKg =
        (currentWallet['total_deposited_kg'] as num?)?.toDouble() ?? 0.0;
    final currentDeposits =
        (currentWallet['completed_deposits'] as num?)?.toInt() ?? 0;

    final pointsToAdd = ecoPoints ?? earnedEcoPoints ?? 0;
    final kgToAdd = weightKg ?? depositedKg ?? 0.0;

    final newBalance = currentBalance + amount;
    final newPoints = currentPoints + pointsToAdd;
    final newKg = currentKg + kgToAdd;
    final newDeposits = currentDeposits + 1;

    await _userWalletsCol.doc(email).set({
      'user_email': email,
      'balance': newBalance,
      'eco_points': newPoints,
      'total_deposited_kg': newKg,
      'completed_deposits': newDeposits,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await _userWalletTransactionsCol.add({
      'user_email': email,
      'transaction_id':
          transactionId ?? 'TRX-DEP-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'deposit',
      'title': title ?? (wasteName != null ? 'Deposit $wasteName' : 'Setoran Sampah'),
      'description': description ?? '$kgToAdd kg • $channel',
      'amount': amount,
      'channel': channel,
      'status': 'success',
      'created_at': DateTime.now().toIso8601String(),
    });

    userBalanceNotifier.value = newBalance;
    userEcoPointsNotifier.value = newPoints;
    notifyHistoryChanged();
    return true;
  }

  Future<bool> debitUserBalance({
    String? userEmail,
    required double amount,
    String? title,
    String? channel = 'Penarikan Saldo',
    String? description,
  }) async {
    final email = await _resolveUserEmail(userEmail);
    final currentWallet = await getOrCreateUserWallet(email);
    final currentBalance = (currentWallet['balance'] as num?)?.toDouble() ?? 0.0;
    if (currentBalance < amount) return false;

    final newBalance = currentBalance - amount;
    await _userWalletsCol.doc(email).update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _userWalletTransactionsCol.add({
      'user_email': email,
      'transaction_id': 'TRX-WDL-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'withdrawal',
      'title': title ?? 'Penarikan Saldo',
      'description': description ?? channel,
      'amount': -amount,
      'channel': channel,
      'status': 'success',
      'created_at': DateTime.now().toIso8601String(),
    });

    userBalanceNotifier.value = newBalance;
    notifyHistoryChanged();
    return true;
  }

  Future<List<Map<String, dynamic>>> getUserWalletTransactions(
      [String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _userWalletTransactionsCol
          .where('user_email', isEqualTo: email)
          .get();
      final list = snapshot.docs.map((d) => d.data()).toList();
      list.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> recalculateUserBalanceFromSales(
      [String? userEmail]) async {
    return await syncUserWalletFromDb(userEmail);
  }

  // ==========================================
  // 6. NOTIFIKASI (NOTIFICATIONS)
  // ==========================================

  Future<List<Map<String, dynamic>>> getNotifications([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _notificationsCol
          .where('user_email', isEqualTo: email)
          .get();
      if (snapshot.docs.isEmpty) {
        return _seedDefaultNotifications(email);
      }
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = (data['id'] as num?)?.toInt() ?? doc.id.hashCode;
        data['_doc_id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      return list;
    } catch (_) {
      return _seedDefaultNotifications(email);
    }
  }

  List<Map<String, dynamic>> _seedDefaultNotifications(String userEmail) {
    final initialNotifs = [
      {
        'id': 1,
        'user_email': userEmail,
        'title': 'Setoran Sampah Berhasil Diverifikasi! 🌿',
        'message':
            'Setoran sampah plastik & kertas seberat 4.5 kg telah selesai ditimbang. Saldo sebesar +Rp 45.000 telah ditambahkan ke dompet Anda.',
        'time': 'Baru saja',
        'type': 'rewardDeposit',
        'is_read': 0,
        'action_label': 'Lihat Riwayat',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'user_email': userEmail,
        'title': 'Kurir Menuju Lokasi Penjemputan 🚚',
        'message':
            'Kurir Budi Santoso (B 1234 XYZ) sedang dalam perjalanan. Estimasi tiba dalam 12 menit.',
        'time': '1 jam yang lalu',
        'type': 'pickupStatus',
        'is_read': 0,
        'action_label': 'Lacak Penjemputan',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
    ];
    for (final notif in initialNotifs) {
      _notificationsCol.add(notif).then((_) {}, onError: (_) {});
    }
    return initialNotifs;
  }

  Future<int> insertNotification({
    String? userEmail,
    required String title,
    required String message,
    String? type,
    String? time,
    String? actionLabel,
    int? isRead,
  }) async {
    final email = await _resolveUserEmail(userEmail);
    final id = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    final data = {
      'id': id,
      'user_email': email,
      'title': title,
      'message': message,
      'type': type ?? 'general',
      'time': time ?? 'Baru saja',
      'action_label': actionLabel,
      'is_read': isRead ?? 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _notificationsCol.add(data);
    return id;
  }

  Future<int> markNotificationAsRead(int id) async {
    try {
      final snapshot = await _notificationsCol.get();
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        final docId = (docData['id'] as num?)?.toInt() ?? doc.id.hashCode;
        if (docId == id) {
          await doc.reference.update({'is_read': 1});
          break;
        }
      }
      return 1;
    } catch (_) {
      return 0;
    }
  }

  Future<int> markAllNotificationsAsRead([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _notificationsCol
          .where('user_email', isEqualTo: email)
          .where('is_read', isEqualTo: 0)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.update({'is_read': 1});
      }
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> deleteNotification(int id) async {
    try {
      final snapshot = await _notificationsCol.get();
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        final docId = (docData['id'] as num?)?.toInt() ?? doc.id.hashCode;
        if (docId == id) {
          await doc.reference.delete();
          return 1;
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> clearAllNotifications([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _notificationsCol
          .where('user_email', isEqualTo: email)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getUnreadNotificationCount([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    try {
      final snapshot = await _notificationsCol
          .where('user_email', isEqualTo: email)
          .where('is_read', isEqualTo: 0)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  // ==========================================
  // 7. DROP POINTS (BANK SAMPAH)
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllDropPoints() async {
    try {
      final snapshot = await _dropPointsCol.get();
      if (snapshot.docs.isEmpty) {
        return _seedDefaultDropPoints();
      }
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {
      return _seedDefaultDropPoints();
    }
  }

  List<Map<String, dynamic>> _seedDefaultDropPoints() {
    final list = [
      {
        'id': 1,
        'name': 'Recycling Center Central',
        'address': 'Jl. Hijau Daun No. 45, Jakarta Selatan',
        'lat': -6.2115,
        'lng': 106.8480,
        'hours': 'Buka 08:00 - 17:00',
        'status': 'Buka Sekarang',
        'categories': 'Plastik, Kertas, Logam, E-Waste',
        'map_x': 0.35,
        'map_y': 0.40,
        'phone': '021-5551234',
        'is_active': 1,
      },
      {
        'id': 2,
        'name': 'Bank Sampah Melati Pusat',
        'address': 'Jl. Kebon Kacang Raya Blok C2, Jakarta Pusat',
        'lat': -6.2085,
        'lng': 106.8450,
        'hours': 'Buka 08:30 - 17:30',
        'status': 'Buka Sekarang',
        'categories': 'Plastik PET, Kardus, Kaca, Minyak',
        'map_x': 0.65,
        'map_y': 0.35,
        'phone': '0812-9988-7766',
        'is_active': 1,
      },
    ];
    for (final dp in list) {
      _dropPointsCol.doc('${dp['id']}').set(dp).catchError((_) {});
    }
    return list;
  }

  Future<int> insertDropPoint(Map<String, dynamic> point) async {
    final docRef = await _dropPointsCol.add(point);
    return docRef.id.hashCode;
  }

  // ==========================================
  // 8. CHAT MESSAGES REALTIME
  // ==========================================

  Future<List<Map<String, dynamic>>> getChatMessages() async {
    try {
      final snapshot = await _chatMessagesCol
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> insertChatMessage({
    required String msgId,
    required String senderRole,
    required String text,
    String? imagePath,
    bool isSystem = false,
    DateTime? timestamp,
  }) async {
    final data = {
      'msg_id': msgId,
      'sender_role': senderRole,
      'text': text,
      'image_path': imagePath,
      'is_system': isSystem ? 1 : 0,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
    await _chatMessagesCol.doc(msgId).set(data);
    return 1;
  }

  Future<int> clearChatMessages() async {
    final snapshot = await _chatMessagesCol.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return snapshot.docs.length;
  }

  // ==========================================
  // 9. AI SCAN HISTORY
  // ==========================================

  Future<int> insertAiScanHistory({
    String? userEmail,
    required String itemName,
    required String category,
    required double confidence,
    required double weightKg,
    required double reward,
    required int ecoPoints,
  }) async {
    final email = await _resolveUserEmail(userEmail);
    final data = {
      'user_email': email,
      'item_name': itemName,
      'category': category,
      'confidence': confidence,
      'weight_kg': weightKg,
      'reward': reward,
      'eco_points': ecoPoints,
      'scanned_at': DateTime.now().toIso8601String(),
    };
    final docRef = await _aiScanHistoryCol.add(data);
    return docRef.id.hashCode;
  }

  Future<List<Map<String, dynamic>>> getAiScanHistory(String userEmail) async {
    try {
      final snapshot = await _aiScanHistoryCol
          .where('user_email', isEqualTo: userEmail)
          .get();
      final list = snapshot.docs.map((d) => d.data()).toList();
      list.sort((a, b) =>
          (b['scanned_at'] as String).compareTo(a['scanned_at'] as String));
      return list;
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 10. REWARD REDEMPTION (ECO POINTS)
  // ==========================================

  Future<Map<String, dynamic>> redeemEcoPointsReward({
    required String userEmail,
    required RewardItem reward,
    String? targetAccount,
  }) async {
    final currentPoints = await getUserEcoPoints(userEmail);
    if (currentPoints < reward.pointsCost) {
      return {
        'success': false,
        'message': 'Poin Eco Anda tidak mencukupi.',
      };
    }

    final newPoints = currentPoints - reward.pointsCost;
    await _userWalletsCol.doc(userEmail).update({'eco_points': newPoints});
    userEcoPointsNotifier.value = newPoints;

    final code = 'TC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 30));

    final voucherId = (now.millisecondsSinceEpoch ~/ 1000) + (newPoints % 1000);
    final voucher = {
      'id': voucherId,
      'user_email': userEmail,
      'reward_id': reward.id,
      'title': reward.title,
      'category': reward.category.name,
      'merchant': reward.merchant,
      'nominal_value': reward.nominalValue,
      'voucher_code': code,
      'barcode': 'BC-$code',
      'points_used': reward.pointsCost,
      'status': 'active',
      'target_account': targetAccount,
      'terms': reward.terms.join('\n'),
      'instructions': reward.instructions,
      'redeemed_at': now.toIso8601String(),
      'expires_at': expiry.toIso8601String(),
    };
    await _userRedeemedRewardsCol.add(voucher);
    notifyHistoryChanged();

    final redeemedObj = RedeemedVoucher.fromMap(voucher);

    return {
      'success': true,
      'message': 'Penukaran reward berhasil!',
      'voucher_code': code,
      'new_points': newPoints,
      'voucher': redeemedObj,
    };
  }

  Future<List<RedeemedVoucher>> getUserRedeemedRewards(
      String userEmail) async {
    try {
      final snapshot = await _userRedeemedRewardsCol
          .where('user_email', isEqualTo: userEmail)
          .get();
      final list = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        if (!data.containsKey('id') || data['id'] == null) {
          data['id'] = d.id.hashCode;
        }
        return RedeemedVoucher.fromMap(data);
      }).toList();
      list.sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<int> getActiveVouchersCount(String userEmail) async {
    final list = await getUserRedeemedRewards(userEmail);
    return list.where((v) => v.isActive).length;
  }

  Future<void> markRedeemedVoucherAsUsed(int voucherId, String userEmail) async {
    try {
      final snapshot = await _userRedeemedRewardsCol
          .where('user_email', isEqualTo: userEmail)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = (data['id'] as num?)?.toInt() ?? doc.id.hashCode;
        if (id == voucherId) {
          await doc.reference.update({
            'status': 'used',
            'used_at': DateTime.now().toIso8601String(),
          });
          break;
        }
      }
      notifyHistoryChanged();
    } catch (e) {
      debugPrint('Error marking voucher as used: $e');
    }
  }

  Future<bool> useRedeemedVoucher(int id, String userEmail) async {
    await markRedeemedVoucherAsUsed(id, userEmail);
    return true;
  }

  static String generateVoucherCode(String merchant) {
    final clean = merchant.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final sub = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    final rnd = (DateTime.now().millisecondsSinceEpoch % 9000) + 1000;
    return 'TTC-$sub-$rnd';
  }

  static String generateBarcode13() {
    final rnd = (DateTime.now().millisecondsSinceEpoch % 900000000) + 100000000;
    return '9842$rnd';
  }
}
