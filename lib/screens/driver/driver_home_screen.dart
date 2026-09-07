import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';
import 'package:trashtocash/screens/driver/driver_active_order_screen.dart';
import 'package:trashtocash/screens/driver/driver_profile_screen.dart';
import 'package:trashtocash/screens/driver/driver_wallet_screen.dart';
import 'package:trashtocash/screens/home.dart';
import 'package:trashtocash/services/location_service.dart';
import 'package:trashtocash/widgets/live_google_map_widget.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _bottomNavIndex = 0;
  String _selectedFilter = 'Semua'; // 'Semua', 'Organik', 'Non-Organik', '< 2 km'

  @override
  void initState() {
    super.initState();
    DriverHelper.instance.loadOrdersFromDatabase();
    LocationService.instance.requestLocationPermission().then((_) {
      LocationService.instance.startLiveTracking();
    });
  }

  Future<void> _createSimulatedOrder() async {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final randomId = 'TRX-JMP-$suffix';
    final simulatedPickup = WastePickupModel(
      transactionId: randomId,
      wasteName: 'Plastik PET & Botol Daur Ulang',
      wasteType: 'Non-Organik',
      weightKg: 5.0,
      ratePerKg: 10000.0,
      totalReward: 50000.0,
      method: 'Jemput Sampah',
      pickupAddress: 'Jl. Surya Kencana No. $suffix, Jakarta',
      pickupDate: 'Hari Ini',
      pickupTime: '15:00 WIB',
      pickupNotes: 'Sudah dipilah dan siap di teras depan.',
      status: 'Menunggu Penjemputan',
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertWastePickup(simulatedPickup);
    await DriverHelper.instance.loadOrdersFromDatabase();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0D6938),
          content: Text('Order baru $randomId tersimpan di SQLite & aktif di radar! 📥'),
        ),
      );
    }
  }

  void _switchToUserMode() {
    DriverHelper.instance.isDriverModeActive.value = false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeTrashToCash()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabPages = [
      _buildRadarOrdersTab(isDark),
      _buildActiveOrHistoryTab(isDark),
      const DriverWalletScreen(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121915) : const Color(0xFFF7FAF8),
      appBar: _buildDriverAppBar(isDark),
      body: tabPages[_bottomNavIndex],
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  PreferredSizeWidget _buildDriverAppBar(bool isDark) {
    return AppBar(
      backgroundColor: const Color(0xFF0D6938),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: ValueListenableBuilder<DriverProfileModel>(
        valueListenable: DriverHelper.instance.profileNotifier,
        builder: (context, profile, _) {
          return Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.black87, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                profile.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Mitra Kurir • ${profile.vehiclePlate}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Online / Offline Switch
        ValueListenableBuilder<DriverProfileModel>(
          valueListenable: DriverHelper.instance.profileNotifier,
          builder: (context, profile, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => DriverHelper.instance.toggleOnlineStatus(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.isOnline
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: profile.isOnline ? Colors.white : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Switch Back to User Mode Button
                IconButton(
                  icon: const Icon(Icons.switch_account_outlined, color: Colors.white),
                  tooltip: 'Beralih ke Mode Pengguna',
                  onPressed: _switchToUserMode,
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRadarOrdersTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await DriverHelper.instance.loadOrdersFromDatabase();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Mode Switch Banner
            _buildModeSwitchNotice(isDark),
            const SizedBox(height: 14),

            // Performance Dashboard Card
            _buildDriverStatOverview(isDark),
            const SizedBox(height: 18),

            // Ongoing Active Order Floating Reminder (if exists)
            ValueListenableBuilder<DriverOrderItemModel?>(
              valueListenable: DriverHelper.instance.activeOrderNotifier,
              builder: (context, activeOrder, _) {
                if (activeOrder == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOngoingActiveOrderBanner(activeOrder, isDark),
                );
              },
            ),

            // Radar Header & Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar,
                        color: Color(0xFF0D6938),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Radar Order Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<List<DriverOrderItemModel>>(
                  valueListenable: DriverHelper.instance.availableOrdersNotifier,
                  builder: (context, orders, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orders.length} Tersedia',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Google Maps Live Radar View
            ValueListenableBuilder<UserGpsState>(
              valueListenable: LocationService.instance.userLocationNotifier,
              builder: (context, userGps, _) {
                return LiveGoogleMapWidget(
                  perspective: MapPerspective.driver,
                  driverName: 'Saya (Mitra Driver)',
                  customerName: 'Order Warga',
                  customerLat: userGps.latitude + 0.006,
                  customerLng: userGps.longitude + 0.008,
                  height: 220,
                  showNavigationBanner: false,
                );
              },
            ),
            const SizedBox(height: 14),

            // Filter Chips
            _buildFilterChips(isDark),
            const SizedBox(height: 12),

            // SQLite Sync & Quick Simulation Bar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF0D6938)),
                    label: const Text(
                      'Refresh SQLite',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                    onPressed: () async {
                      await DriverHelper.instance.loadOrdersFromDatabase();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Data radar berhasil disinkronkan dari database SQLite! 🔄'),
                            duration: Duration(milliseconds: 1200),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_task, size: 16, color: Colors.white),
                    label: const Text(
                      '+ Order SQLite',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _createSimulatedOrder,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Orders Feed
            ValueListenableBuilder<DriverProfileModel>(
              valueListenable: DriverHelper.instance.profileNotifier,
              builder: (context, profile, _) {
                if (!profile.isOnline) {
                  return _buildOfflineStateCard(isDark);
                }

                return ValueListenableBuilder<List<DriverOrderItemModel>>(
                  valueListenable: DriverHelper.instance.availableOrdersNotifier,
                  builder: (context, orders, _) {
                    final filtered = _getFilteredOrders(orders);

                    if (filtered.isEmpty) {
                      return _buildEmptyRadarState(isDark);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(filtered[index], isDark);
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitchNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D6938).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D6938).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Color(0xFF0D6938), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anda berada di Mode Mitra Kurir TrashToCash. Siap menerima order penjemputan dari warga.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF0D6938),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatOverview(bool isDark) {
    return ValueListenableBuilder<DriverProfileModel>(
      valueListenable: DriverHelper.instance.profileNotifier,
      builder: (context, profile, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D6938), Color(0xFF1B8A4D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Penghasilan & Komisi',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${profile.walletBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D6938),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet, size: 16),
                    label: const Text(
                      'Tarik Dana',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _bottomNavIndex = 2; // Switch to Wallet Tab
                      });
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Jemput Selesai', '${profile.completedPickupsToday} Order', Icons.check_circle_outline),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatColumn('Total Angkutan', '${profile.totalKgToday.toStringAsFixed(1)} kg', Icons.scale_outlined),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatColumn('Radius Tugas', '${profile.operationalRadiusKm.toStringAsFixed(0)} km', Icons.near_me_outlined),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingActiveOrderBanner(DriverOrderItemModel activeOrder, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverActiveOrderScreen(order: activeOrder),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2B22) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0D6938), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF0D6938),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.navigation, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6938),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ORDER SEDANG BERJALAN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeOrder.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: activeOrder.status.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeOrder.userName} • ${activeOrder.wasteName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    activeOrder.userAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF0D6938), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['Semua', 'Organik', 'Non-Organik', '< 2 km'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              selectedColor: const Color(0xFF0D6938),
              backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF0D6938)
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<DriverOrderItemModel> _getFilteredOrders(List<DriverOrderItemModel> list) {
    if (_selectedFilter == 'Organik') {
      return list.where((o) => o.wasteType.toLowerCase().contains('organik') && !o.wasteType.toLowerCase().contains('non')).toList();
    } else if (_selectedFilter == 'Non-Organik') {
      return list.where((o) => o.wasteType.toLowerCase().contains('non-organik')).toList();
    } else if (_selectedFilter == '< 2 km') {
      return list.where((o) => o.distanceKm <= 2.0).toList();
    }
    return list;
  }

  Widget _buildOrderCard(DriverOrderItemModel order, bool isDark) {
    final isOrganic = order.wasteType.toLowerCase().contains('organik') &&
        !order.wasteType.toLowerCase().contains('non');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOrganic
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOrganic ? Icons.energy_savings_leaf : Icons.recycling,
                      color: isOrganic ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.wasteName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${order.wasteType} • Estimasi ${order.estimatedWeightKg.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me, size: 12, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '${order.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // User & Address Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF0D6938), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.userAddress,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (order.pickupNotes != null && order.pickupNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF263229) : const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: "${order.pickupNotes}"',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Compensation & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ongkir / Komisi Mitra',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey),
                  ),
                  Text(
                    '+Rp ${order.deliveryFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6938),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final current = List<DriverOrderItemModel>.from(
                        DriverHelper.instance.availableOrdersNotifier.value,
                      );
                      current.removeWhere((o) => o.transactionId == order.transactionId);
                      DriverHelper.instance.availableOrdersNotifier.value = current;
                    },
                    child: Text(
                      'Abaikan',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await DriverHelper.instance.acceptOrder(order, context: context);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverActiveOrderScreen(order: order),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Terima Jemputan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRadarState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar,
                color: Color(0xFF0D6938),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sedang Memindai Order di Sekitar...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada pesanan jemput sampah baru dalam radius ${DriverHelper.instance.profileNotifier.value.operationalRadiusKm.toStringAsFixed(0)} km. Anda akan menerima notifikasi instan saat warga memesan jemput.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text(
                'Segarkan Radar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                DriverHelper.instance.loadOrdersFromDatabase();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineStateCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.power_settings_new, size: 48, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              'Status Anda Sedang Offline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktifkan switch Online di pojok kanan atas untuk mulai menerima notifikasi & orderan jemput sampah dari warga.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => DriverHelper.instance.toggleOnlineStatus(),
              child: const Text('Aktifkan Status Online', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrHistoryTab(bool isDark) {
    return ValueListenableBuilder<List<DriverOrderItemModel>>(
      valueListenable: DriverHelper.instance.completedOrdersNotifier,
      builder: (context, history, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Penjemputan Selesai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar penjemputan sampah yang telah berhasil Anda selesaikan dan ditransfer komisinya.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A241E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum Ada Riwayat Selesai Hari Ini',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Terima pesanan di tab Radar untuk mulai mengumpulkan komisi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = history[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A241E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF4EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Color(0xFF0D6938), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.wasteName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${item.actualWeightKg?.toStringAsFixed(1) ?? item.estimatedWeightKg.toStringAsFixed(1)} kg • ${item.userName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+Rp ${item.deliveryFee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D6938),
                                ),
                              ),
                              const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _bottomNavIndex,
      backgroundColor: isDark ? const Color(0xFF18221C) : Colors.white,
      indicatorColor: const Color(0xFF0D6938).withValues(alpha: 0.18),
      onDestinationSelected: (idx) => setState(() => _bottomNavIndex = idx),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.radar_outlined),
          selectedIcon: Icon(Icons.radar, color: Color(0xFF0D6938)),
          label: 'Radar Order',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history, color: Color(0xFF0D6938)),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF0D6938)),
          label: 'Komisi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: Color(0xFF0D6938)),
          label: 'Profil Mitra',
        ),
      ],
    );
  }
}
