import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/helpers/language_helper.dart';
import 'package:trashtocash/helpers/regional_languages_data.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/helpers/theme_helper.dart';
import 'package:trashtocash/models/user_level_model.dart';
import 'package:trashtocash/screens/driver/driver_home_screen.dart';
import 'package:trashtocash/screens/my_vouchers_screen.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';
import 'package:trashtocash/screens/withdrawal_screen.dart';
import 'package:trashtocash/widgets/user_level_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  String _phone = '0812-3456-7890';
  String _address = 'Jl. Kebon Sirih No. 24, Menteng, Jakarta Pusat';
  String _birthDate = '12 Mei 1998';
  String _gender = 'Laki-laki';
  String _avatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _email = widget.userEmail;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? prefs.getString('userEmail') ?? widget.userEmail;

    String name = prefs.getString('userName') ?? widget.userName;
    String phone = prefs.getString('userPhone') ?? _phone;
    String address = prefs.getString('userAddress') ?? _address;

    try {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        name = user.name;
        if (user.phone != null && user.phone!.isNotEmpty) phone = user.phone!;
        if (user.address != null && user.address!.isNotEmpty) address = user.address!;
      }
    } catch (_) {}

    final savedAvatar = prefs.getString('userAvatarUrl') ?? '';
    DatabaseHelper.userAvatarNotifier.value = savedAvatar;
    DatabaseHelper.userNameNotifier.value = name;

    setState(() {
      _name = name;
      _email = email;
      _phone = phone;
      _address = address;
      _birthDate = prefs.getString('userBirthDate') ?? _birthDate;
      _gender = prefs.getString('userGender') ?? _gender;
      _avatarUrl = savedAvatar;
    });
  }

  Future<void> _saveProfileData({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String birthDate,
    required String gender,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);
    await prefs.setString('userAddress', address);
    await prefs.setString('userBirthDate', birthDate);
    await prefs.setString('userGender', gender);
    if (avatarUrl != null) {
      await prefs.setString('userAvatarUrl', avatarUrl);
      DatabaseHelper.userAvatarNotifier.value = avatarUrl;
    }
    DatabaseHelper.userNameNotifier.value = name;

    try {
      await DatabaseHelper.instance.updateUserProfile(
        email: email,
        name: name,
        phone: phone,
        address: address,
      );
    } catch (_) {}

    setState(() {
      _name = name;
      _email = email;
      _phone = phone;
      _address = address;
      _birthDate = birthDate;
      _gender = gender;
      if (avatarUrl != null) _avatarUrl = avatarUrl;
    });
  }

  ImageProvider _getAvatarImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      );
    }
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    }
    try {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return const NetworkImage(
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _saveProfileData(
          name: _name,
          email: _email,
          phone: _phone,
          address: _address,
          birthDate: _birthDate,
          gender: _gender,
          avatarUrl: pickedFile.path,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF0D6938),
              content: Text('Foto profil berhasil diubah dari Galeri!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal memilih foto dari Galeri: $e'),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _saveProfileData(
          name: _name,
          email: _email,
          phone: _phone,
          address: _address,
          birthDate: _birthDate,
          gender: _gender,
          avatarUrl: pickedFile.path,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF0D6938),
              content: Text('Foto profil berhasil diambil dari Kamera!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal mengambil foto: $e'),
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E2821) : Colors.white,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header with glowing halo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF27AE60), Color(0xFF0D6938)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0D6938,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Konfirmasi Keluar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle / Description
              Text(
                'Apakah Anda yakin ingin keluar dari akun? Anda perlu masuk kembali untuk mengakses saldo dan riwayat penukaran sampah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ya, Keluar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onLogout();
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        elevation: 2,
                        shadowColor: const Color(
                          0xFF0D6938,
                        ).withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeAvatarSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=200',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ubah Foto Profil',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Pilih dari Galeri Button (Prominent)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2822)
                      : const Color(0xFFEAF4EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D6938),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  title: Row(
                    children: [
                      const Text(
                        'Pilih dari Galeri HP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6938),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Pilih foto selfie atau avatar dari album galeri Anda',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF0D6938),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromGallery();
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 2. Ambil dari Kamera Button
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263229)
                      : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Buka kamera dan ambil foto langsung',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromCamera();
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 3. Gunakan Ikon Default (Icons.person)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2822)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF0D6938),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Gunakan Ikon Default',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Hapus foto dan gunakan avatar ikon profil default',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _saveProfileData(
                      name: _name,
                      email: _email,
                      phone: _phone,
                      address: _address,
                      birthDate: _birthDate,
                      gender: _gender,
                      avatarUrl: '',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF0D6938),
                          content: Text('Foto profil direset ke ikon person default.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top Card Wrapper matching Frame 11
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with Edit Overlay & Tap Action
                GestureDetector(
                  onTap: _showChangeAvatarSheet,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                            width: 2.5,
                          ),
                        ),
                        child: ValueListenableBuilder<String>(
                          valueListenable: DatabaseHelper.userAvatarNotifier,
                          builder: (context, currentAvatar, _) {
                            final hasCustomImg = currentAvatar.isNotEmpty &&
                                (currentAvatar.startsWith('http://') ||
                                 currentAvatar.startsWith('https://') ||
                                 File(currentAvatar).existsSync());

                            if (hasCustomImg) {
                              return CircleAvatar(
                                radius: 42,
                                backgroundColor: isDark
                                    ? const Color(0xFF1E2822)
                                    : const Color(0xFFEAF4EE),
                                backgroundImage: _getAvatarImageProvider(currentAvatar),
                              );
                            }

                            return CircleAvatar(
                              radius: 42,
                              backgroundColor: isDark
                                  ? const Color(0xFF1E2822)
                                  : const Color(0xFFEAF4EE),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF0D6938),
                                size: 52,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6938),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).cardColor,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Button Text Ubah Foto Profil
                InkWell(
                  onTap: _showChangeAvatarSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 13,
                          color: Color(0xFF0D6938),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Ubah Foto dari Galeri',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                // User Level Tier Pill Badge
                ValueListenableBuilder<int>(
                  valueListenable: DatabaseHelper.userEcoPointsNotifier,
                  builder: (context, ecoPoints, _) {
                    final progression = UserLevelProgression.fromStats(
                      points: ecoPoints,
                      totalKg: 0.0,
                    );
                    final tier = progression.currentTier;

                    return InkWell(
                      onTap: () => UserLevelSheet.show(context, totalKg: 0.0),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tier.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tier.primaryColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tier.icon,
                              size: 15,
                              color: tier.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Level ${tier.level} • ${tier.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tier.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: tier.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Total Saldo Widget Inside Profile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageHelper.t('TOTAL SALDO').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ValueListenableBuilder<double>(
                            valueListenable: DatabaseHelper.userBalanceNotifier,
                            builder: (context, balance, _) {
                              return Text(
                                DatabaseHelper.formatRupiah(balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFFFD700),
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tarik Saldo Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WithdrawalScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    label: Text(
                      LanguageHelper.t('Tarik Saldo'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings Options Card List
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // 0. Beralih ke Mode Driver / Kurir
                _buildSettingsTile(
                  icon: Icons.electric_moped,
                  title: 'Mode Mitra Driver / Kurir',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Buka Radar',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    DriverHelper.instance.isDriverModeActive.value = true;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverHomeScreen(),
                      ),
                    );
                  },
                ),

                // A. Tukar Eco-Points & Hadiah (Reward Redemption)
                _buildSettingsTile(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Tukar Poin & Voucher Belanja',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD84315),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Katalog 🎁',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RewardRedemptionScreen(),
                      ),
                    );
                  },
                ),

                // B. Voucher & Hadiah Saya
                _buildSettingsTile(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Voucher & Hadiah Saya',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Lihat Kode 🎟️',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVouchersScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // 1. Informasi Pribadi
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: LanguageHelper.t('Informasi Pribadi'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InformasiPribadiScreen(
                          name: _name,
                          email: _email,
                          phone: _phone,
                          address: _address,
                          birthDate: _birthDate,
                          gender: _gender,
                          onSave:
                              (name, email, phone, address, birthDate, gender) {
                                _saveProfileData(
                                  name: name,
                                  email: email,
                                  phone: phone,
                                  address: address,
                                  birthDate: birthDate,
                                  gender: gender,
                                );
                              },
                        ),
                      ),
                    );
                  },
                ),

                // 2. Pengaturan Profil
                _buildSettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  title: LanguageHelper.t('Pengaturan Profil'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PengaturanProfilScreen(),
                      ),
                    );
                  },
                ),

                // 3. Metode Pembayaran
                _buildSettingsTile(
                  icon: Icons.payment_outlined,
                  title: LanguageHelper.t('Metode Pembayaran'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MetodePembayaranScreen(),
                      ),
                    );
                  },
                ),

                // 4. Pengaturan Notifikasi
                _buildSettingsTile(
                  icon: Icons.notifications_none,
                  title: LanguageHelper.t('Pengaturan Notifikasi'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PengaturanNotifikasiScreen(),
                      ),
                    );
                  },
                ),

                // 5. Keamanan
                _buildSettingsTile(
                  icon: Icons.security_outlined,
                  title: LanguageHelper.t('Keamanan & PIN'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KeamananScreen(),
                      ),
                    );
                  },
                ),

                // 6. Pusat Bantuan
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: LanguageHelper.t('Pusat Bantuan'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PusatBantuanScreen(),
                      ),
                    );
                  },
                ),

                // 7. Keluar dari Akun
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: LanguageHelper.t('Keluar dari Akun'),
                  showDivider: false,
                  titleColor: Colors.red.shade600,
                  iconColor: Colors.red.shade600,
                  iconBgColor: isDark
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.red.shade50,
                  onTap: _showLogoutDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Branding Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                size: 14,
                color: const Color(0xFF0D6938).withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'TrashToCash v1.0.0 • Solusi Sampah Jadi Cuan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
    Color? titleColor,
    Color? iconColor,
    Color? iconBgColor,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  iconBgColor ??
                  (isDark
                      ? const Color(0xFF0D6938).withValues(alpha: 0.2)
                      : const Color(0xFFEAF4EE)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color:
                  iconColor ??
                  (isDark ? const Color(0xFF27AE60) : const Color(0xFF0D6938)),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: titleColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.grey,
                size: 20,
              ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ==========================================
// 1. INFORMASI PRIBADI SCREEN
// ==========================================
class InformasiPribadiScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String birthDate;
  final String gender;
  final Function(
    String name,
    String email,
    String phone,
    String address,
    String birthDate,
    String gender,
  )
  onSave;

  const InformasiPribadiScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.gender,
    required this.onSave,
  });

  @override
  State<InformasiPribadiScreen> createState() => _InformasiPribadiScreenState();
}

