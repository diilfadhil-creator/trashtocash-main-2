import 'package:flutter/material.dart';

/// Kategori Hadiah / Penukaran Poin
enum RewardCategory {
  all,
  voucherBelanja,
  ewalletPulsa,
  tagihanPln,
  merchandise,
  donasi,
}

extension RewardCategoryExtension on RewardCategory {
  String get id {
    switch (this) {
      case RewardCategory.all:
        return 'all';
      case RewardCategory.voucherBelanja:
        return 'voucher_belanja';
      case RewardCategory.ewalletPulsa:
        return 'ewallet_pulsa';
      case RewardCategory.tagihanPln:
        return 'tagihan_pln';
      case RewardCategory.merchandise:
        return 'merchandise';
      case RewardCategory.donasi:
        return 'donasi';
    }
  }

  String get label {
    switch (this) {
      case RewardCategory.all:
        return 'Semua Hadiah';
      case RewardCategory.voucherBelanja:
        return 'Voucher Belanja';
      case RewardCategory.ewalletPulsa:
        return 'E-Wallet & Pulsa';
      case RewardCategory.tagihanPln:
        return 'Listrik PLN';
      case RewardCategory.merchandise:
        return 'Merchandise Eco';
      case RewardCategory.donasi:
        return 'Donasi Hijau';
    }
  }

  String get shortLabel {
    switch (this) {
      case RewardCategory.all:
        return 'Semua';
      case RewardCategory.voucherBelanja:
        return '🛒 Belanja';
      case RewardCategory.ewalletPulsa:
        return '📱 E-Wallet';
      case RewardCategory.tagihanPln:
        return '⚡ Listrik';
      case RewardCategory.merchandise:
        return '🌱 Eco Goods';
      case RewardCategory.donasi:
        return '🌳 Donasi';
    }
  }

  IconData get icon {
    switch (this) {
      case RewardCategory.all:
        return Icons.grid_view_rounded;
      case RewardCategory.voucherBelanja:
        return Icons.shopping_bag_outlined;
      case RewardCategory.ewalletPulsa:
        return Icons.phone_android_rounded;
      case RewardCategory.tagihanPln:
        return Icons.bolt_rounded;
      case RewardCategory.merchandise:
        return Icons.eco_outlined;
      case RewardCategory.donasi:
        return Icons.volunteer_activism_outlined;
    }
  }
}

/// Definisi Model Katalog Hadiah Penukaran Poin
class RewardItem {
  final int id;
  final String title;
  final RewardCategory category;
  final int pointsCost;
  final String nominalValue;
  final String merchant;
  final Color brandColor;
  final IconData icon;
  final String description;
  final List<String> terms;
  final String? badge;
  final int stock;
  final int validityDays;
  final String instructions;
  final bool requiresTargetInput; // e.g. Phone number for e-wallet or PLN ID
  final String? targetInputLabel;
  final String? targetInputHint;

  const RewardItem({
    required this.id,
    required this.title,
    required this.category,
    required this.pointsCost,
    required this.nominalValue,
    required this.merchant,
    required this.brandColor,
    required this.icon,
    required this.description,
    required this.terms,
    this.badge,
    this.stock = 99,
    this.validityDays = 30,
    required this.instructions,
    this.requiresTargetInput = false,
    this.targetInputLabel,
    this.targetInputHint,
  });

