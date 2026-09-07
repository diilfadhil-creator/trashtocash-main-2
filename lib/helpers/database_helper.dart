import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trashtocash/data/waste_seed_data.dart';
import 'package:trashtocash/models/reward_item_model.dart';
import 'package:trashtocash/models/user_model.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trashtocash.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  final StreamController<Map<String, dynamic>> _realtimeGpsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get realtimeGpsStream =>
      _realtimeGpsStreamController.stream;

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table (Customer & Driver Accounts)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'customer',
        phone TEXT,
        vehicle_type TEXT,
        vehicle_plate TEXT,
        address TEXT,
        bank_name TEXT,
        bank_account_number TEXT,
        bank_account_holder TEXT,
        ewallet_type TEXT,
        ewallet_number TEXT,
        ewallet_account_holder TEXT,
        preferred_payout_method TEXT DEFAULT 'ewallet',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Waste Items Table (Katalog Sampah Organik & Non-Organik Spesifik)
    await db.execute('''
      CREATE TABLE waste_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        sample_item TEXT,
        rate_per_kg REAL NOT NULL,
        eco_points INTEGER NOT NULL DEFAULT 10,
        icon_name TEXT,
        image_url TEXT,
        description TEXT,
        handling_tip TEXT
      )
    ''');

    // 3. Waste Pickups / Transactions Table (Data Pengambilan & Setoran Sampah)
    await db.execute('''
      CREATE TABLE waste_pickups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE NOT NULL,
        user_id INTEGER,
        user_email TEXT,
        waste_name TEXT NOT NULL,
        waste_type TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        rate_per_kg REAL NOT NULL,
        total_reward REAL NOT NULL,
        method TEXT NOT NULL,
        pickup_address TEXT,
        pickup_date TEXT,
        pickup_time TEXT,
        pickup_notes TEXT,
        drop_point_name TEXT,
        status TEXT NOT NULL,
        driver_id TEXT,
        driver_name TEXT,
        driver_fee REAL DEFAULT 15000.0,
        actual_weight_kg REAL,
        proof_photo_path TEXT,
        verification_pin TEXT DEFAULT '8842',
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Driver Wallet Transactions Table (Riwayat Komisi & Penarikan Saldo Driver)
    await db.execute('''
      CREATE TABLE driver_wallet_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id TEXT NOT NULL,
        transaction_id TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        channel TEXT,
        status TEXT NOT NULL DEFAULT 'success',
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Driver Profiles Table (Profil & Pengaturan Armada Driver)
    await db.execute('''
      CREATE TABLE driver_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        vehicle_plate TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        is_online INTEGER NOT NULL DEFAULT 1,
        wallet_balance REAL NOT NULL DEFAULT 145000.0,
        completed_pickups INTEGER NOT NULL DEFAULT 0,
        total_kg REAL NOT NULL DEFAULT 0.0,
        operational_radius REAL NOT NULL DEFAULT 5.0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 6. Realtime GPS Tracking Table (Penyimpanan Realtime Titik Koordinat & Status GPS Driver)
    await db.execute('''
      CREATE TABLE driver_realtime_gps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        driver_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed_kmph REAL NOT NULL DEFAULT 0.0,
        heading REAL NOT NULL DEFAULT 0.0,
        distance_km REAL NOT NULL DEFAULT 0.0,
        eta TEXT NOT NULL DEFAULT '6 Menit',
        progress REAL NOT NULL DEFAULT 0.0,
        source TEXT NOT NULL DEFAULT 'realtime_gps',
        updated_at TEXT NOT NULL
      )
    ''');

    // 7. User Wallets Table (Saldo, Poin Eco, & Rekap Setoran Pengguna)
    await db.execute('''
      CREATE TABLE user_wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        user_email TEXT NOT NULL UNIQUE,
        balance REAL NOT NULL DEFAULT 850.0,
        eco_points INTEGER NOT NULL DEFAULT 120,
        total_deposited_kg REAL NOT NULL DEFAULT 12.5,
        completed_deposits INTEGER NOT NULL DEFAULT 4,
        updated_at TEXT NOT NULL
      )
    ''');

    // 8. User Wallet Transactions Table (Riwayat Mutasi Saldo: Setor Sampah, Tarik Tunai, Bonus)
    await db.execute('''
      CREATE TABLE user_wallet_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        transaction_id TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        channel TEXT,
        status TEXT NOT NULL DEFAULT 'success',
        created_at TEXT NOT NULL
      )
    ''');

    // 9. Notifications Table (Pusat Notifikasi Aplikasi)
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        time TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        action_label TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 10. Drop Points Table (Bank Sampah & Drop Point Terdekat)
    await db.execute('''
      CREATE TABLE drop_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        hours TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Buka Sekarang',
        categories TEXT NOT NULL,
        map_x REAL NOT NULL DEFAULT 0.5,
        map_y REAL NOT NULL DEFAULT 0.5,
        phone TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 11. Chat Messages Table (Chat Dua Arah Kurir & Nasabah)
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        msg_id TEXT UNIQUE NOT NULL,
        sender_role TEXT NOT NULL,
        text TEXT NOT NULL,
        image_path TEXT,
        is_system INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL
      )
    ''');

    // 12. AI Vision Scan History Table (Riwayat Deteksi Kamera AI)
    await db.execute('''
      CREATE TABLE ai_scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        confidence REAL NOT NULL,
        weight_kg REAL NOT NULL,
        reward REAL NOT NULL,
        eco_points INTEGER NOT NULL,
        scanned_at TEXT NOT NULL
      )
    ''');

    // 13. User Redeemed Rewards / Vouchers Table (Voucher Belanja, Saldo E-Wallet, Pulsa, PLN)
    await db.execute('''
      CREATE TABLE user_redeemed_rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        reward_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        merchant TEXT NOT NULL,
        nominal_value TEXT NOT NULL,
        voucher_code TEXT NOT NULL,
        barcode TEXT NOT NULL,
        points_used INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        target_account TEXT,
        terms TEXT,
        instructions TEXT,
        redeemed_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        used_at TEXT
      )
    ''');

    // Seed Initial Catalog Data, User Wallet, Drop Points, & Notifications
    await _seedInitialWasteData(db);
    await _seedInitialUserWalletData(db);
    await _seedInitialDropPoints(db);
    await _seedInitialNotifications(db);
    await _seedInitialChatMessages(db);
    await _seedInitialRedeemedRewards(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS waste_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          sample_item TEXT,
          rate_per_kg REAL NOT NULL,
          eco_points INTEGER NOT NULL DEFAULT 10,
          icon_name TEXT,
          image_url TEXT,
          description TEXT,
          handling_tip TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS waste_pickups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id TEXT UNIQUE NOT NULL,
          user_id INTEGER,
          waste_name TEXT NOT NULL,
          waste_type TEXT NOT NULL,
          weight_kg REAL NOT NULL,
          rate_per_kg REAL NOT NULL,
          total_reward REAL NOT NULL,
          method TEXT NOT NULL,
          pickup_address TEXT,
          pickup_date TEXT,
          pickup_time TEXT,
          pickup_notes TEXT,
          drop_point_name TEXT,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add column handling_tip if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE waste_items ADD COLUMN handling_tip TEXT',
        );
      } catch (_) {}

      // Refresh specific waste data
      await db.delete('waste_items');
      await _insertAllDetailedWasteItems(db);
    }

    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'customer'",
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN vehicle_type TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN vehicle_plate TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE waste_pickups ADD COLUMN driver_id TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE waste_pickups ADD COLUMN driver_name TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE waste_pickups ADD COLUMN driver_fee REAL DEFAULT 15000.0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE waste_pickups ADD COLUMN actual_weight_kg REAL',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE waste_pickups ADD COLUMN proof_photo_path TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE waste_pickups ADD COLUMN verification_pin TEXT DEFAULT '8842'",
        );
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS driver_wallet_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driver_id TEXT NOT NULL,
          transaction_id TEXT,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          amount REAL NOT NULL,
          channel TEXT,
          status TEXT NOT NULL DEFAULT 'success',
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS driver_profiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          vehicle_plate TEXT NOT NULL,
          vehicle_type TEXT NOT NULL,
          is_online INTEGER NOT NULL DEFAULT 1,
          wallet_balance REAL NOT NULL DEFAULT 145000.0,
          completed_pickups INTEGER NOT NULL DEFAULT 0,
          total_kg REAL NOT NULL DEFAULT 0.0,
          operational_radius REAL NOT NULL DEFAULT 5.0,
          updated_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          user_email TEXT NOT NULL UNIQUE,
          balance REAL NOT NULL DEFAULT 850.0,
          eco_points INTEGER NOT NULL DEFAULT 120,
          total_deposited_kg REAL NOT NULL DEFAULT 12.5,
          completed_deposits INTEGER NOT NULL DEFAULT 4,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_wallet_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          transaction_id TEXT,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          amount REAL NOT NULL,
          channel TEXT,
          status TEXT NOT NULL DEFAULT 'success',
          created_at TEXT NOT NULL
        )
      ''');

      await _seedInitialUserWalletData(db);
    }

    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN bank_name TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN bank_account_number TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN bank_account_holder TEXT',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN ewallet_type TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN ewallet_number TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN ewallet_account_holder TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE users ADD COLUMN preferred_payout_method TEXT DEFAULT 'ewallet'",
        );
      } catch (_) {}
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          time TEXT NOT NULL,
          type TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          action_label TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS drop_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          hours TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'Buka Sekarang',
          categories TEXT NOT NULL,
          map_x REAL NOT NULL DEFAULT 0.5,
          map_y REAL NOT NULL DEFAULT 0.5,
          phone TEXT,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          msg_id TEXT UNIQUE NOT NULL,
          sender_role TEXT NOT NULL,
          text TEXT NOT NULL,
          image_path TEXT,
          is_system INTEGER NOT NULL DEFAULT 0,
          timestamp TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          item_name TEXT NOT NULL,
          category TEXT NOT NULL,
          confidence REAL NOT NULL,
          weight_kg REAL NOT NULL,
          reward REAL NOT NULL,
          eco_points INTEGER NOT NULL,
          scanned_at TEXT NOT NULL
        )
      ''');

      await _seedInitialDropPoints(db);
      await _seedInitialNotifications(db);
      await _seedInitialChatMessages(db);
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_redeemed_rewards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          reward_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          merchant TEXT NOT NULL,
          nominal_value TEXT NOT NULL,
          voucher_code TEXT NOT NULL,
          barcode TEXT NOT NULL,
          points_used INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          target_account TEXT,
          terms TEXT,
          instructions TEXT,
          redeemed_at TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          used_at TEXT
        )
      ''');

      await _seedInitialRedeemedRewards(db);
    }
  }

  // Seed default Organic and Non-Organic waste items
  Future<void> _seedInitialWasteData(Database db) async {
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM waste_items',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      await _insertAllDetailedWasteItems(db);
    }
  }

  Future<void> _insertAllDetailedWasteItems(Database db) async {
    for (final item in wasteSeedData) {
      await db.insert('waste_items', item);
    }
  }

  // Seed default User Wallet & sample initial transactions
  Future<void> _seedInitialUserWalletData(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_wallets',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) {
        final now = DateTime.now().toIso8601String();
        await db.insert('user_wallets', {
          'user_id': 1,
          'user_email': 'user@email.com',
          'balance': 850000.0,
          'eco_points': 120,
          'total_deposited_kg': 12.5,
          'completed_deposits': 4,
          'updated_at': now,
        });

        await db.insert('user_wallet_transactions', {
          'user_email': 'user@email.com',
          'transaction_id': 'TRX-DEP-2026052401',
          'type': 'deposit',
          'title': 'Deposit Plastik (PET)',
          'description': '2.5 kg • Drop-off di Bank Sampah Melati',
          'amount': 25000.0,
          'channel': 'Drop-off Mandiri',
          'status': 'success',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
        });
        await db.insert('user_wallet_transactions', {
          'user_email': 'user@email.com',
          'transaction_id': 'TRX-DEP-2026051802',
          'type': 'deposit',
          'title': 'Deposit Kardus & Kertas',
          'description': '4.0 kg • Dijemput Kurir Mitra',
          'amount': 32000.0,
          'channel': 'Jemput Sampah',
          'status': 'success',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 11))
              .toIso8601String(),
        });
        await db.insert('user_wallet_transactions', {
          'user_email': 'user@email.com',
          'transaction_id': 'TRX-WDL-2026051501',
          'type': 'withdrawal',
          'title': 'Penarikan ke Bank Central (BCA)',
          'description': 'Rekening: **** 1234 (A/N Faty)',
          'amount': -100000.0,
          'channel': 'Bank Central (BCA)',
          'status': 'success',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 14))
              .toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error seeding user wallet: $e');
    }
  }

  // Seed default Drop Points
  Future<void> _seedInitialDropPoints(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM drop_points',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) {
        final initialDropPoints = [
          {
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
          {
            'name': 'Eco Point Gandaria',
            'address': 'Jl. Gandaria Indah No. 12, Jakarta Selatan',
            'lat': -6.2440,
            'lng': 106.7860,
            'hours': 'Buka 08:30 - 18:00',
            'status': 'Buka Sekarang',
            'categories': 'Semua Jenis Sampah, Kompos, Elektronik',
            'map_x': 0.55,
            'map_y': 0.75,
            'phone': '0857-1122-3344',
            'is_active': 1,
          },
          {
            'name': 'Depo Daur Ulang Kebayoran',
            'address': 'Jl. Kebayoran Baru No. 88, Jakarta Selatan',
            'lat': -6.2480,
            'lng': 106.7980,
            'hours': 'Buka 08:00 - 16:00',
            'status': 'Buka Sekarang',
            'categories': 'Plastik, Logam, Baterai & Aki',
            'map_x': 0.20,
            'map_y': 0.70,
            'phone': '021-7229988',
            'is_active': 1,
          },
          {
            'name': 'Bank Sampah Berseri Senayan',
            'address': 'Jl. Asia Afrika Pintu 9, Gelora, Jakarta Pusat',
            'lat': -6.2210,
            'lng': 106.8020,
            'hours': 'Buka 09:00 - 17:00',
            'status': 'Buka Sekarang',
            'categories': 'Botol Plastik, Kaleng, Kertas HVS, Jelantah',
            'map_x': 0.80,
            'map_y': 0.50,
            'phone': '0813-4455-6677',
            'is_active': 1,
          },
        ];
        for (final dp in initialDropPoints) {
          await db.insert('drop_points', dp);
        }
      }
    } catch (e) {
      debugPrint('Error seeding drop points: $e');
    }
  }

  // Seed default Notifications
  Future<void> _seedInitialNotifications(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) {
        final initialNotifs = [
          {
            'user_email': 'user@email.com',
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
            'user_email': 'user@email.com',
            'title': 'Kurir Menuju Lokasi Penjemputan 🚚',
            'message':
                'Kurir Budi Santoso (B 1234 XYZ) sedang dalam perjalanan menuju Jl. Melati Blok C2 No. 15. Estimasi tiba dalam 12 menit.',
            'time': '1 jam yang lalu',
            'type': 'pickupStatus',
            'is_read': 0,
            'action_label': 'Lacak Penjemputan',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
          },
          {
            'user_email': 'user@email.com',
            'title': 'Bonus Poin Eco-Hero Mingguan! 🎁',
            'message':
                'Kumpulkan dan setorkan minimal 5 kg sampah plastik minggu ini untuk mendapatkan ekstra Rp 25.000.',
            'time': '4 jam yang lalu',
            'type': 'weeklyChallenge',
            'is_read': 0,
            'action_label': 'Setor Sekarang',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
          },
          {
            'user_email': 'user@email.com',
            'title': 'Penarikan Saldo Berhasil Diproses 💸',
            'message':
                'Penarikan saldo sebesar Rp 100.000 ke rekening Bank Central (BCA) ****1234 telah berhasil ditransfer.',
            'time': 'Kemarin, 16:40',
            'type': 'withdrawalSuccess',
            'is_read': 1,
            'action_label': 'Rincian Penarikan',
            'created_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },
        ];
        for (final notif in initialNotifs) {
          await db.insert('notifications', notif);
        }
      }
    } catch (e) {
      debugPrint('Error seeding notifications: $e');
    }
  }

  // Seed default Chat Messages
  Future<void> _seedInitialChatMessages(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) {
        await db.insert('chat_messages', {
          'msg_id': 'sys_1',
          'sender_role': 'system',
          'text':
              'Penjemputan dimulai. Pengguna terhubung dengan Mitra Kurir resmi TrashToCash.',
          'is_system': 1,
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 8))
              .toIso8601String(),
        });
        await db.insert('chat_messages', {
          'msg_id': 'msg_1',
          'sender_role': 'driver',
          'text':
              'Halo kak! Saya Budi Santoso, mitra kurir TrashToCash. Saya sedang menuju ke lokasi penjemputan ya (estimasi 10-15 menit). Mohon pastikan sampah sudah siap.',
          'is_system': 0,
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 6))
              .toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error seeding chat messages: $e');
    }
  }

  // 1. CRUD Katalog Sampah

  // Create sampah baru
  Future<int> insertWasteItem(WasteItemModel item) async {
    final db = await instance.database;
    return await db.insert('waste_items', item.toMap());
  }

  // Read Data diurutkan berdasarkan jenis sampah dan harga per kilogram.
  Future<List<WasteItemModel>> getAllWasteItems() async {
    final db = await instance.database;
    final result = await db.query(
      'waste_items',
      orderBy: 'type ASC, rate_per_kg DESC',
    );
    return result.map((map) => WasteItemModel.fromMap(map)).toList();
  }

  // Read sampah berdasarkan jenis organik/non-organik
  Future<List<WasteItemModel>> getWasteItemsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'waste_items',
      where: 'LOWER(type) = LOWER(?)',
      whereArgs: [type],
      orderBy: 'rate_per_kg DESC',
    );
    return result.map((map) => WasteItemModel.fromMap(map)).toList();
  }

  // Read jenis sampah berdasarkan ID
  Future<WasteItemModel?> getWasteItemById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'waste_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return WasteItemModel.fromMap(result.first);
    }
    return null;
  }

  // READ search berdasarkan kata kunci nama
  Future<List<WasteItemModel>> searchWasteItems(String keyword) async {
    final db = await instance.database;
    final cleanKeyword = '%${keyword.trim()}%';
    final result = await db.query(
      'waste_items',
      where: 'name LIKE ? OR sample_item LIKE ? OR description LIKE ?',
      whereArgs: [cleanKeyword, cleanKeyword, cleanKeyword],
      orderBy: 'type ASC, rate_per_kg DESC',
    );
    return result.map((map) => WasteItemModel.fromMap(map)).toList();
  }

  // Update katalog sampah
  Future<int> updateWasteItem(WasteItemModel item) async {
    if (item.id == null) return 0;
    final db = await instance.database;
    return await db.update(
      'waste_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete
  Future<int> deleteWasteItemsForMigration() async {
    final db = await instance.database;
    return await db.delete('waste_items');
  }

  // 2.CRUD DATA TRANSAKSI & PENJEMPUTAN (WASTE PICKUPS)

  // Create pengambilan/pejemputan sampah
  Future<int> insertWastePickup(WastePickupModel pickup) async {
    final db = await instance.database;
    final map = Map<String, dynamic>.from(pickup.toMap());
    if (!map.containsKey('user_email') ||
        map['user_email'] == null ||
        (map['user_email'] as String).isEmpty) {
      map['user_email'] = await _resolveUserEmail();
    }
    final res = await db.insert(
      'waste_pickups',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyHistoryChanged();
    return res;
  }

  // Read riwayat transaksi
  Future<List<WastePickupModel>> getAllWastePickups() async {
    final db = await instance.database;
    final result = await db.query('waste_pickups', orderBy: 'id DESC');
    return result.map((map) => WastePickupModel.fromMap(map)).toList();
  }

  // [READ] Ambil seluruh transaksi pengambilan/penyetoran sampah milik pengguna tertentu
  Future<List<WastePickupModel>> getWastePickupsByUser([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    if (userEmail == null || userEmail.trim().isEmpty) {
      final result = await db.query('waste_pickups', orderBy: 'id DESC');
      return result.map((map) => WastePickupModel.fromMap(map)).toList();
    }
    final normalizedEmail = userEmail.trim().toLowerCase();
    final result = await db.query(
      'waste_pickups',
      where:
          'LOWER(user_email) = ? OR user_email IS NULL OR user_email = "" OR ? = "user@email.com" OR LOWER(user_email) = "user@email.com"',
      whereArgs: [normalizedEmail, normalizedEmail],
      orderBy: 'id DESC',
    );
    if (result.isEmpty) {
      final allResult = await db.query('waste_pickups', orderBy: 'id DESC');
      return allResult.map((map) => WastePickupModel.fromMap(map)).toList();
    }
    return result.map((map) => WastePickupModel.fromMap(map)).toList();
  }

  // [READ] Ambil transaksi pengambilan sampah berdasarkan status
  Future<List<WastePickupModel>> getWastePickupsByType(String wasteType) async {
    final db = await instance.database;
    final result = await db.query(
      'waste_pickups',
      where: 'LOWER(waste_type) = LOWER(?)',
      whereArgs: [wasteType],
      orderBy: 'id DESC',
    );
    return result.map((map) => WastePickupModel.fromMap(map)).toList();
  }

  // Read Ambil satu transaksi berdasarkan ID
  Future<WastePickupModel?> getWastePickupById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'waste_pickups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return WastePickupModel.fromMap(result.first);
    }
    return null;
  }

  // Read Ambil satu transaksi berdasarkan transaction_id unik (contoh: 'TRX-8821')
  Future<WastePickupModel?> getWastePickupByTransactionId(
    String transactionId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'waste_pickups',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    if (result.isNotEmpty) {
      return WastePickupModel.fromMap(result.first);
    }
    return null;
  }

  // Update status penjemputan sampah berdasarkan ID
  Future<int> updatePickupStatus(int id, String status) async {
    final db = await instance.database;
    final res = await db.update(
      'waste_pickups',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyHistoryChanged();
    return res;
  }

  // Update status penjemputan sampah berdasarkan transaction_id
  Future<int> updatePickupStatusByTransactionId(
    String transactionId,
    String status,
  ) async {
    final db = await instance.database;
    final res = await db.update(
      'waste_pickups',
      {'status': status},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    notifyHistoryChanged();
    return res;
  }

  // Update status penjemputan pending/diproses menjadi Selesai saat transaksi diselesaikan
  Future<int> markLatestPickupAsSuccess() async {
    final db = await instance.database;
    final res = await db.rawUpdate('''
      UPDATE waste_pickups 
      SET status = 'Selesai' 
      WHERE status = 'Menunggu Penjemputan' OR status = 'Diproses'
    ''');
    notifyHistoryChanged();
    return res;
  }

  // update data transaksi penjemputan sampah
  Future<int> updateWastePickup(WastePickupModel pickup) async {
    if (pickup.id == null) return 0;
    final db = await instance.database;
    final res = await db.update(
      'waste_pickups',
      pickup.toMap(),
      where: 'id = ?',
      whereArgs: [pickup.id],
    );
    notifyHistoryChanged();
    return res;
  }

  Future<int> deleteWastePickupById(int id) async {
    final db = await instance.database;
    final res = await db.delete(
      'waste_pickups',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyHistoryChanged();
    return res;
  }

  Future<int> deleteWastePickupsForMigration() async {
    final db = await instance.database;
    final res = await db.delete('waste_pickups');
    notifyHistoryChanged();
    return res;
  }

  Future<int> deleteWastePickupByTransactionId(String transactionId) async {
    final db = await instance.database;
    final res = await db.delete(
      'waste_pickups',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    notifyHistoryChanged();
    return res;
  }

  // USER AUTHENTICATION

  // Register new user into SQLite
  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;

    // Check if email already exists
    final isExist = await isEmailRegistered(user.email);
    if (isExist) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain.');
    }

    final userId = await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    // Initialize user wallet in database
    await db.insert('user_wallets', {
      'user_id': userId,
      'user_email': user.email,
      'balance': 0.0,
      'eco_points': 0,
      'total_deposited_kg': 0.0,
      'completed_deposits': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return userId;
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Login user by verifying email and password
  Future<UserModel?> loginUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?) AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Login user by verifying email, password, and specific role ('customer' or 'driver')
  Future<UserModel?> loginUserWithRole(
    String email,
    String password,
    String role,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where:
          'LOWER(email) = LOWER(?) AND password = ? AND LOWER(role) = LOWER(?)',
      whereArgs: [email, password, role],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Get user details by email
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // ==========================================
  // 4. DRIVER PORTAL DATABASE PERSISTENCE APIS
  // ==========================================

  /// Insert Driver Wallet Transaction (Commission, Withdrawal, Bonus)
  Future<int> insertDriverWalletTransaction({
    required String driverId,
    String? transactionId,
    required String type, // 'commission', 'withdrawal', 'bonus'
    required String title,
    String? description,
    required double amount,
    String? channel,
    String status = 'success',
  }) async {
    final db = await instance.database;
    return await db.insert('driver_wallet_transactions', {
      'driver_id': driverId,
      'transaction_id': transactionId,
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'channel': channel,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get Driver Wallet Transactions
  Future<List<Map<String, dynamic>>> getDriverWalletTransactions({
    String driverId = 'T2C-8842',
  }) async {
    final db = await instance.database;
    return await db.query(
      'driver_wallet_transactions',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get Pending Waste Pickups for Driver Radar
  Future<List<WastePickupModel>> getPendingDriverPickups() async {
    final db = await instance.database;
    final result = await db.query(
      'waste_pickups',
      where:
          "method = 'Jemput Sampah' AND (status = 'Menunggu Penjemputan' OR status = 'Pending')",
      orderBy: 'created_at DESC',
    );
    return result.map((json) => WastePickupModel.fromMap(json)).toList();
  }

  /// Get Completed Pickups for Driver History
  Future<List<WastePickupModel>> getDriverCompletedPickups({
    String? driverId,
  }) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result;
    if (driverId != null && driverId.isNotEmpty) {
      result = await db.query(
        'waste_pickups',
        where: "status = 'Selesai' AND (driver_id = ? OR driver_id IS NULL)",
        whereArgs: [driverId],
        orderBy: 'created_at DESC',
      );
    } else {
      result = await db.query(
        'waste_pickups',
        where: "status = 'Selesai'",
        orderBy: 'created_at DESC',
      );
    }
    return result.map((json) => WastePickupModel.fromMap(json)).toList();
  }

  /// Driver Accepts a Waste Pickup Order
  Future<int> acceptWastePickupByDriver({
    required String transactionId,
    required String driverId,
    required String driverName,
  }) async {
    final db = await instance.database;
    return await db.update(
      'waste_pickups',
      {'status': 'Diproses', 'driver_id': driverId, 'driver_name': driverName},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Complete Waste Pickup by Driver with Actual Weight & Photo
  Future<int> completeWastePickupByDriver({
    required String transactionId,
    required double actualWeightKg,
    required double totalReward,
    String? proofPhotoPath,
    String? driverId,
  }) async {
    final db = await instance.database;
    final Map<String, dynamic> values = {
      'status': 'Selesai',
      'weight_kg': actualWeightKg,
      'actual_weight_kg': actualWeightKg,
      'total_reward': totalReward,
    };
    if (proofPhotoPath != null) {
      values['proof_photo_path'] = proofPhotoPath;
    }
    if (driverId != null) {
      values['driver_id'] = driverId;
    }

    final res = await db.update(
      'waste_pickups',
      values,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    notifyHistoryChanged();
    return res;
  }

  /// Save or Update Driver Profile in Database
  Future<void> saveDriverProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    await db.insert(
      'driver_profiles',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get Driver Profile from Database
  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    final db = await instance.database;
    final result = await db.query(
      'driver_profiles',
      where: 'id = ?',
      whereArgs: [driverId],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// 🛰️ Insert & Broadcast Realtime GPS Point into Database
  Future<int> insertOrUpdateDriverGps(Map<String, dynamic> gpsData) async {
    final db = await instance.database;
    final id = await db.insert(
      'driver_realtime_gps',
      gpsData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Broadcast through live SQLite stream
    _realtimeGpsStreamController.add(gpsData);
    return id;
  }

  /// 🛰️ Get Latest GPS Coordinates from Realtime Database
  Future<Map<String, dynamic>?> getLatestDriverGps(String transactionId) async {
    final db = await instance.database;
    final result = await db.query(
      'driver_realtime_gps',
      where: 'transaction_id = ?',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// 🛰️ Get GPS Waypoints History for Route Breadcrumb
  Future<List<Map<String, dynamic>>> getDriverGpsHistory(
    String transactionId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'driver_realtime_gps',
      where: 'transaction_id = ?',
      orderBy: 'id ASC',
    );
  }

  // ==========================================
  // 5. USER WALLET & BALANCE PERSISTENCE APIS
  // ==========================================

  /// Reaktif Notifier untuk Saldo, Poin, Avatar, dan Profil Pengguna secara Real-Time di seluruh UI
  static final ValueNotifier<double> userBalanceNotifier =
      ValueNotifier<double>(0.0);
  static final ValueNotifier<int> userEcoPointsNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<String> userAvatarNotifier = ValueNotifier<String>(
    '',
  );
  static final ValueNotifier<String> userNameNotifier = ValueNotifier<String>(
    'TrashToCash Member',
  );
  static final ValueNotifier<int> historyUpdateNotifier = ValueNotifier<int>(0);

  /// Pemicu instan notifikasi perubahan riwayat aktivitas di seluruh UI
  static void notifyHistoryChanged() {
    historyUpdateNotifier.value++;
  }

  /// Helper utility untuk memformat nominal angka menjadi format Rupiah yang mudah dipahami
  /// Contoh: 100000 -> "Rp 100.000", 25000 -> "Rp 25.000", 0 -> "Rp 0"
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
      // Bulatkan ke bilangan bulat agar angka nol ribuan jelas dan rapi (tanpa .00 atau ,00 yang membingungkan)
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

  /// Helper untuk mendapatkan email pengguna aktif dari SharedPreferences
  Future<String> _resolveUserEmail([String? providedEmail]) async {
    if (providedEmail != null && providedEmail.trim().isNotEmpty) {
      return providedEmail.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved =
          prefs.getString('email') ??
          prefs.getString('userEmail') ??
          prefs.getString('registeredEmail');
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return 'user@email.com';
  }

  /// Sinkronisasi Saldo & Poin dari Database ke Notifier Reaktif
  Future<Map<String, dynamic>> syncUserWalletFromDb([String? userEmail]) async {
    final email = await _resolveUserEmail(userEmail);
    final wallet = await getOrCreateUserWallet(email);
    final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
    final ecoPoints = (wallet['eco_points'] as num?)?.toInt() ?? 0;

    userBalanceNotifier.value = balance;
    userEcoPointsNotifier.value = ecoPoints;
    return wallet;
  }

  /// Dapatkan atau buat data User Wallet di SQLite
  Future<Map<String, dynamic>> getOrCreateUserWallet([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);

    final results = await db.query(
      'user_wallets',
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      final existing = results.first;
      var currentBal = (existing['balance'] as num?)?.toDouble() ?? 0.0;
      // Auto-migrate legacy balance stored in old units (< 1000 and > 0, e.g. 975 -> 975000)
      if (currentBal > 0 && currentBal < 1000) {
        currentBal = currentBal * 1000;
        await db.update(
          'user_wallets',
          {
            'balance': currentBal,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'LOWER(user_email) = LOWER(?)',
          whereArgs: [email],
        );
        try {
          await db.rawUpdate('''
            UPDATE user_wallet_transactions
            SET amount = amount * 1000
            WHERE ABS(amount) > 0 AND ABS(amount) < 1000
          ''');
        } catch (_) {}
        final updatedMap = Map<String, dynamic>.from(existing)
          ..['balance'] = currentBal;
        userBalanceNotifier.value = currentBal;
        return updatedMap;
      }
      userBalanceNotifier.value = currentBal;
      return existing;
    }

    final newWallet = {
      'user_email': email,
      'balance': 0.0,
      'eco_points': 0,
      'total_deposited_kg': 0.0,
      'completed_deposits': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final id = await db.insert(
      'user_wallets',
      newWallet,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final created = Map<String, dynamic>.from(newWallet)..['id'] = id;
    userBalanceNotifier.value = (created['balance'] as num).toDouble();
    userEcoPointsNotifier.value = (created['eco_points'] as num).toInt();
    return created;
  }

  /// 🔄 Hitung Ulang Saldo Nyata Berdasarkan Penjualan Sampah & Penarikan
  Future<Map<String, dynamic>> recalculateUserBalanceFromSales([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);

    // Hitung total reward dan kg dari transaksi penjualan/setoran sampah yang Selesai
    final pickupResult = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(weight_kg), 0) as total_kg,
        COALESCE(SUM(total_reward), 0) as total_pickup_reward,
        COUNT(*) as completed_count
      FROM waste_pickups
      WHERE LOWER(user_email) = LOWER(?)
        AND status = 'Selesai'
    ''',
      [email],
    );

    double totalKg = 0.0;
    int completedDeposits = 0;
    double pickupReward = 0.0;
    if (pickupResult.isNotEmpty) {
      totalKg = (pickupResult.first['total_kg'] as num?)?.toDouble() ?? 0.0;
      completedDeposits =
          (pickupResult.first['completed_count'] as num?)?.toInt() ?? 0;
      pickupReward =
          (pickupResult.first['total_pickup_reward'] as num?)?.toDouble() ??
          0.0;
    }

    // Hitung total penarikan
    final withdrawalResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(ABS(amount)), 0) as total_withdrawal
      FROM user_wallet_transactions
      WHERE LOWER(user_email) = LOWER(?) AND type = 'withdrawal'
    ''',
      [email],
    );
    double totalWithdrawal = 0.0;
    if (withdrawalResult.isNotEmpty) {
      totalWithdrawal =
          (withdrawalResult.first['total_withdrawal'] as num?)?.toDouble() ??
          0.0;
    }

    final netBalance = (pickupReward - totalWithdrawal).clamp(
      0.0,
      double.infinity,
    );
    final ecoPoints = (totalKg * 10).toInt();

    final nowStr = DateTime.now().toIso8601String();
    await db.rawInsert(
      '''
      INSERT INTO user_wallets (user_email, balance, eco_points, total_deposited_kg, completed_deposits, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_email) DO UPDATE SET
        balance = excluded.balance,
        eco_points = excluded.eco_points,
        total_deposited_kg = excluded.total_deposited_kg,
        completed_deposits = excluded.completed_deposits,
        updated_at = excluded.updated_at
    ''',
      [email, netBalance, ecoPoints, totalKg, completedDeposits, nowStr],
    );

    userBalanceNotifier.value = netBalance;
    userEcoPointsNotifier.value = ecoPoints;

    return {
      'user_email': email,
      'balance': netBalance,
      'eco_points': ecoPoints,
      'total_deposited_kg': totalKg,
      'completed_deposits': completedDeposits,
      'updated_at': nowStr,
    };
  }

  /// Ambil Total Saldo Pengguna dari Database SQLite
  Future<double> getUserBalance([String? userEmail]) async {
    final wallet = await getOrCreateUserWallet(userEmail);
    final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
    userBalanceNotifier.value = balance;
    return balance;
  }

  /// Ambil Total Eco-Points Pengguna dari Database SQLite
  Future<int> getUserEcoPoints([String? userEmail]) async {
    final wallet = await getOrCreateUserWallet(userEmail);
    final ecoPoints = (wallet['eco_points'] as num?)?.toInt() ?? 0;
    userEcoPointsNotifier.value = ecoPoints;
    return ecoPoints;
  }

  /// 💰 Tambah Saldo Pengguna saat Setor Sampah (Deposit) & Catat Riwayat Mutasi
  Future<double> creditUserBalance({
    String? userEmail,
    required double amount,
    required String title,
    String? description,
    String? transactionId,
    int ecoPoints = 0,
    double weightKg = 0.0,
    String channel = 'Setor Sampah',
  }) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final wallet = await getOrCreateUserWallet(email);

    final currentBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
    final currentPoints = (wallet['eco_points'] as num?)?.toInt() ?? 0;
    final currentWeight =
        (wallet['total_deposited_kg'] as num?)?.toDouble() ?? 0.0;
    final currentDeposits =
        (wallet['completed_deposits'] as num?)?.toInt() ?? 0;

    final newBalance = currentBalance + amount;
    final newPoints = currentPoints + ecoPoints;
    final newWeight = currentWeight + weightKg;
    final newDeposits = currentDeposits + 1;
    final nowStr = DateTime.now().toIso8601String();

    await db.update(
      'user_wallets',
      {
        'balance': newBalance,
        'eco_points': newPoints,
        'total_deposited_kg': newWeight,
        'completed_deposits': newDeposits,
        'updated_at': nowStr,
      },
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );

    await db.insert('user_wallet_transactions', {
      'user_email': email,
      'transaction_id': transactionId,
      'type': 'deposit',
      'title': title,
      'description':
          description ?? 'Setoran ${weightKg.toStringAsFixed(1)} kg ($channel)',
      'amount': amount,
      'channel': channel,
      'status': 'success',
      'created_at': nowStr,
    });

    // Update Reactive Notifiers seketika
    userBalanceNotifier.value = newBalance;
    userEcoPointsNotifier.value = newPoints;
    notifyHistoryChanged();

    return newBalance;
  }

  /// 💸 Tarik Saldo Pengguna (Debit / Withdrawal) & Catat Mutasi ke SQLite
  Future<bool> debitUserBalance({
    String? userEmail,
    required double amount,
    required String title,
    String? description,
    String? channel,
    String? transactionId,
  }) async {
    if (amount <= 0) return false;
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final wallet = await getOrCreateUserWallet(email);

    final currentBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
    if (currentBalance < amount) {
      return false; // Saldo tidak mencukupi
    }

    final newBalance = currentBalance - amount;
    final nowStr = DateTime.now().toIso8601String();

    await db.update(
      'user_wallets',
      {'balance': newBalance, 'updated_at': nowStr},
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );

    await db.insert('user_wallet_transactions', {
      'user_email': email,
      'transaction_id':
          transactionId ??
          'TRX-WDL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 12)}',
      'type': 'withdrawal',
      'title': title,
      'description': description,
      'amount': -amount,
      'channel': channel,
      'status': 'success',
      'created_at': nowStr,
    });

    // Update Reactive Notifier
    userBalanceNotifier.value = newBalance;
    notifyHistoryChanged();
    return true;
  }

  /// Ambil Riwayat Mutasi Dompet Pengguna
  Future<List<Map<String, dynamic>>> getUserWalletTransactions([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final normalizedEmail = email.trim().toLowerCase();

    final result = await db.query(
      'user_wallet_transactions',
      where:
          'LOWER(user_email) = LOWER(?) OR user_email IS NULL OR user_email = "" OR ? = "user@email.com" OR LOWER(user_email) = "user@email.com"',
      whereArgs: [normalizedEmail, normalizedEmail],
      orderBy: 'created_at DESC, id DESC',
    );
    if (result.isEmpty) {
      return await db.query(
        'user_wallet_transactions',
        orderBy: 'created_at DESC, id DESC',
      );
    }
    return result;
  }

  /// Delete satu transaksi dompet pengguna (opsional)
  Future<int> deleteUserWalletTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'user_wallet_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil informasi rekening bank dan dompet digital pengguna
  Future<Map<String, dynamic>> getUserPaymentAccounts([
    String? userEmail,
  ]) async {
    final email = await _resolveUserEmail(userEmail);
    final user = await getUserByEmail(email);
    if (user != null) {
      return {
        'bank_name': user.bankName,
        'bank_account_number': user.bankAccountNumber,
        'bank_account_holder': user.bankAccountHolder ?? user.name,
        'ewallet_type': user.ewalletType,
        'ewallet_number': user.ewalletNumber ?? user.phone,
        'ewallet_account_holder': user.ewalletAccountHolder ?? user.name,
        'preferred_payout_method': user.preferredPayoutMethod ?? 'ewallet',
      };
    }
    return {};
  }

  /// Update informasi rekening bank dan dompet digital pengguna
  Future<int> updateUserPaymentAccounts({
    required String email,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    String? ewalletType,
    String? ewalletNumber,
    String? ewalletAccountHolder,
    String? preferredPayoutMethod,
  }) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {
        if (bankName != null) 'bank_name': bankName,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankAccountHolder != null) 'bank_account_holder': bankAccountHolder,
        if (ewalletType != null) 'ewallet_type': ewalletType,
        if (ewalletNumber != null) 'ewallet_number': ewalletNumber,
        if (ewalletAccountHolder != null)
          'ewallet_account_holder': ewalletAccountHolder,
        if (preferredPayoutMethod != null)
          'preferred_payout_method': preferredPayoutMethod,
      },
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
    );
  }

  /// Update data profil pengguna di tabel users
  Future<int> updateUserProfile({
    required String email,
    String? name,
    String? phone,
    String? address,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      },
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
    );
  }

  // ==========================================
  // 6. NOTIFICATIONS APIS
  // ==========================================

  /// Ambil semua notifikasi untuk pengguna tertentu
  Future<List<Map<String, dynamic>>> getNotifications([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    return await db.query(
      'notifications',
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
      orderBy: 'id DESC',
    );
  }

  /// Tambah notifikasi baru ke database
  Future<int> insertNotification({
    String? userEmail,
    required String title,
    required String message,
    required String type,
    String? time,
    String? actionLabel,
  }) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final now = DateTime.now();
    return await db.insert('notifications', {
      'user_email': email,
      'title': title,
      'message': message,
      'time': time ?? 'Baru saja',
      'type': type,
      'is_read': 0,
      'action_label': actionLabel,
      'created_at': now.toIso8601String(),
    });
  }

  /// Tandai notifikasi sudah dibaca
  Future<int> markNotificationAsRead(int id) async {
    final db = await instance.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tandai semua notifikasi sudah dibaca
  Future<int> markAllNotificationsAsRead([String? userEmail]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );
  }

  /// Hapus satu notifikasi
  Future<int> deleteNotification(int id) async {
    final db = await instance.database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua notifikasi pengguna
  Future<int> clearAllNotifications([String? userEmail]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    return await db.delete(
      'notifications',
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );
  }

  // ==========================================
  // 7. DROP POINTS APIS
  // ==========================================

  /// Ambil semua bank sampah / drop points terdaftar
  Future<List<Map<String, dynamic>>> getAllDropPoints() async {
    final db = await instance.database;
    return await db.query(
      'drop_points',
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
  }

  /// Tambah drop point baru
  Future<int> insertDropPoint(Map<String, dynamic> dropPoint) async {
    final db = await instance.database;
    return await db.insert('drop_points', dropPoint);
  }

  // ==========================================
  // 8. CHAT MESSAGES APIS
  // ==========================================

  /// Ambil riwayat chat kurir & pengguna
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final db = await instance.database;
    return await db.query('chat_messages', orderBy: 'id ASC');
  }

  /// Simpan pesan chat baru
  Future<int> insertChatMessage({
    required String msgId,
    required String senderRole,
    required String text,
    String? imagePath,
    bool isSystem = false,
    DateTime? timestamp,
  }) async {
    final db = await instance.database;
    return await db.insert('chat_messages', {
      'msg_id': msgId,
      'sender_role': senderRole,
      'text': text,
      'image_path': imagePath,
      'is_system': isSystem ? 1 : 0,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Bersihkan riwayat chat
  Future<int> clearChatMessages() async {
    final db = await instance.database;
    return await db.delete('chat_messages');
  }

  // ==========================================
  // 9. AI VISION SCAN HISTORY APIS
  // ==========================================

  /// Simpan riwayat scan kamera AI
  Future<int> insertAiScanHistory({
    String? userEmail,
    required String itemName,
    required String category,
    required double confidence,
    required double weightKg,
    required double reward,
    required int ecoPoints,
  }) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final res = await db.insert('ai_scan_history', {
      'user_email': email,
      'item_name': itemName,
      'category': category,
      'confidence': confidence,
      'weight_kg': weightKg,
      'reward': reward,
      'eco_points': ecoPoints,
      'scanned_at': DateTime.now().toIso8601String(),
    });
    notifyHistoryChanged();
    return res;
  }

  /// Ambil riwayat scan kamera AI
  Future<List<Map<String, dynamic>>> getAiScanHistory([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    return await db.query(
      'ai_scan_history',
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
      orderBy: 'id DESC',
    );
  }

  // Seed default sample redeemed voucher
  Future<void> _seedInitialRedeemedRewards(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_redeemed_rewards',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) {
        final now = DateTime.now();
        final exp = now.add(const Duration(days: 30));
        await db.insert('user_redeemed_rewards', {
          'user_email': 'user@email.com',
          'reward_id': 1,
          'title': 'Voucher Belanja Alfamart Rp 25.000',
          'category': 'voucher_belanja',
          'merchant': 'Alfamart',
          'nominal_value': 'Rp 25.000',
          'voucher_code': 'TTC-ALFA-9842-8821',
          'barcode': '9842109842109',
          'points_used': 50,
          'status': 'active',
          'target_account': null,
          'terms': 'Berlaku di seluruh gerai Alfamart. Tidak dapat diuangkan.',
          'instructions':
              'Tunjukkan barcode voucher ke kasir Alfamart saat pembayaran.',
          'redeemed_at': now
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'expires_at': exp.toIso8601String(),
          'used_at': null,
        });
      }
    } catch (e) {
      debugPrint('Error seeding redeemed rewards: $e');
    }
  }

  // ==========================================
  // 10. POINT REDEMPTION & REWARDS APIS
  // ==========================================

  /// Generate Voucher Code unik dengan prefix brand
  static String generateVoucherCode(String merchant) {
    final cleanMerchant = merchant
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    final prefix = cleanMerchant.length >= 4
        ? cleanMerchant.substring(0, 4)
        : cleanMerchant.padRight(4, 'X');
    final rand = Random();
    final part1 = (1000 + rand.nextInt(9000)).toString();
    final part2 = (1000 + rand.nextInt(9000)).toString();
    return 'TTC-$prefix-$part1-$part2';
  }

  /// Generate Barcode 13 digit angka untuk scanner kasir
  static String generateBarcode13() {
    final rand = Random();
    final buffer = StringBuffer('9842'); // Prefix TrashToCash
    for (int i = 0; i < 9; i++) {
      buffer.write(rand.nextInt(10).toString());
    }
    return buffer.toString();
  }

  /// 🎁 Tukar Eco-Points dengan Voucher Belanja, Saldo E-Wallet, Pulsa, atau Hadiah
  Future<Map<String, dynamic>> redeemEcoPointsReward({
    String? userEmail,
    required RewardItem reward,
    String? targetAccount,
  }) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final wallet = await getOrCreateUserWallet(email);

    final currentPoints = (wallet['eco_points'] as num?)?.toInt() ?? 0;
    if (currentPoints < reward.pointsCost) {
      return {
        'success': false,
        'message':
            'Eco-Points Anda ($currentPoints Poin) tidak mencukupi untuk menukar ${reward.title} (${reward.pointsCost} Poin). Kurang ${reward.pointsCost - currentPoints} Poin lagi!',
      };
    }

    final newPoints = currentPoints - reward.pointsCost;
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: reward.validityDays));
    final nowStr = now.toIso8601String();
    final voucherCode = generateVoucherCode(reward.merchant);
    final barcode = generateBarcode13();

    // 1. Potong Eco-Points di user_wallets
    await db.update(
      'user_wallets',
      {'eco_points': newPoints, 'updated_at': nowStr},
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
    );

    // 2. Simpan Voucher ke tabel user_redeemed_rewards
    final voucherMap = {
      'user_email': email,
      'reward_id': reward.id,
      'title': reward.title,
      'category': reward.category.id,
      'merchant': reward.merchant,
      'nominal_value': reward.nominalValue,
      'voucher_code': voucherCode,
      'barcode': barcode,
      'points_used': reward.pointsCost,
      'status': 'active',
      'target_account': targetAccount,
      'terms': reward.terms.join('\n• '),
      'instructions': reward.instructions,
      'redeemed_at': nowStr,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': null,
    };

    final voucherId = await db.insert('user_redeemed_rewards', voucherMap);
    final createdVoucher = Map<String, dynamic>.from(voucherMap)
      ..['id'] = voucherId;

    // 3. Catat riwayat mutasi dompet (Points Exchange)
    await db.insert('user_wallet_transactions', {
      'user_email': email,
      'transaction_id':
          'TRX-RWD-${now.millisecondsSinceEpoch.toString().substring(5, 12)}',
      'type': 'reward_redemption',
      'title': 'Tukar Poin: ${reward.merchant}',
      'description':
          'Penukaran ${reward.pointsCost} Eco-Points (${reward.nominalValue} - $voucherCode)',
      'amount': 0.0,
      'channel': reward.category.label,
      'status': 'success',
      'created_at': nowStr,
    });

    // 4. Tambah Notifikasi Pengguna
    await insertNotification(
      userEmail: email,
      title: 'Voucher Berhasil Ditukar! 🎁',
      message:
          'Selamat! Penukaran ${reward.pointsCost} Poin untuk "${reward.title}" berhasil. Kode voucher: $voucherCode.',
      type: 'rewardDeposit',
      actionLabel: 'Lihat Voucher',
    );

    // 5. Update Reactive Notifier Realtime di seluruh UI
    userEcoPointsNotifier.value = newPoints;
    notifyHistoryChanged();

    return {
      'success': true,
      'message':
          'Selamat! Anda berhasil menukar ${reward.pointsCost} Eco-Points untuk ${reward.title}.',
      'voucher': RedeemedVoucher.fromMap(createdVoucher),
      'remaining_points': newPoints,
    };
  }

  /// Ambil Semua Voucher yang Pernah Ditukarkan Pengguna
  Future<List<RedeemedVoucher>> getUserRedeemedRewards([
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);

    final results = await db.query(
      'user_redeemed_rewards',
      where: 'LOWER(user_email) = LOWER(?)',
      whereArgs: [email],
      orderBy: 'id DESC',
    );

    return results.map((m) => RedeemedVoucher.fromMap(m)).toList();
  }

  /// Tandai Voucher Sudah Dipakai di Kasir / Merchant
  Future<bool> markRedeemedVoucherAsUsed(
    int voucherId, [
    String? userEmail,
  ]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final nowStr = DateTime.now().toIso8601String();

    final count = await db.update(
      'user_redeemed_rewards',
      {'status': 'used', 'used_at': nowStr},
      where: 'id = ? AND LOWER(user_email) = LOWER(?)',
      whereArgs: [voucherId, email],
    );

    notifyHistoryChanged();
    return count > 0;
  }

  /// Hitung Jumlah Voucher Aktif yang Tersedia
  Future<int> getActiveVouchersCount([String? userEmail]) async {
    final db = await instance.database;
    final email = await _resolveUserEmail(userEmail);
    final nowStr = DateTime.now().toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM user_redeemed_rewards
      WHERE LOWER(user_email) = LOWER(?)
        AND status = 'active'
        AND expires_at > ?
    ''',
      [email, nowStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database connection
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