class _InformasiPribadiScreenState extends State<InformasiPribadiScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
    _birthDateController = TextEditingController(text: widget.birthDate);
    _selectedGender = widget.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _addressController.text.trim(),
      _birthDateController.text.trim(),
      _selectedGender,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informasi pribadi berhasil disimpan!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Informasi Pribadi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                    'Nama Lengkap',
                    _nameController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    'Alamat Email',
                    _emailController,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    'Nomor Telepon',
                    _phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    'Tanggal Lahir',
                    _birthDateController,
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Laki-laki')),
                          selected: _selectedGender == 'Laki-laki',
                          selectedColor: const Color(0xFFD6EFE2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGender = 'Laki-laki');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Perempuan')),
                          selected: _selectedGender == 'Perempuan',
                          selectedColor: const Color(0xFFD6EFE2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGender = 'Perempuan');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    'Alamat Rumah Lengkap',
                    _addressController,
                    Icons.home_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0D6938), size: 18),
            filled: true,
            fillColor: const Color(0xFFF4F8F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. PENGATURAN PROFIL SCREEN (ENTERPRISE ECO-HERO)
// ==========================================
class PengaturanProfilScreen extends StatefulWidget {
  const PengaturanProfilScreen({super.key});

  @override
  State<PengaturanProfilScreen> createState() => _PengaturanProfilScreenState();
}

class _PengaturanProfilScreenState extends State<PengaturanProfilScreen> {
  // App Appearance & Personalization
  String _selectedLanguage = 'Bahasa Indonesia';
  late bool _isDarkMode;
  String _themeSelection = 'Sistem';
  String _textSize = 'Standar';
  String _weightUnit = 'Kilogram (kg)';
  String _currencyUnit = 'Rupiah (Rp)';
  bool _hapticFeedback = true;

  // Recycling & Logistics Preferences
  bool _autoDetectLocation = true;
  double _pickupRadius = 5.0;
  String _preferredPickupTime = 'Pagi (08:00 - 12:00)';
  String _courierNote = 'Sampah sudah dipilah rapi di teras depan';

  // Data, Storage & Sync
  String _photoQuality = 'Kompresi Hemat Kuota (Cepat)';
  bool _autoSyncOffline = true;
  String _cacheSize = '28.4 MB';

  // Privacy & Community
  bool _publicLeaderboard = true;
  bool _shareEcoImpact = true;

  @override
  void initState() {
    super.initState();
    _isDarkMode = ThemeHelper.isDarkMode;
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage =
            prefs.getString('appLanguage') ?? 'Bahasa Indonesia';
        _themeSelection =
            prefs.getString('appThemeSelection') ??
            (_isDarkMode ? 'Gelap' : 'Terang');
        _textSize = prefs.getString('appTextSize') ?? 'Standar';
        _weightUnit = prefs.getString('appWeightUnit') ?? 'Kilogram (kg)';
        _currencyUnit = prefs.getString('appCurrencyUnit') ?? 'Rupiah (Rp)';
        _hapticFeedback = prefs.getBool('appHapticFeedback') ?? true;

        _autoDetectLocation = prefs.getBool('appAutoLocation') ?? true;
        _pickupRadius = prefs.getDouble('appPickupRadius') ?? 5.0;
        _preferredPickupTime =
            prefs.getString('appPickupTime') ?? 'Pagi (08:00 - 12:00)';
        _courierNote =
            prefs.getString('appCourierNote') ??
            'Sampah sudah dipilah rapi di teras depan';

        _photoQuality =
            prefs.getString('appPhotoQuality') ??
            'Kompresi Hemat Kuota (Cepat)';
        _autoSyncOffline = prefs.getBool('appAutoSync') ?? true;
        _cacheSize = prefs.getString('appCacheSize') ?? '28.4 MB';

        _publicLeaderboard = prefs.getBool('appPublicLeaderboard') ?? true;
        _shareEcoImpact = prefs.getBool('appShareImpact') ?? true;
      });
    }
  }

  Future<void> _saveStringPref(String key, String value, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (mounted) {
      setState(() {});
      if (label.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D6938),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$label diubah ke: $value')),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showLanguagePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LanguagePickerSheet(
        currentLanguage: _selectedLanguage,
        onLanguageSelected: (newLang) async {
          await LanguageHelper.setLanguage(newLang);
          if (mounted) {
            setState(() => _selectedLanguage = newLang);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0D6938),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                content: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bahasa aplikasi berhasil diubah ke: $newLang',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showThemeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E2821) : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.palette_outlined, color: Color(0xFF0D6938), size: 22),
              SizedBox(width: 10),
              Text(
                'Pilih Tema Tampilan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Mode Terang (Light)',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Tampilan bersih dan cerah',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: _themeSelection == 'Terang'
                    ? const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF0D6938),
                      )
                    : const Icon(Icons.radio_button_off, color: Colors.grey),
                onTap: () {
                  setDlgState(() => _themeSelection = 'Terang');
                  setState(() {
                    _themeSelection = 'Terang';
                    _isDarkMode = false;
                  });
                  _saveStringPref(
                    'appThemeSelection',
                    'Terang',
                    'Tema Tampilan',
                  );
                  ThemeHelper.setThemeSelection('Terang');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text(
                  'Mode Gelap (Dark)',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Hemat baterai & nyaman di mata',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: _themeSelection == 'Gelap'
                    ? const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF0D6938),
                      )
                    : const Icon(Icons.radio_button_off, color: Colors.grey),
                onTap: () {
                  setDlgState(() => _themeSelection = 'Gelap');
                  setState(() {
                    _themeSelection = 'Gelap';
                    _isDarkMode = true;
                  });
                  _saveStringPref(
                    'appThemeSelection',
                    'Gelap',
                    'Tema Tampilan',
                  );
                  ThemeHelper.setThemeSelection('Gelap');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text(
                  'Ikuti Sistem Perangkat',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Menyesuaikan pengaturan HP otomatis',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: _themeSelection == 'Sistem'
                    ? const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF0D6938),
                      )
                    : const Icon(Icons.radio_button_off, color: Colors.grey),
                onTap: () {
                  setDlgState(() => _themeSelection = 'Sistem');
                  setState(() => _themeSelection = 'Sistem');
                  _saveStringPref(
                    'appThemeSelection',
                    'Sistem',
                    'Tema Tampilan',
                  );
                  ThemeHelper.setThemeSelection('Sistem');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextSizeDialog() {
    final options = [
      'Kecil (90%)',
      'Standar (100%)',
      'Besar (115%)',
      'Ekstra Besar (130%)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ukuran Font / Teks UI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: options.map((opt) {
          final isSelected = _textSize == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _textSize = opt);
              _saveStringPref('appTextSize', opt, 'Ukuran Teks UI');
              ThemeHelper.setTextSize(opt);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showWeightUnitDialog() {
    final options = [
      'Kilogram (kg)',
      'Gram (g)',
      'Ton Metrik (t)',
      'Pounds (lbs)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Format Satuan Berat Sampah',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: options.map((opt) {
          final isSelected = _weightUnit == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _weightUnit = opt);
              _saveStringPref('appWeightUnit', opt, 'Satuan Berat');
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCurrencyDialog() {
    final options = ['Rupiah (Rp)', 'Poin T-Cash', 'Eco-Credits (Global)'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Format Mata Uang / Saldo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: options.map((opt) {
          final isSelected = _currencyUnit == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _currencyUnit = opt);
              _saveStringPref('appCurrencyUnit', opt, 'Format Mata Uang');
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showRadiusDialog() {
    double tempRadius = _pickupRadius;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Radius Penjemputan Drop Point',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempRadius.toStringAsFixed(1)} Kilometer',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6938),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mencari mitra penjemput dan bank sampah dalam jangkauan ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Slider(
                value: tempRadius,
                min: 1.0,
                max: 25.0,
                divisions: 24,
                activeColor: const Color(0xFF0D6938),
                label: '${tempRadius.toStringAsFixed(1)} km',
                onChanged: (val) => setDlgState(() => tempRadius = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('appPickupRadius', tempRadius);
                setState(() => _pickupRadius = tempRadius);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0D6938),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Radius penjemputan diubah ke: ${tempRadius.toStringAsFixed(1)} km',
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickupTimeDialog() {
    final options = [
      'Pagi (08:00 - 12:00)',
      'Siang (13:00 - 16:00)',
      'Sore (16:00 - 18:00)',
      'Malam / Tengah Malam (19:00 - 24:00)',
      'Fleksibel (Kapan Saja Kurir Siap)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Waktu Penjemputan Favorit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: options.map((opt) {
          final isSelected = _preferredPickupTime == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _preferredPickupTime = opt);
              _saveStringPref(
                'appPickupTime',
                opt,
                'Waktu Penjemputan Favorit',
              );
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13.5,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCourierNoteDialog() {
    final controller = TextEditingController(text: _courierNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Instruksi Default untuk Kurir',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Instruksi ini akan otomatis terisi saat Anda memesan penjemputan sampah.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Sampah di teras depan, gerbang tidak dikunci...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6938),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final newNote = controller.text.trim();
              setState(() => _courierNote = newNote);
              _saveStringPref('appCourierNote', newNote, 'Instruksi Kurir');
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhotoQualityDialog() {
    final options = [
      'Kompresi Hemat Kuota (Cepat)',
      'Standar Seimbang (HD 720p)',
      'Kualitas Asli Tanpa Kompresi (Ultra HD)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Kualitas Upload Foto Sampah',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: options.map((opt) {
          final isSelected = _photoQuality == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _photoQuality = opt);
              _saveStringPref('appPhotoQuality', opt, 'Kualitas Foto Bukti');
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMemberPerksSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFF6B5300),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keuntungan Gold Member',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level 4 dari 5 • Eco-Hero',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildPerkItem(
              Icons.trending_up,
              'Bonus Saldo +10%',
              'Dapatkan ekstra 10% T-Cash setiap penimbangan terverifikasi.',
            ),
            _buildPerkItem(
              Icons.local_shipping_outlined,
              'Prioritas Kurir Penjemput',
              'Pesanan penjemputan sampah Anda diprioritaskan dalam 15 menit.',
            ),
            _buildPerkItem(
              Icons.eco_rounded,
              'Lencana Khusus Profil',
              'Status Eco-Hero emas terpampang di leaderboard komunitas.',
            ),
            _buildPerkItem(
              Icons.card_giftcard,
              'Kupon Hadiah Spesial',
              'Voucher belanja ramah lingkungan eksklusif setiap awal bulan.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0D6938), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearAppCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bersihkan Cache Aplikasi?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Akan menghapus file sementara dan cache gambar ($_cacheSize). Riwayat dan data akun Anda tetap aman.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6938),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _cacheSize = '0.0 KB');
              _saveStringPref('appCacheSize', '0.0 KB', '');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0D6938),
                  content: Text('Cache aplikasi berhasil dibersihkan!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Bersihkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ekspor Laporan Jejak Karbon & Setoran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unduh riwayat transaksi, berat sampah terdaur ulang, dan sertifikat emisi CO2 yang dicegah.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 28,
              ),
              title: const Text(
                'Format Dokumen PDF Resmi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Lengkap dengan sertifikat & grafik bulanan',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.download, color: Color(0xFF0D6938)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF0D6938),
                    content: Text(
                      'Laporan PDF berhasil diunduh ke folder Download!',
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.table_chart,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'Format Spreadsheet Excel / CSV',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Data mentah riwayat transaksi & berat',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.download, color: Color(0xFF0D6938)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF0D6938),
                    content: Text('File CSV berhasil diunduh!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showActiveSessionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Perangkat & Sesi Login Aktif',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(
                Icons.phone_android,
                color: Color(0xFF0D6938),
              ),
              title: Text(
                'Perangkat Ini (Android 14)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                'Jakarta, Indonesia • Sedang Aktif',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.laptop_mac, color: Colors.grey),
              title: const Text(
                'Web Dashboard TrashToCash',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Chrome di Windows • Aktif 2 jam lalu',
                style: TextStyle(fontSize: 11),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesi Web berhasil dikeluarkan!'),
                    ),
                  );
                },
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0D6938),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0D6938),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: Text(
          LanguageHelper.t('Pengaturan Profil & Aplikasi'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. TOP HERO BADGE & XP CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6938), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFD700),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tingkat Keanggotaan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Gold Member Eco-Hero',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Multiplier Reward +10% • Prioritas Jemput',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: _showMemberPerksSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XP Menuju Platinum Eco-Guardian',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '2.450 / 3.000 XP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 2450 / 3000,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFD700),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // 2. TAMPILAN & PERSONALISASI
          _buildSectionHeader(
            'TAMPILAN & PERSONALISASI',
            Icons.palette_outlined,
          ),
          _buildCardContainer([
            ListTile(
              leading: const Icon(
                Icons.language_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Bahasa Aplikasi',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedLanguage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showLanguagePickerSheet,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.dark_mode_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Tema Tampilan',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _themeSelection,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showThemeDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.format_size_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Ukuran Font / Teks UI',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _textSize,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showTextSizeDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.scale_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Satuan Berat Sampah',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _weightUnit,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showWeightUnitDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.monetization_on_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Format Mata Uang / Saldo',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _currencyUnit,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showCurrencyDialog,
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(
                Icons.vibration_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Efek Getar & Haptic Feedback',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Getaran halus saat scan sampah & konfirmasi',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _hapticFeedback,
              activeThumbColor: const Color(0xFF0D6938),
              onChanged: (val) {
                setState(() => _hapticFeedback = val);
                _saveBoolPref('appHapticFeedback', val);
              },
            ),
          ]),

          // 3. PREFERENSI PENJEMPUTAN & DAUR ULANG
          _buildSectionHeader(
            'PREFERENSI PENJEMPUTAN & DAUR ULANG',
            Icons.recycling_rounded,
          ),
          _buildCardContainer([
            SwitchListTile(
              secondary: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Deteksi Lokasi Otomatis (GPS)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Cari drop point terdekat berdasarkan GPS perangkat',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _autoDetectLocation,
              activeThumbColor: const Color(0xFF0D6938),
              onChanged: (val) {
                setState(() => _autoDetectLocation = val);
                _saveBoolPref('appAutoLocation', val);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.radar_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Radius Penjemputan Maksimal',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_pickupRadius.toStringAsFixed(1)} km jangkauan kurir',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showRadiusDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Waktu Penjemputan Favorit',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _preferredPickupTime,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showPickupTimeDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.note_alt_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Instruksi Default untuk Kurir',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _courierNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showCourierNoteDialog,
            ),
          ]),

          // 4. DATA, PENYIMPANAN & SINKRONISASI
          _buildSectionHeader(
            'DATA, PENYIMPANAN & SINKRONISASI',
            Icons.cloud_sync_outlined,
          ),
          _buildCardContainer([
            ListTile(
              leading: const Icon(
                Icons.photo_camera_back_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Kualitas Foto Bukti Sampah',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _photoQuality,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showPhotoQualityDialog,
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(
                Icons.sync_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Sinkronisasi Otomatis Offline',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Simpan riwayat saat offline dan sinkron otomatis saat online',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _autoSyncOffline,
              activeThumbColor: const Color(0xFF0D6938),
              onChanged: (val) {
                setState(() => _autoSyncOffline = val);
                _saveBoolPref('appAutoSync', val);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.cleaning_services_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Bersihkan Cache Aplikasi',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$_cacheSize file sementara tersimpan',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: TextButton(
                onPressed: _clearAppCache,
                child: const Text(
                  'Bersihkan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D6938),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Ekspor Laporan Jejak Karbon & Setoran',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Unduh berkas PDF / Excel rekap bulanan',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _exportReport,
            ),
          ]),

          // 5. PRIVASI & KEAMANAN AKUN
          _buildSectionHeader(
            'PRIVASI & KEAMANAN AKUN',
            Icons.security_rounded,
          ),
          _buildCardContainer([
            SwitchListTile(
              secondary: const Icon(
                Icons.leaderboard_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Tampilkan di Leaderboard Eco-Hero',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Nama dan total daur ulang Anda terlihat di peringkat komunitas',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _publicLeaderboard,
              activeThumbColor: const Color(0xFF0D6938),
              onChanged: (val) {
                setState(() => _publicLeaderboard = val);
                _saveBoolPref('appPublicLeaderboard', val);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(
                Icons.share_outlined,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Bagikan Dampak Lingkungan',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Izinkan pembuatan kartu sertifikat daur ulang untuk media sosial',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _shareEcoImpact,
              activeThumbColor: const Color(0xFF0D6938),
              onChanged: (val) {
                setState(() => _shareEcoImpact = val);
                _saveBoolPref('appShareImpact', val);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.devices_rounded,
                color: Color(0xFF0D6938),
              ),
              title: const Text(
                'Sesi Perangkat Aktif',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Kelola perangkat yang terhubung ke akun Anda',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
              onTap: _showActiveSessionsDialog,
            ),
          ]),

          // 6. ZONA PENGATURAN KHUSUS & HAPUS AKUN
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Reset Pengaturan?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'Semua preferensi tampilan dan penjemputan akan dikembalikan ke setelan awal pabrik.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6938),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          _loadAllPreferences();
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF0D6938),
                                content: Text(
                                  'Pengaturan berhasil direset ke default!',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Pengaturan ke Default'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Hapus Akun TrashToCash?',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    content: const Text(
                      'Peringatan: Penghapusan akun bersifat permanen. Saldo T-Cash, riwayat poin, dan sertifikat Eco-Hero Anda akan terhapus dan tidak dapat dipulihkan.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Hapus Akun',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 18,
              ),
              label: const Text(
                'Hapus Akun Saya Permanen',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// BOTTOM SHEET PILIH BAHASA (718 BAHASA DAERAH)
// ----------------------------------------------------
class _LanguagePickerSheet extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageSelected;

  const _LanguagePickerSheet({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'Semua';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RegionalLanguage> get _filteredLanguages {
    return RegionalLanguagesData.allLanguages.where((lang) {
      if (_selectedRegion != 'Semua') {
        if (_selectedRegion == 'Utama') {
          if (!lang.isNationalOrGlobal) return false;
        } else if (lang.region != _selectedRegion) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = lang.name.toLowerCase().contains(q);
        final provMatch = lang.province.toLowerCase().contains(q);
        final regMatch = lang.region.toLowerCase().contains(q);
        return nameMatch || provMatch || regMatch;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredLanguages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: Color(0xFF0D6938),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Bahasa Aplikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF27AE60,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '718 Bahasa Daerah',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6938),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kemendikbudristek RI',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari bahasa (contoh: Sunda, Jawa, Minang, Papua...)',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF0D6938),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF232D26)
                    : const Color(0xFFF1F6F3),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Region Choice Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: RegionalLanguagesData.regions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final region = RegionalLanguagesData.regions[index];
                final isSelected = _selectedRegion == region;
                return ChoiceChip(
                  label: Text(region),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRegion = region);
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  selectedColor: const Color(0xFF0D6938),
                  backgroundColor: isDark
                      ? const Color(0xFF1E2822)
                      : const Color(0xFFEAF4EE),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0D6938)
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 0,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),
          // Count header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan ${filtered.length} bahasa',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedRegion != 'Semua')
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedRegion = 'Semua';
                      });
                    },
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0D6938),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Languages ListView
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bahasa tidak ditemukan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coba kata kunci pencarian lain',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 64,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = widget.currentLanguage == item.name;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D6938)
                                : (isDark
                                      ? const Color(
                                          0xFF0D6938,
                                        ).withValues(alpha: 0.15)
                                      : const Color(0xFFEAF4EE)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isNationalOrGlobal
                                ? Icons.public_rounded
                                : Icons.translate_rounded,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF0D6938)),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0D6938)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.region,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.province,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D6938),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            : null,
                        onTap: () {
                          widget.onLanguageSelected(item.name);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. METODE PEMBAYARAN SCREEN
// ==========================================
class MetodePembayaranScreen extends StatefulWidget {
  const MetodePembayaranScreen({super.key});

  @override
  State<MetodePembayaranScreen> createState() => _MetodePembayaranScreenState();
}

class _MetodePembayaranScreenState extends State<MetodePembayaranScreen> {
  final List<Map<String, String>> _accounts = [
    {
      'type': 'Bank BCA',
      'number': '8842-1920-331',
      'name': 'TrashToCash Member',
      'isPrimary': 'true',
    },
    {
      'type': 'GoPay',
      'number': '0812-3456-7890',
      'name': 'TrashToCash Member',
      'isPrimary': 'false',
    },
    {
      'type': 'DANA',
      'number': '0812-3456-7890',
      'name': 'TrashToCash Member',
      'isPrimary': 'false',
    },
  ];

  void _showAddAccountSheet() {
    final typeController = TextEditingController(text: 'Bank Mandiri');
    final numberController = TextEditingController();
    final nameController = TextEditingController(text: 'TrashToCash Member');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Rekening / E-Wallet Baru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Jenis Bank / E-Wallet (BCA, Mandiri, OVO, dll)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Rekening / HP E-Wallet',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemilik Rekening',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                ),
                onPressed: () {
                  if (numberController.text.isNotEmpty) {
                    setState(() {
                      _accounts.add({
                        'type': typeController.text,
                        'number': numberController.text,
                        'name': nameController.text,
                        'isPrimary': 'false',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rekening berhasil ditambahkan!'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Simpan Rekening',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Rekening Penarikan Terdaftar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._accounts.map((acc) {
            final isPrimary = acc['isPrimary'] == 'true';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPrimary
                      ? const Color(0xFF0D6938)
                      : Colors.grey.shade200,
                  width: isPrimary ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      acc['type']!.startsWith('Bank')
                          ? Icons.account_balance
                          : Icons.phone_android,
                      color: const Color(0xFF0D6938),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              acc['type']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4EE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Utama',
                                  style: TextStyle(
                                    color: Color(0xFF0D6938),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acc['number']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'a.n. ${acc['name']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPrimary)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var a in _accounts) {
                            a['isPrimary'] = 'false';
                          }
                          acc['isPrimary'] = 'true';
                        });
                      },
                      child: const Text(
                        'Jadikan Utama',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showAddAccountSheet,
            icon: const Icon(Icons.add, color: Color(0xFF0D6938)),
            label: const Text(
              'Tambah Rekening / E-Wallet Lain',
              style: TextStyle(
                color: Color(0xFF0D6938),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0D6938)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. PENGATURAN NOTIFIKASI SCREEN (ENTERPRISE CENTER)
// ==========================================
class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState
    extends State<PengaturanNotifikasiScreen> {
  // Master & Quiet Hours
  bool _masterNotif = true;
  bool _quietHours = false;
  String _quietHoursTime = '22:00 - 06:00';

  // Penjemputan & Kurir
  bool _pickupStatus = true;
  bool _pickupReminder = true;
  bool _courierDelay = true;

  // Saldo & Transaksi Finansial T-Cash
  bool _rewardDeposit = true;
  bool _withdrawalSuccess = true;
  bool _priceAlert = true;
  bool _voucherExpiry = true;

  // Gamifikasi & Komunitas Eco-Hero
  bool _badgeLevel = true;
  bool _weeklyChallenge = true;
  bool _leaderboardRank = false;

  // Edukasi & Berita Lingkungan
  bool _ecoTips = true;
  bool _ecoNews = false;

  // Saluran Notifikasi & Suara
  bool _pushChannel = true;
  bool _soundCoinEffect = true;
  bool _vibrationAlert = true;

  @override
  void initState() {
    super.initState();
    _loadNotifPreferences();
  }

  Future<void> _loadNotifPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _masterNotif = prefs.getBool('notif_master') ?? true;
        _quietHours = prefs.getBool('notif_quiet') ?? false;
        _quietHoursTime =
            prefs.getString('notif_quiet_time') ?? '22:00 - 06:00';

        _pickupStatus = prefs.getBool('notif_pickup_status') ?? true;
        _pickupReminder = prefs.getBool('notif_pickup_reminder') ?? true;
        _courierDelay = prefs.getBool('notif_courier_delay') ?? true;

        _rewardDeposit = prefs.getBool('notif_reward_deposit') ?? true;
        _withdrawalSuccess = prefs.getBool('notif_withdrawal_success') ?? true;
        _priceAlert = prefs.getBool('notif_price_alert') ?? true;
        _voucherExpiry = prefs.getBool('notif_voucher_expiry') ?? true;

        _badgeLevel = prefs.getBool('notif_badge_level') ?? true;
        _weeklyChallenge = prefs.getBool('notif_weekly_challenge') ?? true;
        _leaderboardRank = prefs.getBool('notif_leaderboard_rank') ?? false;

        _ecoTips = prefs.getBool('notif_eco_tips') ?? true;
        _ecoNews = prefs.getBool('notif_eco_news') ?? false;

        _pushChannel = prefs.getBool('notif_channel_push') ?? true;
        _soundCoinEffect = prefs.getBool('notif_sound_coin') ?? true;
        _vibrationAlert = prefs.getBool('notif_vibration') ?? true;
      });
    }
  }

  Future<void> _saveNotifPref(
    String key,
    bool value, [
    String? titleLabel,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted && titleLabel != null && titleLabel.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D6938),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              Icon(
                value ? Icons.check_circle : Icons.do_not_disturb_on_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value
                      ? '$titleLabel diaktifkan'
                      : '$titleLabel dinonaktifkan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  void _showQuietHoursDialog() {
    final times = [
      '21:00 - 05:00',
      '22:00 - 06:00',
      '23:00 - 07:00',
      'Kustom (Sesuai Jadwal Istirahat)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Atur Rentang Jam Tenang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: times.map((t) {
          final isSelected = _quietHoursTime == t;
          return SimpleDialogOption(
            onPressed: () async {
              setState(() => _quietHoursTime = t);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('notif_quiet_time', t);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0D6938),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    content: Text(
                      'Rentang Jam Tenang diatur ke $t',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF0D6938),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: isDark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF0D6938),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildNotifTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extraAction,
    bool showDivider = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = _masterNotif;

    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          secondary: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isEnabled && value
                  ? const Color(0xFF0D6938).withValues(alpha: 0.12)
                  : (isDark ? Colors.white10 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isEnabled && value
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF0D6938))
                  : Colors.grey,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isEnabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              if (extraAction != null) ...[
                const SizedBox(height: 4),
                extraAction,
              ],
            ],
          ),
          value: isEnabled ? value : false,
          activeThumbColor: const Color(0xFF0D6938),
          onChanged: isEnabled ? onChanged : null,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 60,
            endIndent: 16,
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: Text(
          LanguageHelper.t('Pengaturan Notifikasi'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. MASTER NOTIFICATION SWITCH BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _masterNotif
                    ? [const Color(0xFF0D6938), const Color(0xFF1B5E20)]
                    : [Colors.grey.shade700, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (_masterNotif ? const Color(0xFF0D6938) : Colors.black)
                      .withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _masterNotif
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Semua Notifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _masterNotif
                            ? 'Pemberitahuan aktif secara real-time'
                            : 'Semua notifikasi dibisukan sementara',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _masterNotif,
                  activeThumbColor: const Color(0xFFFFD700),
                  activeTrackColor: Colors.white24,
                  onChanged: (val) {
                    setState(() => _masterNotif = val);
                    _saveNotifPref('notif_master', val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0D6938),
                        content: Text(
                          val
                              ? 'Notifikasi diaktifkan'
                              : 'Semua notifikasi dinonaktifkan',
                        ),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. MODE JAM TENANG (DO NOT DISTURB)
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _quietHours
                    ? const Color(0xFF0D6938).withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _quietHours
                          ? const Color(0xFF0D6938).withValues(alpha: 0.12)
                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      size: 20,
                      color: _quietHours
                          ? (isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF0D6938))
                          : Colors.grey,
                    ),
                  ),
                  title: const Text(
                    'Mode Jam Tenang (Do Not Disturb)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Heningkan nada dan getaran saat jam tidur',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  value: _quietHours,
                  activeThumbColor: const Color(0xFF0D6938),
                  onChanged: _masterNotif
                      ? (val) {
                          setState(() => _quietHours = val);
                          _saveNotifPref('notif_quiet', val);
                        }
                      : null,
                ),
                if (_quietHours) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF0D6938),
                      size: 20,
                    ),
                    title: const Text(
                      'Rentang Waktu Jam Tenang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _quietHoursTime,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF0D6938),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: _showQuietHoursDialog,
                  ),
                ],
              ],
            ),
          ),

          // 3. TRANSAKSI & SALDO FINANSIAL
          _buildSectionCard(
            'SALDO & TRANSAKSI T-CASH',
            Icons.account_balance_wallet_outlined,
            [
              _buildNotifTile(
                title: 'Saldo Masuk dari Setoran Sampah',
                subtitle:
                    'Pemberitahuan instan saat timbangan kurir diverifikasi & cuan masuk',
                icon: Icons.payments_rounded,
                value: _rewardDeposit,
                onChanged: (val) {
                  setState(() => _rewardDeposit = val);
                  _saveNotifPref(
                    'notif_reward_deposit',
                    val,
                    'Notifikasi Saldo Masuk',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Status Penarikan Saldo Berhasil',
                subtitle:
                    'Konfirmasi transfer ke DANA, GoPay, OVO, ShopeePay, atau Bank',
                icon: Icons.check_circle_outline_rounded,
                value: _withdrawalSuccess,
                onChanged: (val) {
                  setState(() => _withdrawalSuccess = val);
                  _saveNotifPref(
                    'notif_withdrawal_success',
                    val,
                    'Notifikasi Penarikan Saldo',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Peringatan Kenaikan Harga Sampah (Price Alert)',
                subtitle:
                    'Update saat harga per-kg jenis sampah tertentu (Plastik/Kardus/Tembaga) naik',
                icon: Icons.trending_up_rounded,
                value: _priceAlert,
                onChanged: (val) {
                  setState(() => _priceAlert = val);
                  _saveNotifPref(
                    'notif_price_alert',
                    val,
                    'Peringatan Harga Sampah',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Kedaluwarsa Kupon & Voucher',
                subtitle:
                    'Pengingat 3 hari sebelum voucher reward & promo hangus',
                icon: Icons.alarm_rounded,
                value: _voucherExpiry,
                showDivider: false,
                onChanged: (val) {
                  setState(() => _voucherExpiry = val);
                  _saveNotifPref(
                    'notif_voucher_expiry',
                    val,
                    'Notifikasi Kupon & Voucher',
                  );
                },
              ),
            ],
          ),

          // 4. PENJEMPUTAN & LOGISTIK KURIR
          _buildSectionCard(
            'PENJEMPUTAN & LOGISTIK KURIR',
            Icons.local_shipping_outlined,
            [
              _buildNotifTile(
                title: 'Status Live Tracking Kurir',
                subtitle:
                    'Saat kurir ditugaskan, dalam perjalanan, dan tiba di titik temu',
                icon: Icons.navigation_rounded,
                value: _pickupStatus,
                onChanged: (val) {
                  setState(() => _pickupStatus = val);
                  _saveNotifPref(
                    'notif_pickup_status',
                    val,
                    'Status Live Tracking Kurir',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Pengingat Jadwal Setor Sampah',
                subtitle:
                    'Peringatan H-1 dan 1 jam sebelum jadwal penjemputan tiba',
                icon: Icons.calendar_today_rounded,
                value: _pickupReminder,
                onChanged: (val) {
                  setState(() => _pickupReminder = val);
                  _saveNotifPref(
                    'notif_pickup_reminder',
                    val,
                    'Pengingat Jadwal Setor',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Info Cuaca & Keterlambatan Kurir',
                subtitle:
                    'Pemberitahuan jika terjadi hujan deras atau penyesuaian rute penjemputan',
                icon: Icons.thunderstorm_rounded,
                value: _courierDelay,
                showDivider: false,
                onChanged: (val) {
                  setState(() => _courierDelay = val);
                  _saveNotifPref(
                    'notif_courier_delay',
                    val,
                    'Info Keterlambatan Kurir',
                  );
                },
              ),
            ],
          ),

          // 5. GAMIFIKASI & KOMUNITAS ECO-HERO
          _buildSectionCard(
            'GAMIFIKASI & KOMUNITAS ECO-HERO',
            Icons.emoji_events_outlined,
            [
              _buildNotifTile(
                title: 'Pencapaian Lencana & Naik Level',
                subtitle:
                    'Pemberitahuan saat membuka lencana baru atau naik level Eco-Hero',
                icon: Icons.military_tech_rounded,
                value: _badgeLevel,
                onChanged: (val) {
                  setState(() => _badgeLevel = val);
                  _saveNotifPref(
                    'notif_badge_level',
                    val,
                    'Pencapaian Lencana',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Tantangan Mingguan & Event Double Poin',
                subtitle:
                    'Misi daur ulang mingguan, Hari Bumi, dan kupon reward tambahan',
                icon: Icons.local_fire_department_rounded,
                value: _weeklyChallenge,
                onChanged: (val) {
                  setState(() => _weeklyChallenge = val);
                  _saveNotifPref(
                    'notif_weekly_challenge',
                    val,
                    'Tantangan Mingguan',
                  );
                },
              ),
              _buildNotifTile(
                title: 'Pembaruan Peringkat Leaderboard',
                subtitle:
                    'Info saat posisi ranking daur ulang Anda di kota/kelurahan naik',
                icon: Icons.leaderboard_rounded,
                value: _leaderboardRank,
                showDivider: false,
                onChanged: (val) {
                  setState(() => _leaderboardRank = val);
                  _saveNotifPref(
                    'notif_leaderboard_rank',
                    val,
                    'Peringkat Leaderboard',
                  );
                },
              ),
            ],
          ),

          // 6. EDUKASI & TIPS LINGKUNGAN
          _buildSectionCard('EDUKASI & TIPS LINGKUNGAN', Icons.eco_outlined, [
            _buildNotifTile(
              title: 'Tips & Panduan Memilah Sampah',
              subtitle:
                  'Tips cerdas zero-waste, pemilahan organik, anorganik, dan limbah B3',
              icon: Icons.lightbulb_outline_rounded,
              value: _ecoTips,
              onChanged: (val) {
                setState(() => _ecoTips = val);
                _saveNotifPref('notif_eco_tips', val, 'Tips Memilah Sampah');
              },
            ),
            _buildNotifTile(
              title: 'Kabar Lingkungan & Dampak CO2',
              subtitle:
                  'Laporan bulanan jejak emisi karbon yang berhasil Anda cegah',
              icon: Icons.newspaper_rounded,
              value: _ecoNews,
              showDivider: false,
              onChanged: (val) {
                setState(() => _ecoNews = val);
                _saveNotifPref('notif_eco_news', val, 'Kabar Lingkungan');
              },
            ),
          ]),

          // 7. PENGATURAN SUARA & PERANGKAT
          _buildSectionCard('PENGATURAN SUARA & PERANGKAT', Icons.tune_rounded, [
            _buildNotifTile(
              title: 'Push Notification (Perangkat HP)',
              subtitle: 'Notifikasi mengambang dan di bilah status HP',
              icon: Icons.phone_android_rounded,
              value: _pushChannel,
              onChanged: (val) {
                setState(() => _pushChannel = val);
                _saveNotifPref(
                  'notif_channel_push',
                  val,
                  'Push Notification HP',
                );
              },
            ),
            _buildNotifTile(
              title: 'Efek Suara Koin Saat Saldo Masuk',
              subtitle:
                  'Bunyikan gemerincing koin saat uang hasil daur ulang masuk',
              icon: Icons.volume_up_rounded,
              value: _soundCoinEffect,
              extraAction: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => SoundHelper.previewCoinSound(context),
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 14,
                  color: Color(0xFF0D6938),
                ),
                label: const Text(
                  'Tes Suara',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6938),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() => _soundCoinEffect = val);
                _saveNotifPref('notif_sound_coin', val, 'Efek Suara Koin');
                if (val) {
                  SoundHelper.playCoinSound();
                }
              },
            ),
            _buildNotifTile(
              title: 'Getaran Notifikasi',
              subtitle: 'Aktifkan getaran saat ada pemberitahuan penting masuk',
              icon: Icons.vibration_rounded,
              value: _vibrationAlert,
              showDivider: false,
              onChanged: (val) {
                setState(() => _vibrationAlert = val);
                _saveNotifPref('notif_vibration', val, 'Getaran Notifikasi');
              },
            ),
          ]),

          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notif_master', true);
                await prefs.setBool('notif_quiet', false);
                await prefs.setBool('notif_pickup_status', true);
                await prefs.setBool('notif_pickup_reminder', true);
                await prefs.setBool('notif_courier_delay', true);
                await prefs.setBool('notif_reward_deposit', true);
                await prefs.setBool('notif_withdrawal_success', true);
                await prefs.setBool('notif_price_alert', true);
                await prefs.setBool('notif_voucher_expiry', true);
                await prefs.setBool('notif_badge_level', true);
                await prefs.setBool('notif_weekly_challenge', true);
                await prefs.setBool('notif_leaderboard_rank', false);
                await prefs.setBool('notif_eco_tips', true);
                await prefs.setBool('notif_eco_news', false);
                await prefs.setBool('notif_channel_push', true);
                await prefs.setBool('notif_sound_coin', true);
                await prefs.setBool('notif_vibration', true);
                _loadNotifPreferences();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0D6938),
                      content: Text(
                        'Pengaturan notifikasi berhasil dikembalikan ke default!',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Pengaturan Notifikasi ke Default'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==========================================
// 5. KEAMANAN SCREEN
// ==========================================
class KeamananScreen extends StatefulWidget {
  const KeamananScreen({super.key});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  bool _biometricEnabled = true;

  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi Saat Ini',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ulangi Kata Sandi Baru',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6938),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kata sandi berhasil diperbarui!'),
                ),
              );
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ubah PIN Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan 6-digit PIN baru untuk verifikasi penarikan saldo:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6938),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN transaksi berhasil diperbarui!'),
                ),
              );
            },
            child: const Text(
              'Simpan PIN',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF0D6938),
                  ),
                  title: const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Terakhir diubah 30 hari lalu',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin, color: Color(0xFF0D6938)),
                  title: const Text(
                    'PIN Transaksi (6-Digit)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Digunakan untuk konfirmasi penarikan',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChangePinDialog,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF0D6938),
                  ),
                  title: const Text(
                    'Kunci Sidik Jari / Face ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Buka aplikasi menggunakan biometrik',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  value: _biometricEnabled,
                  activeThumbColor: const Color(0xFF0D6938),
                  onChanged: (val) {
                    setState(() => _biometricEnabled = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val ? 'Biometrik diaktifkan' : 'Biometrik dimatikan',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perangkat yang Terhubung',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: Color(0xFF0D6938),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smartphone ini (Aktif Sekarang)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Jakarta, Indonesia • TrashToCash App v1.0',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. PUSAT BANTUAN SCREEN
// ==========================================
class PusatBantuanScreen extends StatelessWidget {
  const PusatBantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Pusat Bantuan & FAQ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Bantuan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6938), Color(0xFF1B5E20)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Bantuan & FAQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Temukan jawaban lengkap dan panduan seputar layanan TrashToCash di bawah ini.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // FAQ Accordion
          const Text(
            'Pertanyaan Populer (FAQ)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                ExpansionTile(
                  title: Text(
                    'Bagaimana cara kerja penjemputan sampah?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Pilih metode Jemput Sampah, pindai sampah Anda untuk estimasi berat & reward, lalu tentukan alamat dan jadwal. Kurir kami akan datang menjemput sesuai jadwal yang dipilih.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  title: Text(
                    'Berapa lama saldo T-Cash masuk setelah setor?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Saldo T-Cash langsung masuk secara instan ke dompet Anda segera setelah petugas loket Drop Point atau Kurir menimbang dan mengonfirmasi penyerahan sampah.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  title: Text(
                    'Kategori sampah apa saja yang dapat ditukar?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'TrashToCash menerima Plastik (PET, HDPE), Kardus & Kertas, Logam & Kaleng, Botol Kaca, serta E-Waste (Elektronik). Pastikan sampah dalam keadaan bersih dan kering.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  title: Text(
                    'Bagaimana cara menarik saldo T-Cash ke rekening bank?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Buka menu Profil atau Beranda, tekan tombol "Tarik Saldo", masukkan nominal penarikan (minimal Rp 100.000) dan pilih rekening bank atau e-wallet tujuan yang sudah terdaftar.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
