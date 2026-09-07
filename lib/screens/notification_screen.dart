import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/screens/history_screen.dart';
import 'package:trashtocash/screens/pickup_status.dart';
import 'package:trashtocash/screens/profile_screen.dart';

enum NotifCategory { all, transaction, pickup, promo, education }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotifCategory _selectedCategory = NotifCategory.all;
  bool _masterNotifEnabled = true;
  bool _quietHoursActive = false;
  String _quietHoursTime = '22:00 - 06:00';

  @override
  void initState() {
    super.initState();
    _loadStatusFromPreferences();
    NotificationHelper.loadNotificationsFromDatabase();
  }

  Future<void> _loadStatusFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _masterNotifEnabled = prefs.getBool('notif_master') ?? true;
        _quietHoursActive = prefs.getBool('notif_quiet') ?? false;
        _quietHoursTime = prefs.getString('notif_quiet_time') ?? '22:00 - 06:00';
      });
    }
  }

  List<AppNotificationItem> _getFilteredList(List<AppNotificationItem> list) {
    if (_selectedCategory == NotifCategory.all) return list;
    return list.where((n) {
      switch (_selectedCategory) {
        case NotifCategory.transaction:
          return n.type == NotificationType.rewardDeposit ||
              n.type == NotificationType.withdrawalSuccess ||
              n.type == NotificationType.priceAlert;
        case NotifCategory.pickup:
          return n.type == NotificationType.pickupStatus ||
              n.type == NotificationType.pickupReminder ||
              n.type == NotificationType.courierDelay;
        case NotifCategory.promo:
          return n.type == NotificationType.voucherExpiry ||
              n.type == NotificationType.weeklyChallenge ||
              n.type == NotificationType.badgeLevel;
        case NotifCategory.education:
          return n.type == NotificationType.ecoTips ||
              n.type == NotificationType.ecoNews;
        case NotifCategory.all:
          return true;
      }
    }).toList();
  }

  void _markAllAsRead() {
    NotificationHelper.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0D6938),
        content: Text('Semua notifikasi telah ditandai dibaca'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  void _showNotificationDetail(AppNotificationItem item) {
    NotificationHelper.markAsRead(item.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  if (item.actionLabel != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6938),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (item.type == NotificationType.pickupStatus ||
                              item.type == NotificationType.pickupReminder) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PickupStatusScreen(),
                              ),
                            );
                          } else if (item.type == NotificationType.rewardDeposit ||
                              item.type == NotificationType.withdrawalSuccess) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            );
                          }
                        },
                        child: Text(
                          item.actionLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestSimulationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.science_rounded, color: Color(0xFF0D6938), size: 22),
                SizedBox(width: 8),
                Text(
                  'Uji Coba Pengiriman Notifikasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih skenario notifikasi di bawah. Pengiriman akan secara langsung mengikuti toggle aktif di Pengaturan Notifikasi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSimulateTile(
              title: '1. Saldo Masuk (+Rp 45.000)',
              subtitle: 'Memeriksa toggle Saldo Masuk & Suara Koin',
              icon: Icons.payments_rounded,
              color: const Color(0xFF0D6938),
              onTap: () async {
                Navigator.pop(ctx);
                final sent = await NotificationHelper.triggerNotification(
                  context: context,
                  type: NotificationType.rewardDeposit,
                  title: 'Saldo Masuk +Rp 45.000 🪙',
                  message: 'Setoran sampah botol plastik 4.5 kg selesai ditimbang. Saldo berhasil masuk ke T-Cash wallet Anda!',
                  actionLabel: 'Lihat',
                );
                if (!sent && mounted) {
                  _showBlockedSnackBar('Saldo Masuk');
                }
              },
            ),
            _buildSimulateTile(
              title: '2. Live Tracking: Kurir Menuju Lokasi',
              subtitle: 'Memeriksa toggle Status Penjemputan Kurir',
              icon: Icons.local_shipping_outlined,
              color: Colors.green,
              onTap: () async {
                Navigator.pop(ctx);
                final sent = await NotificationHelper.triggerNotification(
                  context: context,
                  type: NotificationType.pickupStatus,
                  title: 'Kurir Sedang Menuju Rumah Anda 🚚',
                  message: 'Kurir Joko Santoso sedang dalam perjalanan. Estimasi sampai 8 menit lagi.',
                  actionLabel: 'Lacak',
                );
                if (!sent && mounted) {
                  _showBlockedSnackBar('Status Penjemputan');
                }
              },
            ),
            _buildSimulateTile(
              title: '3. Price Alert: Kenaikan Harga Sampah',
              subtitle: 'Memeriksa toggle Peringatan Kenaikan Harga',
              icon: Icons.trending_up_rounded,
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(ctx);
                final sent = await NotificationHelper.triggerNotification(
                  context: context,
                  type: NotificationType.priceAlert,
                  title: 'Harga Kardus & Logam Naik! 📈',
                  message: 'Harga kardus bekas hari ini naik menjadi Rp 2.800/kg. Setorkan sampahmu sekarang!',
                );
                if (!sent && mounted) {
                  _showBlockedSnackBar('Peringatan Harga');
                }
              },
            ),
            _buildSimulateTile(
              title: '4. Tips Cerdas Memilah Sampah',
              subtitle: 'Memeriksa toggle Tips & Edukasi Lingkungan',
              icon: Icons.lightbulb_outline_rounded,
              color: Colors.amber.shade800,
              onTap: () async {
                Navigator.pop(ctx);
                final sent = await NotificationHelper.triggerNotification(
                  context: context,
                  type: NotificationType.ecoTips,
                  title: 'Tips Memilah Sampah Plastik 💡',
                  message: 'Pastikan botol plastik dicuci bersih dan diremukkan sebelum disetorkan agar menghemat tempat penimbangan.',
                );
                if (!sent && mounted) {
                  _showBlockedSnackBar('Tips Lingkungan');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBlockedSnackBar(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text('Notifikasi "$featureName" dinonaktifkan di Pengaturan Notifikasi Anda.'),
        action: SnackBarAction(
          label: 'Ubah',
          textColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PengaturanNotifikasiScreen()),
            );
            _loadStatusFromPreferences();
          },
        ),
      ),
    );
  }

  Widget _buildSimulateTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF0D6938)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: ValueListenableBuilder<int>(
          valueListenable: NotificationHelper.unreadCountNotifier,
          builder: (context, unreadCount, _) {
            return Row(
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            tooltip: 'Uji Coba Kirim Notifikasi',
            onPressed: _showTestSimulationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Pengaturan Notifikasi',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PengaturanNotifikasiScreen()),
              );
              _loadStatusFromPreferences();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotificationItem>>(
        valueListenable: NotificationHelper.notificationsNotifier,
        builder: (context, allNotifications, _) {
          final filtered = _getFilteredList(allNotifications);
          final unreadCount = allNotifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              // BANNER PERINGATAN JIKA MASTER NOTIF MATI ATAU JAM TENANG AKTIF
              if (!_masterNotifEnabled)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_off_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Semua notifikasi sedang dibisukan di pengaturan.',
                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: Colors.white24,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notif_master', true);
                          _loadStatusFromPreferences();
                        },
                        child: const Text('Aktifkan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else if (_quietHoursActive)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1E2822),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime_rounded, color: Color(0xFF4ADE80), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode Jam Tenang Aktif ($_quietHoursTime)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter Tabs (Horizontal scrolling chips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('Semua (${allNotifications.length})', NotifCategory.all, isDark),
                            const SizedBox(width: 6),
                            _buildCategoryChip('Transaksi & Cuan', NotifCategory.transaction, isDark),
                            const SizedBox(width: 6),
                            _buildCategoryChip('Penjemputan Kurir', NotifCategory.pickup, isDark),
                            const SizedBox(width: 6),
                            _buildCategoryChip('Promo & Misi', NotifCategory.promo, isDark),
                            const SizedBox(width: 6),
                            _buildCategoryChip('Edukasi', NotifCategory.education, isDark),
                          ],
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markAllAsRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Baca Semua', style: TextStyle(fontSize: 11, color: Color(0xFF0D6938), fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(item, isDark);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, NotifCategory category, bool isDark) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6938)
              : (isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D6938)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item, bool isDark) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        final currentList = List<AppNotificationItem>.from(NotificationHelper.notificationsNotifier.value);
        currentList.removeWhere((n) => n.id == item.id);
        NotificationHelper.notificationsNotifier.value = currentList;
        NotificationHelper.updateUnreadCount();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNotificationDetail(item),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isRead
                  ? Theme.of(context).cardColor
                  : (isDark ? const Color(0xFF1E2F23) : const Color(0xFFF0FDF4)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead
                    ? (isDark ? Colors.white10 : Colors.grey.shade200)
                    : const Color(0xFF0D6938).withValues(alpha: 0.35),
                width: item.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D6938),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 54,
                color: Color(0xFF0D6938),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Notifikasi aktivitas setoran sampah, transaksi, dan promo akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showTestSimulationDialog,
              icon: const Icon(Icons.science_outlined, size: 16, color: Colors.white),
              label: const Text('Kirim Notifikasi Uji Coba', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
