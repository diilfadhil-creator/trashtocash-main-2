import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/models/user_level_model.dart';
import 'package:trashtocash/screens/chosemethod_screen.dart';
import 'package:trashtocash/screens/driver/driver_home_screen.dart';
import 'package:trashtocash/screens/drop_location.dart';
import 'package:trashtocash/screens/history_screen.dart';
import 'package:trashtocash/screens/live_camera_scan_screen.dart';
import 'package:trashtocash/screens/notification_screen.dart';
import 'package:trashtocash/screens/panduan_sampah_screen.dart';
import 'package:trashtocash/screens/profile_screen.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';
import 'package:trashtocash/screens/withdrawal_screen.dart';
import 'package:trashtocash/widgets/user_level_sheet.dart';

import 'login.dart';

class HomeTrashToCash extends StatefulWidget {
  final int initialTabIndex;
  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);

  const HomeTrashToCash({super.key, this.initialTabIndex = 0});

  static void switchToTab(int index) {
    tabNotifier.value = index;
  }

  @override
  State<HomeTrashToCash> createState() => _HomeTrashToCashState();
}

class _HomeTrashToCashState extends State<HomeTrashToCash> {
  int _currentIndex = 0;
  int? _activeQuickAction;
  String _userName = 'TrashToCash Member';
  String _userEmail = 'user@email.com';
  String _avatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';