  /// Daftar lengkap katalog reward & voucher bawaan
  static const List<RewardItem> defaultCatalog = [
    // 🛒 1. VOUCHER BELANJA
    RewardItem(
      id: 1,
      title: 'Voucher Belanja Alfamart Rp 25.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 50,
      nominalValue: 'Rp 25.000',
      merchant: 'Alfamart',
      brandColor: Color(0xFFD32F2F),
      icon: Icons.storefront_rounded,
      badge: 'Terlaris 🔥',
      stock: 120,
      validityDays: 30,
      description: 'Potongan belanja langsung tanpa min. transaksi di seluruh gerai Alfamart Indonesia.',
      instructions: 'Tunjukkan kode barcode/QR voucher kepada kasir Alfamart saat melakukan pembayaran.',
      terms: [
        'Berlaku di seluruh gerai Alfamart di seluruh Indonesia.',
        'Dapat digabungkan dengan promo belanja lainnya.',
        'Tidak dapat diuangkan kembali.',
        'Berlaku selama 30 hari sejak tanggal penukaran.',
      ],
    ),
    RewardItem(
      id: 2,
      title: 'Voucher Belanja Alfamart Rp 50.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 95,
      nominalValue: 'Rp 50.000',
      merchant: 'Alfamart',
      brandColor: Color(0xFFD32F2F),
      icon: Icons.storefront_rounded,
      badge: 'Diskon Poin ⭐',
      stock: 85,
      validityDays: 30,
      description: 'Hemat 5 poin! Voucher belanja senilai Rp 50.000 untuk kebutuhan harian keluarga di Alfamart.',
      instructions: 'Tunjukkan kode barcode/QR voucher kepada kasir Alfamart saat melakukan pembayaran.',
      terms: [
        'Berlaku di seluruh gerai Alfamart Indonesia.',
        'Berlaku untuk semua item termasuk sembako & perlengkapan rumah.',
        'Satu voucher berlaku untuk satu transaksi.',
        'Masa aktif 30 hari sejak penukaran.',
      ],
    ),
    RewardItem(
      id: 3,
      title: 'Voucher Belanja Indomaret Rp 25.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 50,
      nominalValue: 'Rp 25.000',
      merchant: 'Indomaret',
      brandColor: Color(0xFF1565C0),
      icon: Icons.shopping_basket_rounded,
      badge: 'Populer ✨',
      stock: 150,
      validityDays: 30,
      description: 'Voucher digital belanja Indomaret untuk jajan, sembako, dan keperluan sehari-hari.',
      instructions: 'Buka menu i-Saku atau scan barcode voucher pada mesin kasir Indomaret saat transaksi.',
      terms: [
        'Berlaku di seluruh Indomaret & Indomaret Point.',
        'Tanpa batas minimal transaksi belanja.',
        'Tidak dapat ditukar dengan uang tunai.',
        'Masa aktif 30 hari dari tanggal klaim.',
      ],
    ),
    RewardItem(
      id: 4,
      title: 'Voucher Belanja Indomaret Rp 50.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 95,
      nominalValue: 'Rp 50.000',
      merchant: 'Indomaret',
      brandColor: Color(0xFF1565C0),
      icon: Icons.shopping_basket_rounded,
      badge: 'Hemat Poin',
      stock: 90,
      validityDays: 30,
      description: 'Potongan Rp 50.000 di seluruh gerai Indomaret dengan hemat 5 Eco-Points.',
      instructions: 'Tunjukkan barcode voucher di aplikasi TrashToCash pada kasir Indomaret.',
      terms: [
        'Berlaku di seluruh jaringan Indomaret nasional.',
        'Bisa digunakan untuk semua jenis produk fisik.',
        'Satu voucher untuk satu struk pembayaran.',
        'Masa aktif 30 hari.',
      ],
    ),
    RewardItem(
      id: 5,
      title: 'Voucher Tokopedia Diskon Rp 20.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 40,
      nominalValue: 'Rp 20.000',
      merchant: 'Tokopedia',
      brandColor: Color(0xFF00AA5B),
      icon: Icons.shopping_cart_rounded,
      badge: 'Online Shopping',
      stock: 200,
      validityDays: 14,
      description: 'Kode promo potongan belanja online di Tokopedia Official Store & Power Merchant.',
      instructions: 'Salin kode promo dan masukkan pada kolom Promo di halaman checkout aplikasi Tokopedia.',
      terms: [
        'Minimal transaksi belanja Rp 50.000 di Tokopedia.',
        'Berlaku untuk Power Merchant & Official Store.',
        'Berlaku 14 hari sejak penukaran.',
      ],
    ),
    RewardItem(
      id: 6,
      title: 'Voucher Shopee Belanja & Gratis Ongkir Rp 25.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 50,
      nominalValue: 'Rp 25.000',
      merchant: 'Shopee',
      brandColor: Color(0xFFEE4D2D),
      icon: Icons.local_mall_rounded,
      badge: 'Online Shop',
      stock: 180,
      validityDays: 14,
      description: 'Diskon belanja Rp 25.000 + subsidi ongkos kirim di marketplace Shopee.',
      instructions: 'Masukkan kode voucher di kolom "Voucher Shopee" pada halaman keranjang/checkout.',
      terms: [
        'Berlaku untuk pembelian produk di Shopee Mall & Star Seller.',
        'Minimal transaksi Rp 40.000.',
        'Berlaku 14 hari sejak klaim.',
      ],
    ),
    RewardItem(
      id: 7,
      title: 'Voucher Super Indo Supermarket Rp 50.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 100,
      nominalValue: 'Rp 50.000',
      merchant: 'Super Indo',
      brandColor: Color(0xFFE53935),
      icon: Icons.store_mall_directory_rounded,
      badge: 'Fresh & Groceries',
      stock: 60,
      validityDays: 45,
      description: 'Voucher belanja sayuran segar, buah, daging, dan kebutuhan dapur di Super Indo.',
      instructions: 'Tunjukkan kode voucher digital kepada kasir Super Indo sebelum melakukan pembayaran.',
      terms: [
        'Berlaku di seluruh gerai Super Indo di Indonesia.',
        'Berlaku untuk semua item termasuk fresh food & groceries.',
        'Masa aktif 45 hari sejak tanggal penukaran.',
      ],
    ),
    RewardItem(
      id: 8,
      title: 'Voucher Kopi Kenangan / Janji Jiwa Rp 20.000',
      category: RewardCategory.voucherBelanja,
      pointsCost: 35,
      nominalValue: 'Rp 20.000',
      merchant: 'Kopi Kenangan',
      brandColor: Color(0xFF6D4C41),
      icon: Icons.coffee_rounded,
      badge: 'Minuman Segar ☕',
      stock: 75,
      validityDays: 30,
      description: 'Nikmati kopi dan minuman favorit ramah lingkungan dengan potongan langsung Rp 20.000.',
      instructions: 'Masukkan kode voucher di aplikasi Kopi Kenangan atau tunjukkan saat pesan di outlet.',
      terms: [
        'Berlaku untuk semua menu minuman ukuran Reguler/Large.',
        'Berlaku di seluruh outlet Kopi Kenangan & Janji Jiwa.',
        'Masa aktif 30 hari.',
      ],
    ),

    // 📱 2. E-WALLET & PULSA / DATA
    RewardItem(
      id: 9,
      title: 'Top Up Saldo GoPay Rp 20.000',
      category: RewardCategory.ewalletPulsa,
      pointsCost: 45,
      nominalValue: 'Rp 20.000',
      merchant: 'GoPay',
      brandColor: Color(0xFF00AED6),
      icon: Icons.account_balance_wallet_rounded,
      badge: 'Instan ⚡',
      stock: 300,
      validityDays: 365,
      description: 'Top up saldo GoPay instan langsung ke nomor HP akun Gojek / GoPay kamu.',
      instructions: 'Saldo akan langsung ditransfer otomatis ke akun GoPay terdaftar dalam hitungan detik.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor HP Akun GoPay',
      targetInputHint: 'Contoh: 081234567890',
      terms: [
        'Pastikan nomor HP akun GoPay aktif dan sesuai.',
        'Saldo langsung masuk ke akun tanpa potongan biaya admin.',
        'Non-refundable jika nomor salah dimasukkan.',
      ],
    ),
    RewardItem(
      id: 10,
      title: 'Top Up Saldo DANA Rp 25.000',
      category: RewardCategory.ewalletPulsa,
      pointsCost: 55,
      nominalValue: 'Rp 25.000',
      merchant: 'DANA',
      brandColor: Color(0xFF118EEA),
      icon: Icons.account_balance_wallet_rounded,
      badge: 'Instan ⚡',
      stock: 250,
      validityDays: 365,
      description: 'Saldo dompet digital DANA Rp 25.000 untuk transaksi QRIS, transfer, & bayar tagihan.',
      instructions: 'Saldo akan otomatis dikreditkan ke nomor DANA yang kamu masukkan.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor HP Akun DANA',
      targetInputHint: 'Contoh: 081234567890',
      terms: [
        'Akun DANA harus berstatus aktif.',
        'Proses pengisian saldo instan 1-5 menit.',
        'Bebas biaya administrasi top up.',
      ],
    ),
    RewardItem(
      id: 11,
      title: 'Pulsa All Operator Rp 25.000',
      category: RewardCategory.ewalletPulsa,
      pointsCost: 50,
      nominalValue: 'Rp 25.000',
      merchant: 'Telkomsel / Indosat / XL / Tri',
      brandColor: Color(0xFFE64A19),
      icon: Icons.phone_in_talk_rounded,
      badge: 'Semua Operator',
      stock: 400,
      validityDays: 365,
      description: 'Pulsa reguler Rp 25.000 untuk Telkomsel, Indosat Ooredoo, XL Axiata, Tri, dan Smartfren.',
      instructions: 'Pulsa akan langsung terisi ke nomor ponsel yang diisi saat penukaran poin.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor Handphone Tujuan',
      targetInputHint: 'Contoh: 0852xxxxxxxx',
      terms: [
        'Berlaku untuk semua operator seluler di Indonesia.',
        'Menambah masa aktif kartu seluler sesuai ketentuan operator.',
        'Pengisian otomatis real-time.',
      ],
    ),
    RewardItem(
      id: 12,
      title: 'Paket Data Internet 5 GB (30 Hari)',
      category: RewardCategory.ewalletPulsa,
      pointsCost: 60,
      nominalValue: '5 GB Kuota',
      merchant: 'All Operator',
      brandColor: Color(0xFF3F51B5),
      icon: Icons.wifi_rounded,
      badge: 'Kuota Utama',
      stock: 200,
      validityDays: 30,
      description: 'Paket kuota internet 5 GB 24 jam penuh di semua jaringan (4G/5G) selama 30 hari.',
      instructions: 'Paket data akan otomatis diaktifkan pada nomor handphone yang kamu masukkan.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor HP Penerima Kuota',
      targetInputHint: 'Contoh: 0813xxxxxxxx',
      terms: [
        'Kuota utama 24 jam tanpa pembagian waktu / aplikasi.',
        'Masa aktif paket 30 hari sejak injeksi data berhasil.',
        'Pastikan nomor dalam masa aktif (tidak tenggang).',
      ],
    ),

    // ⚡ 3. LISTRIK PLN & UTILITAS
    RewardItem(
      id: 13,
      title: 'Token Listrik PLN Prabayar Rp 20.000',
      category: RewardCategory.tagihanPln,
      pointsCost: 45,
      nominalValue: 'Rp 20.000',
      merchant: 'PLN Persero',
      brandColor: Color(0xFFFBC02D),
      icon: Icons.electric_bolt_rounded,
      badge: 'Utilitas ⚡',
      stock: 350,
      validityDays: 180,
      description: '20 Digit Stroom Token Listrik PLN prabayar untuk penerangan rumah hemat energi.',
      instructions: 'Masukkan 20 digit nomor token yang tertera pada layar Voucher Saya ke meteran kWh rumah.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor Meter / ID Pelanggan PLN',
      targetInputHint: 'Contoh: 32019842109 (11-12 digit)',
      terms: [
        'Berlaku untuk seluruh ID Pelanggan PLN Prabayar di Indonesia.',
        'Jumlah kWh disesuaikan dengan tarif daya golongan pelanggan PLN.',
        'Token dapat diinput kapan saja ke meteran PLN.',
      ],
    ),
    RewardItem(
      id: 14,
      title: 'Token Listrik PLN Prabayar Rp 50.000',
      category: RewardCategory.tagihanPln,
      pointsCost: 100,
      nominalValue: 'Rp 50.000',
      merchant: 'PLN Persero',
      brandColor: Color(0xFFFBC02D),
      icon: Icons.electric_bolt_rounded,
      badge: 'Hemat Energi',
      stock: 200,
      validityDays: 180,
      description: 'Stroom Token Listrik PLN Rp 50.000 siap pakai langsung di meteran listrik rumah.',
      instructions: 'Tekan 20 digit nomor token di keypad meteran listrik Anda lalu tekan Enter.',
      requiresTargetInput: true,
      targetInputLabel: 'Nomor Meter / ID Pelanggan PLN',
      targetInputHint: 'Contoh: 14098234112',
      terms: [
        'Berlaku untuk semua golongan daya kWh listrik prabayar.',
        'Token tidak memiliki tanggal kedaluwarsa sebelum diinput.',
        'Bebas biaya admin PLN.',
      ],
    ),

    // 🌱 4. MERCHANDISE RAMAH LINGKUNGAN
    RewardItem(
      id: 15,
      title: 'Exclusive TrashToCash Eco-Totebag Kanvas',
      category: RewardCategory.merchandise,
      pointsCost: 75,
      nominalValue: '1 Pcs Totebag',
      merchant: 'TrashToCash Official',
      brandColor: Color(0xFF0D6938),
      icon: Icons.shopping_bag_outlined,
      badge: 'Official Merchandise 🌱',
      stock: 50,
      validityDays: 60,
      description: 'Tas belanja kanvas tebal ramah lingkungan pengganti kantong plastik sekali pakai.',
      instructions: 'Dapat diambil langsung di Drop Point TrashToCash terdekat atau dikirim via kurir penjemputan.',
      terms: [
        'Bahan kanvas katun organik premium ramah lingkungan kuat hingga 15 kg.',
        'Klaim pengambilan di seluruh Drop Point resmi TrashToCash.',
        'Tunjukkan kode penukaran kepada petugas Drop Point.',
      ],
    ),
    RewardItem(
      id: 16,
      title: 'Stainless Steel Eco-Tumbler 500ml',
      category: RewardCategory.merchandise,
      pointsCost: 120,
      nominalValue: '1 Pcs Tumbler 500ml',
      merchant: 'TrashToCash Official',
      brandColor: Color(0xFF00897B),
      icon: Icons.local_drink_rounded,
      badge: 'Eksklusif ⭐',
      stock: 35,
      validityDays: 60,
      description: 'Tumbler tahan suhu panas & dingin 12 jam, mengurangi sampah botol plastik sekali pakai.',
      instructions: 'Ambil di Drop Point terdekat atau minta kurir antarkan saat jadwal penjemputan sampah berikutnya.',
      terms: [
        'Stainless Steel 304 Food Grade bebas BPA.',
        'Desain eksklusif logo TrashToCash Eco-Hero.',
        'Masa klaim 60 hari sejak penukaran poin.',
      ],
    ),
    RewardItem(
      id: 17,
      title: 'Paket Bibit Sayur Organik & Pupuk Kompos',
      category: RewardCategory.merchandise,
      pointsCost: 40,
      nominalValue: '1 Paket Tanam',
      merchant: 'Bank Sampah Mandiri',
      brandColor: Color(0xFF43A047),
      icon: Icons.yard_rounded,
      badge: 'Urban Farming 🌿',
      stock: 80,
      validityDays: 60,
      description: 'Paket 5 jenis bibit sayuran hijau (kangkung, bayam, cabai, tomat) + 2kg kompos organik.',
      instructions: 'Ambil paket bibit tanaman di mitra Bank Sampah terdekat dengan menunjukkan kode voucher.',
      terms: [
        'Kompos hasil fermentasi sampah organik nasabah TrashToCash.',
        'Bibit unggul mudah tumbuh di pot / polybag perumahan.',
        'Bebas biaya tambahan.',
      ],
    ),

    // 🌳 5. DONASI HIJAU
    RewardItem(
      id: 18,
      title: 'Donasi Tanam 1 Bibit Pohon Mangrove Pesisir',
      category: RewardCategory.donasi,
      pointsCost: 30,
      nominalValue: '1 Pohon Mangrove',
      merchant: 'Yayasan Lindungi Hutan',
      brandColor: Color(0xFF1B5E20),
      icon: Icons.forest_rounded,
      badge: 'Aksi Nyata Bumi 🌏',
      stock: 999,
      validityDays: 365,
      description: 'Tukarkan poin Anda untuk menanam 1 pohon mangrove di pesisir guna cegah abrasi & serap karbon.',
      instructions: 'Sertifikat digital atas nama Anda akan otomatis diterbitkan di aplikasi.',
      terms: [
        'Ditanam secara berkala oleh relawan pelestarian pesisir.',
        'Dapatkan e-sertifikat kontribusi hijau di profil TrashToCash.',
        'Poin langsung disalurkan 100% untuk program konservasi.',
      ],
    ),
  ];
}

