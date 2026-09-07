import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageHelper {
  static final ValueNotifier<String> languageNotifier =
      ValueNotifier<String>('Bahasa Indonesia');

  static String get currentLanguage => languageNotifier.value;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('appLanguage') ?? 'Bahasa Indonesia';
    languageNotifier.value = savedLang;
  }

  static Future<void> setLanguage(String langName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', langName);
    languageNotifier.value = langName;
  }

  static bool get isEnglish =>
      languageNotifier.value.toLowerCase().contains('english');

  static bool get isSunda =>
      languageNotifier.value.toLowerCase().contains('sunda');

  static bool get isJawa =>
      languageNotifier.value.toLowerCase().contains('jawa');

  static String get langCode {
    final l = languageNotifier.value.toLowerCase();
    if (l.contains('english')) return 'en';
    if (l.contains('sunda')) return 'su';
    if (l.contains('jawa')) return 'jv';
    return 'id';
  }

  // Dictionary of core UI translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'app_title': 'TrashToCash',
      'home': 'Beranda',
      'scan': 'Scan Sampah',
      'history': 'Riwayat',
      'profile': 'Profil',
      'deposit_waste': 'Setor Sampah',
      'pickup_service': 'Layanan Penjemputan',
      'drop_off': 'Drop-off Mandiri',
      'total_balance': 'Total Saldo T-Cash',
      'withdraw': 'Tarik Saldo',
      'eco_points': 'Poin Eco-Hero',
      'settings': 'Pengaturan',
      'profile_settings': 'Pengaturan Profil',
      'notification_settings': 'Pengaturan Notifikasi',
      'language': 'Bahasa Aplikasi',
      'theme': 'Tema Tampilan',
      'personal_info': 'Informasi Pribadi',
      'payment_methods': 'Metode Pembayaran',
      'security': 'Keamanan & PIN',
      'help_center': 'Pusat Bantuan',
      'logout': 'Keluar Akun',
      'save': 'Simpan',
      'cancel': 'Batal',
      'success': 'Berhasil',
      'pending': 'Menunggu Penjemputan',
    },
    'en': {
      'app_title': 'TrashToCash',
      'home': 'Home',
      'scan': 'Scan Waste',
      'history': 'History',
      'profile': 'Profile',
      'deposit_waste': 'Deposit Waste',
      'pickup_service': 'Pickup Service',
      'drop_off': 'Self Drop-off',
      'total_balance': 'Total T-Cash Balance',
      'withdraw': 'Withdraw Cash',
      'eco_points': 'Eco-Hero Points',
      'settings': 'Settings',
      'profile_settings': 'Profile Settings',
      'notification_settings': 'Notification Settings',
      'language': 'App Language',
      'theme': 'Appearance Theme',
      'personal_info': 'Personal Information',
      'payment_methods': 'Payment Methods',
      'security': 'Security & PIN',
      'help_center': 'Help Center',
      'logout': 'Log Out',
      'save': 'Save',
      'cancel': 'Cancel',
      'success': 'Success',
      'pending': 'Pending Pickup',
    },
    'su': {
      'app_title': 'TrashToCash',
      'home': 'Imah',
      'scan': 'Paresha Runtah',
      'history': 'Riwayat',
      'profile': 'Profil Salira',
      'deposit_waste': 'Setor Runtah',
      'pickup_service': 'Layanan Jemput',
      'drop_off': 'Setor Salira',
      'total_balance': 'Total Saldo T-Cash',
      'withdraw': 'Cokot Saldo',
      'eco_points': 'Poin Eco-Hero',
      'settings': 'Pengaturan',
      'profile_settings': 'Pengaturan Profil',
      'notification_settings': 'Pengaturan Notifikasi',
      'language': 'Basa Aplikasi',
      'theme': 'Téma Tampilan',
      'personal_info': 'Informasi Salira',
      'payment_methods': 'Metode Pembayaran',
      'security': 'Keamanan & PIN',
      'help_center': 'Pusat Pitulung',
      'logout': 'Kaluar Akun',
      'save': 'Simpen',
      'cancel': 'Batal',
      'success': 'Kasil',
      'pending': 'Ngentosan Diropéa',
    },
    'jv': {
      'app_title': 'TrashToCash',
      'home': 'Omah',
      'scan': 'Pindai Sampah',
      'history': 'Riwayat',
      'profile': 'Profil',
      'deposit_waste': 'Setor Sampah',
      'pickup_service': 'Layanan Jupuk',
      'drop_off': 'Setor Dhewe',
      'total_balance': 'Gunggung Saldo T-Cash',
      'withdraw': 'Jupuk Saldo',
      'eco_points': 'Poin Eco-Hero',
      'settings': 'Pengaturan',
      'profile_settings': 'Pengaturan Profil',
      'notification_settings': 'Pengaturan Notifikasi',
      'language': 'Basa Aplikasi',
      'theme': 'Tema Tampilan',
      'personal_info': 'Informasi Pribadi',
      'payment_methods': 'Metode Pembayaran',
      'security': 'Keamanan & PIN',
      'help_center': 'Pusat Pitulung',
      'logout': 'Metu Akun',
      'save': 'Simpen',
      'cancel': 'Bungkur',
      'success': 'Hasil',
      'pending': 'Ngenteni Penjemputan',
    },
  };

  static String t(String text) {
    final code = langCode;
    if (code == 'id') return text;

    if (_translations.containsKey(code) &&
        _translations[code]!.containsKey(text)) {
      return _translations[code]![text]!;
    }

    if (_localizedValues.containsKey(code) &&
        _localizedValues[code]!.containsKey(text)) {
      return _localizedValues[code]![text]!;
    }

    if (code == 'en') {
      return _fallbackEnglish(text);
    }

    return text;
  }

  static String tr(String key) {
    return t(key);
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'Akun & Profil': 'Account & Profile',
      'Informasi Pribadi': 'Personal Information',
      'Pengaturan Profil': 'Profile Settings',
      'Pengaturan Profil & Aplikasi': 'Profile & App Settings',
      'Pengaturan Notifikasi': 'Notification Settings',
      'Metode Pembayaran': 'Payment Methods',
      'Metode Pembayaran & E-Wallet': 'Payment Methods & E-Wallet',
      'Keamanan & PIN': 'Security & PIN',
      'Pusat Bantuan': 'Help Center',
      'Pusat Bantuan & FAQ': 'Help Center & FAQ',
      'Keluar': 'Log Out',
      'Keluar Akun': 'Log Out',
      'Keluar dari Akun': 'Log Out of Account',
      'Versi Aplikasi': 'App Version',
      'TOTAL SALDO': 'TOTAL BALANCE',
      'Saldo T-Cash': 'T-Cash Balance',
      'Total Saldo T-Cash': 'Total T-Cash Balance',
      'Poin Eco': 'Eco Points',
      'Poin Eco-Hero': 'Eco-Hero Points',
      'Tarik Saldo': 'Withdraw Balance',
      'Setor Sampah': 'Deposit Waste',
      'Riwayat': 'History',
      'Beranda': 'Home',
      'Scan Sampah': 'Scan Waste',
      'Profil': 'Profile',
      'Bahasa Aplikasi': 'App Language',
      'Tema Tampilan': 'Appearance Theme',
      'Ukuran Font / Teks UI': 'Font Size / UI Text',
      'Format Satuan Berat Sampah': 'Waste Weight Unit',
      'Format Mata Uang / Saldo': 'Currency / Balance Format',
      'Radius Penjemputan Drop Point': 'Pickup Search Radius',
      'Waktu Penjemputan Favorit': 'Favorite Pickup Time',
      'Instruksi Default untuk Kurir': 'Default Courier Instructions',
      'Kualitas Upload Foto Sampah': 'Photo Upload Quality',
      'Semua Notifikasi': 'All Notifications',
      'Mode Jam Tenang (Do Not Disturb)': 'Quiet Hours Mode (Do Not Disturb)',
      'SALDO & TRANSAKSI T-CASH': 'T-CASH BALANCE & TRANSACTIONS',
      'PENJEMPUTAN & LOGISTIK KURIR': 'PICKUP & COURIER LOGISTICS',
      'GAMIFIKASI & KOMUNITAS ECO-HERO': 'GAMIFICATION & ECO-HERO COMMUNITY',
      'EDUKASI & TIPS LINGKUNGAN': 'EDUCATION & ECO TIPS',
      'PENGATURAN SUARA & PERANGKAT': 'SOUND & DEVICE SETTINGS',
      'Menunggu Penjemputan': 'Pending Pickup',
      'Diproses': 'In Progress',
      'Berhasil': 'Success',
      'Selesai': 'Completed',
      'Mode Mitra Driver / Kurir': 'Driver Partner Mode',
    },
    'su': {
      'Akun & Profil': 'Akun & Profil',
      'Informasi Pribadi': 'Informasi Salira',
      'Pengaturan Profil': 'Pengaturan Profil',
      'Pengaturan Profil & Aplikasi': 'Pengaturan Profil & Aplikasi',
      'Pengaturan Notifikasi': 'Pengaturan Notifikasi',
      'Metode Pembayaran': 'Metode Pembayaran',
      'Keamanan & PIN': 'Keamanan & PIN',
      'Pusat Bantuan': 'Pusat Pitulung',
      'Keluar': 'Kaluar',
      'Keluar Akun': 'Kaluar Akun',
      'Keluar dari Akun': 'Kaluar tina Akun',
      'TOTAL SALDO': 'TOTAL SALDO',
      'Tarik Saldo': 'Cokot Saldo',
      'Bahasa Aplikasi': 'Basa Aplikasi',
      'Tema Tampilan': 'Téma Tampilan',
      'Mode Mitra Driver / Kurir': 'Mode Mitra Driver / Kurir',
    },
    'jv': {
      'Akun & Profil': 'Akun & Profil',
      'Informasi Pribadi': 'Informasi Pribadi',
      'Pengaturan Profil': 'Pengaturan Profil',
      'Pengaturan Profil & Aplikasi': 'Pengaturan Profil & Aplikasi',
      'Pengaturan Notifikasi': 'Pengaturan Notifikasi',
      'Metode Pembayaran': 'Metode Pembayaran',
      'Keamanan & PIN': 'Keamanan & PIN',
      'Pusat Bantuan': 'Pusat Pitulung',
      'Keluar': 'Metu',
      'Keluar Akun': 'Metu Akun',
      'Keluar dari Akun': 'Metu saka Akun',
      'TOTAL SALDO': 'GUNGGUNG SALDO',
      'Tarik Saldo': 'Jupuk Saldo',
      'Bahasa Aplikasi': 'Basa Aplikasi',
      'Tema Tampilan': 'Tema Tampilan',
      'Mode Mitra Driver / Kurir': 'Mode Mitra Driver / Kurir',
    },
  };

  static String _fallbackEnglish(String text) {
    if (text.contains('Pengaturan')) return text.replaceAll('Pengaturan', 'Settings');
    if (text.contains('Notifikasi')) return text.replaceAll('Notifikasi', 'Notification');
    if (text.contains('Profil')) return text.replaceAll('Profil', 'Profile');
    if (text.contains('Bahasa')) return text.replaceAll('Bahasa', 'Language');
    if (text.contains('Tema')) return text.replaceAll('Tema', 'Theme');
    if (text.contains('Sampah')) return text.replaceAll('Sampah', 'Waste');
    if (text.contains('Penjemputan')) return text.replaceAll('Penjemputan', 'Pickup');
    if (text.contains('Berhasil')) return text.replaceAll('Berhasil', 'Success');
    if (text.contains('Batal')) return text.replaceAll('Batal', 'Cancel');
    if (text.contains('Simpan')) return text.replaceAll('Simpan', 'Save');
    return text;
  }
}