  double _totalDepositedKg = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    HomeTrashToCash.tabNotifier.value = widget.initialTabIndex;
    HomeTrashToCash.tabNotifier.addListener(_onTabNotified);
    DatabaseHelper.historyUpdateNotifier.addListener(_onHistoryChanged);
    _loadUserData();
  }

  void _onTabNotified() {
    if (mounted && _currentIndex != HomeTrashToCash.tabNotifier.value) {
      setState(() {
        _currentIndex = HomeTrashToCash.tabNotifier.value;
      });
    }
  }

  void _onHistoryChanged() {
    if (mounted) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    HomeTrashToCash.tabNotifier.removeListener(_onTabNotified);
    DatabaseHelper.historyUpdateNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ??
        prefs.getString('userEmail') ??
        prefs.getString('registeredEmail') ??
        'user@email.com';

    String name = prefs.getString('userName') ??
        prefs.getString('registeredName') ??
        'TrashToCash Member';

    try {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        name = user.name;
      }
    } catch (_) {}

    final savedAvatar = prefs.getString('userAvatarUrl') ?? '';
    DatabaseHelper.userAvatarNotifier.value = savedAvatar;
    DatabaseHelper.userNameNotifier.value = name;

    setState(() {
      _userName = name;
      _userEmail = email;
      _avatarUrl = savedAvatar;
    });

    // Sinkronisasi saldo dompet & statistik dari database SQLite
    await DatabaseHelper.instance.syncUserWalletFromDb(email);
    try {
      final wallet = await DatabaseHelper.instance.getOrCreateUserWallet(email);
      if (mounted) {
        setState(() {
          _totalDepositedKg = (wallet['total_deposited_kg'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (_) {}

    // Muat notifikasi pengguna dari SQLite
    NotificationHelper.loadNotificationsFromDatabase(email);
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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const MenyerahkanSampah(),
      const HistoryScreen(),
      ProfileScreen(
        userName: _userName,
        userEmail: _userEmail,
        onLogout: () => _logout(context),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF0D6938),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 3),
                    child: Row(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: DatabaseHelper.userAvatarNotifier,
                          builder: (context, currentAvatar, _) {
                            final hasCustomImg = currentAvatar.isNotEmpty &&
                                (currentAvatar.startsWith('http://') ||
                                 currentAvatar.startsWith('https://') ||
                                 File(currentAvatar).existsSync());

                            return Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: hasCustomImg
                                  ? CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: _getAvatarImageProvider(currentAvatar),
                                    )
                                  : const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<String>(
                              valueListenable: DatabaseHelper.userNameNotifier,
                              builder: (context, currentName, _) {
                                return Text(
                                  currentName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            Text(
                              _userEmail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.two_wheeler,
                            color: Colors.white,
                          ),
                          tooltip: 'Mode Mitra Kurir / Driver',
                          onPressed: () {
                            DriverHelper.instance.isDriverModeActive.value = true;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DriverHomeScreen(),
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: NotificationHelper.unreadCountNotifier,
                          builder: (context, unreadCount, _) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Pusat Notifikasi',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(child: pages[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: const Color(0xFF0D6938),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _activeQuickAction = null;
            } else if (index == 1) {
              _activeQuickAction = 0;
            } else if (index == 2) {
              _activeQuickAction = 1;
            } else {
              _activeQuickAction = null;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recycling),
            label: 'Deposit',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Home Screen Content Layout
  Widget _buildHomeContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: DatabaseHelper.userBalanceNotifier,
                      builder: (context, balance, _) {
                        return Text(
                          DatabaseHelper.formatRupiah(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Rupiah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
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
                    color: Color(0xFF0D6938),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D6938),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  label: const Text(
                    'Tarik Tunai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              color: Color(0xFF0D6938),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dampak',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_totalDepositedKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sampah terdaur ulang',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: DatabaseHelper.userEcoPointsNotifier,
                  builder: (context, ecoPoints, _) {
                    final progression = UserLevelProgression.fromStats(
                      points: ecoPoints,
                      totalKg: _totalDepositedKg,
                    );
                    final tier = progression.currentTier;

                    return GestureDetector(
                      onTap: () => UserLevelSheet.show(
                        context,
                        totalKg: _totalDepositedKg,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tier.primaryColor.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tier.primaryColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: tier.backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        tier.icon,
                                        color: tier.primaryColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lvl ${tier.level}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: tier.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: tier.primaryColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tier.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              progression.isMaxLevel
                                  ? '$ecoPoints Eco-Points'
                                  : '$ecoPoints/${progression.nextTier?.minPoints} Poin',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mitra Driver Mode Banner
          InkWell(
            onTap: () {
              DriverHelper.instance.isDriverModeActive.value = true;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverHomeScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                    blurRadius: 8,
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
                    child: const Icon(
                      Icons.electric_moped,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Mitra Driver / Kurir',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Terima order jemput & raih komisi tunai',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Buka Radar 🛵',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Banner Tukar Eco-Points Promo
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RewardRedemptionScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD84315), Color(0xFFF4511E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD84315).withValues(alpha: 0.25),
                    blurRadius: 8,
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
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tukar Eco-Points & Voucher 🎁',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Voucher Belanja Alfamart, Indomaret, Pulsa & PLN',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tukar 🛒',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD84315),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Aksi Cepat Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aksi Cepat',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionItem(
                      icon: Icons.recycling,
                      label: 'Setor',
                      isSelected: _activeQuickAction == 0,
                      onTap: () {
                        setState(() {
                          _activeQuickAction = 0;
                          _currentIndex = 1;
                        });
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.camera_alt,
                      label: 'Scan AI',
                      isSelected: _activeQuickAction == 3,
                      onTap: () {
                        setState(() {
                          _activeQuickAction = 3;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LiveCameraScanScreen(isPickup: false),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _activeQuickAction = null;
                            });
                          }
                        });
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.card_giftcard,
                      label: 'Tukar Poin',
                      isSelected: _activeQuickAction == 4,
                      onTap: () {
                        setState(() {
                          _activeQuickAction = 4;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RewardRedemptionScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _activeQuickAction = null;
                            });
                          }
                        });
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.history,
                      label: 'Riwayat',
                      isSelected: _activeQuickAction == 1,
                      onTap: () {
                        setState(() {
                          _activeQuickAction = 1;
                          _currentIndex = 2;
                        });
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi',
                      isSelected: _activeQuickAction == 2,
                      onTap: () {
                        setState(() {
                          _activeQuickAction = 2;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DropPointLocationScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _activeQuickAction = null;
                            });
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Panduan Daur Ulang Section (Interactive)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Panduan Daur Ulang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PanduanDaurUlangScreen(
                        initialTabIndex: 0,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFF0D6938),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Banner Panduan Fitur Scan Foto AI (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LiveCameraScanScreen(isPickup: false),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D6938), Color(0xFF198754)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FITUR FOTO AI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Panduan Scan Foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pelajari cara mudah deteksi otomatis sampah & tips foto terbaik.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2 Kategori Card: Organik & Non-Organik (Clickable)
          Row(
            children: [
              // Kartu Organik
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PanduanDaurUlangScreen(
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                        ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.energy_savings_leaf,
                                  color: Color(0xFF0D6938),
                                  size: 20,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_outward,
                                size: 14,
                                color: Color(0xFF0D6938),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Organik',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sisa makanan, daun kering, sayuran.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Text(
                                'Buka Panduan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D6938),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 12,
                                color: Color(0xFF0D6938),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Kartu Non-Organik
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PanduanDaurUlangScreen(
                            initialTabIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                        ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  color: Color(0xFF0D6938),
                                  size: 20,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_outward,
                                size: 14,
                                color: Color(0xFF1565C0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Non-Organik',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Plastik, kertas, logam, kaca, e-waste.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Text(
                                'Buka Panduan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 12,
                                color: Color(0xFF1565C0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Aktivitas Terkini Section
          _buildRecentActivitiesSection(isDark),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terkini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Switch to History tab
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF0D6938),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: DatabaseHelper.historyUpdateNotifier,
          builder: (context, _, __) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getUserWalletTransactions(_userEmail),
              builder: (context, snapshot) {
                final transactions = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ),
                  );
                }

                if (transactions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
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
                                'Belum Ada Aktivitas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Setoran sampah atau penukaran poin Anda akan muncul di sini.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recentList = transactions.take(3).toList();
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentList.length,
                    separatorBuilder: (ctx, i) => Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                    ),
                    itemBuilder: (ctx, i) {
                      final trx = recentList[i];
                      final type = trx['type'] as String? ?? 'deposit';
                      final title = trx['title'] as String? ?? 'Transaksi';
                      final desc = trx['description'] as String? ?? '';
                      final amount = (trx['amount'] as num?)?.toDouble() ?? 0.0;
                      final createdAt = (trx['created_at'] as String?) ?? '';
                      final date = createdAt.contains('T')
                          ? createdAt.split('T').first
                          : createdAt;

                      Color iconColor;
                      IconData iconData;
                      String amountStr;

                      if (type == 'reward_redemption') {
                        iconColor = const Color(0xFFE65100);
                        iconData = Icons.card_giftcard_rounded;
                        amountStr = 'Tukar Voucher';
                      } else if (type == 'withdrawal') {
                        iconColor = const Color(0xFF1565C0);
                        iconData = Icons.account_balance_wallet_outlined;
                        amountStr = '-${DatabaseHelper.formatRupiah(amount.abs())}';
                      } else {
                        iconColor = const Color(0xFF0D6938);
                        iconData = Icons.recycling;
                        amountStr = '+${DatabaseHelper.formatRupiah(amount.abs())}';
                      }

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = 2; // Open History Screen
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$date • $desc',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                amountStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? const Color(0xFF263229)
        : const Color(0xFFF4F8F5);
    const activeBg = Color(0xFF0D6938);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : defaultBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? activeBg
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeBg.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF0D6938)),
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0D6938)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