/// Model Voucher yang Sudah Berhasil Ditukarkan oleh Pengguna
class RedeemedVoucher {
  final int id;
  final String userEmail;
  final int rewardId;
  final String title;
  final String category;
  final String merchant;
  final String nominalValue;
  final String voucherCode;
  final String barcode;
  final int pointsUsed;
  final String status; // 'active', 'used', 'expired'
  final String? targetAccount;
  final String? terms;
  final String? instructions;
  final String redeemedAt;
  final String expiresAt;
  final String? usedAt;

  RedeemedVoucher({
    required this.id,
    required this.userEmail,
    required this.rewardId,
    required this.title,
    required this.category,
    required this.merchant,
    required this.nominalValue,
    required this.voucherCode,
    required this.barcode,
    required this.pointsUsed,
    required this.status,
    this.targetAccount,
    this.terms,
    this.instructions,
    required this.redeemedAt,
    required this.expiresAt,
    this.usedAt,
  });

  bool get isActive => status.toLowerCase() == 'active' && !isExpired;
  bool get isUsed => status.toLowerCase() == 'used';
  bool get isExpired {
    try {
      final exp = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }

  Color get statusColor {
    if (isUsed) return Colors.grey;
    if (isExpired) return Colors.red;
    return const Color(0xFF0D6938);
  }

  String get statusLabel {
    if (isUsed) return 'Sudah Dipakai';
    if (isExpired) return 'Kedaluwarsa';
    return 'Tersedia (Aktif)';
  }

  factory RedeemedVoucher.fromMap(Map<String, dynamic> map) {
    return RedeemedVoucher(
      id: (map['id'] as num?)?.toInt() ?? 0,
      userEmail: map['user_email'] as String? ?? '',
      rewardId: (map['reward_id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? 'Voucher Belanja',
      category: map['category'] as String? ?? 'voucher_belanja',
      merchant: map['merchant'] as String? ?? 'TrashToCash',
      nominalValue: map['nominal_value'] as String? ?? '',
      voucherCode: map['voucher_code'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      pointsUsed: (map['points_used'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
      targetAccount: map['target_account'] as String?,
      terms: map['terms'] as String?,
      instructions: map['instructions'] as String?,
      redeemedAt: map['redeemed_at'] as String? ?? DateTime.now().toIso8601String(),
      expiresAt: map['expires_at'] as String? ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      usedAt: map['used_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'user_email': userEmail,
      'reward_id': rewardId,
      'title': title,
      'category': category,
      'merchant': merchant,
      'nominal_value': nominalValue,
      'voucher_code': voucherCode,
      'barcode': barcode,
      'points_used': pointsUsed,
      'status': status,
      'target_account': targetAccount,
      'terms': terms,
      'instructions': instructions,
      'redeemed_at': redeemedAt,
      'expires_at': expiresAt,
      'used_at': usedAt,
    };
  }
}
