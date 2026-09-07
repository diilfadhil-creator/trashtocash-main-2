import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';

enum NotificationType {
  rewardDeposit,
  withdrawalSuccess,
  priceAlert,
  voucherExpiry,
  pickupStatus,
  pickupReminder,
  courierDelay,
  badgeLevel,
  weeklyChallenge,
  leaderboardRank,
  ecoTips,
  ecoNews,
  general,
}

class AppNotificationItem {
  final int id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isRead;
  final String? actionLabel;
  final VoidCallback? onAction;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRead = false,
    this.actionLabel,
    this.onAction,
  });
}

/// Pusat integrasi notifikasi aplikasi TrashToCash yang terhubung ke SQLite Database
class NotificationHelper {
  static final ValueNotifier<List<AppNotificationItem>> notificationsNotifier =
      ValueNotifier<List<AppNotificationItem>>([]);

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Muat riwayat notifikasi dari SQLite Database
  static Future<void> loadNotificationsFromDatabase([String? userEmail]) async {
    try {
      final dbNotifs = await DatabaseHelper.instance.getNotifications(userEmail);
      if (dbNotifs.isNotEmpty) {
        final List<AppNotificationItem> items = [];
        for (final n in dbNotifs) {
          final typeStr = n['type'] as String? ?? 'general';
          final type = NotificationType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => NotificationType.general,
          );

          final iconProps = _getIconPropsForType(type);

          items.add(
            AppNotificationItem(
              id: n['id'] as int,
              title: n['title'] as String? ?? '',
              message: n['message'] as String? ?? '',
              time: n['time'] as String? ?? 'Baru saja',
              type: type,
              icon: iconProps['icon'] as IconData,
              iconColor: iconProps['color'] as Color,
              iconBg: iconProps['bg'] as Color,
              isRead: (n['is_read'] as int? ?? 0) == 1,
              actionLabel: n['action_label'] as String?,
            ),
          );
        }
        notificationsNotifier.value = items;
        updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error loading notifications from database: $e');
    }
  }

  static Map<String, dynamic> _getIconPropsForType(NotificationType type) {
    switch (type) {
      case NotificationType.rewardDeposit:
        return {
          'icon': Icons.payments_rounded,
          'color': const Color(0xFF0D6938),
          'bg': const Color(0xFFEAF4EE),
        };
      case NotificationType.withdrawalSuccess:
        return {
          'icon': Icons.account_balance_wallet_outlined,
          'color': const Color(0xFF1E88E5),
          'bg': const Color(0xFFE3F2FD),
        };
      case NotificationType.priceAlert:
        return {
          'icon': Icons.trending_up_rounded,
          'color': const Color(0xFF0D6938),
          'bg': const Color(0xFFEAF4EE),
        };
      case NotificationType.voucherExpiry:
        return {
          'icon': Icons.alarm_rounded,
          'color': Colors.orange,
          'bg': const Color(0xFFFFF3E0),
        };
      case NotificationType.pickupStatus:
        return {
          'icon': Icons.local_shipping_outlined,
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
        };
      case NotificationType.pickupReminder:
        return {
          'icon': Icons.calendar_today_rounded,
          'color': Colors.purple,
          'bg': const Color(0xFFF3E5F5),
        };
      case NotificationType.courierDelay:
        return {
          'icon': Icons.thunderstorm_rounded,
          'color': Colors.amber.shade800,
          'bg': Colors.amber.shade50,
        };
      case NotificationType.badgeLevel:
        return {
          'icon': Icons.military_tech_rounded,
          'color': const Color(0xFFFFD700),
          'bg': const Color(0xFFFFFDE7),
        };
      case NotificationType.weeklyChallenge:
        return {
          'icon': Icons.card_giftcard_outlined,
          'color': const Color(0xFFE67E22),
          'bg': const Color(0xFFFEF5E7),
        };
      case NotificationType.leaderboardRank:
        return {
          'icon': Icons.leaderboard_rounded,
          'color': Colors.teal,
          'bg': Colors.teal.shade50,
        };
      case NotificationType.ecoTips:
        return {
          'icon': Icons.lightbulb_outline_rounded,
          'color': Colors.green,
          'bg': Colors.green.shade50,
        };
      case NotificationType.ecoNews:
        return {
          'icon': Icons.newspaper_rounded,
          'color': Colors.blueGrey,
          'bg': Colors.blueGrey.shade50,
        };
      case NotificationType.general:
        return {
          'icon': Icons.notifications_active_outlined,
          'color': const Color(0xFF0D6938),
          'bg': const Color(0xFFEAF4EE),
        };
    }
  }

  static void updateUnreadCount() {
    unreadCountNotifier.value =
        notificationsNotifier.value.where((n) => !n.isRead).length;
  }

  /// Memeriksa apakah suatu tipe notifikasi diizinkan oleh pengaturan pengguna di SharedPreferences
  static Future<bool> isNotificationEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Cek Master Switch
    final masterNotif = prefs.getBool('notif_master') ?? true;
    if (!masterNotif) return false;

    // 2. Cek kategori spesifik
    switch (type) {
      case NotificationType.rewardDeposit:
        return prefs.getBool('notif_reward_deposit') ?? true;
      case NotificationType.withdrawalSuccess:
        return prefs.getBool('notif_withdrawal_success') ?? true;
      case NotificationType.priceAlert:
        return prefs.getBool('notif_price_alert') ?? true;
      case NotificationType.voucherExpiry:
        return prefs.getBool('notif_voucher_expiry') ?? true;
      case NotificationType.pickupStatus:
        return prefs.getBool('notif_pickup_status') ?? true;
      case NotificationType.pickupReminder:
        return prefs.getBool('notif_pickup_reminder') ?? true;
      case NotificationType.courierDelay:
        return prefs.getBool('notif_courier_delay') ?? true;
      case NotificationType.badgeLevel:
        return prefs.getBool('notif_badge_level') ?? true;
      case NotificationType.weeklyChallenge:
        return prefs.getBool('notif_weekly_challenge') ?? true;
      case NotificationType.leaderboardRank:
        return prefs.getBool('notif_leaderboard_rank') ?? false;
      case NotificationType.ecoTips:
        return prefs.getBool('notif_eco_tips') ?? true;
      case NotificationType.ecoNews:
        return prefs.getBool('notif_eco_news') ?? false;
      case NotificationType.general:
        return true;
    }
  }

  /// Memicu pengiriman notifikasi baru ke dalam aplikasi dan menyimpannya di SQLite Database
  static Future<bool> triggerNotification({
    required BuildContext context,
    required NotificationType type,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool showInAppBanner = true,
  }) async {
    final isAllowed = await isNotificationEnabled(type);
    if (!isAllowed) {
      debugPrint('Notifikasi $type diabaikan karena dinonaktifkan di pengaturan pengguna.');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final vibration = prefs.getBool('notif_vibration') ?? true;
    final email = prefs.getString('email') ?? prefs.getString('userEmail') ?? 'user@email.com';

    // Play sounds
    if (type == NotificationType.rewardDeposit) {
      await SoundHelper.playCoinSound();
    } else if (type == NotificationType.withdrawalSuccess) {
      await SoundHelper.playWithdrawalSuccessSound();
    }

    if (vibration && type != NotificationType.rewardDeposit && type != NotificationType.withdrawalSuccess) {
      HapticFeedback.lightImpact();
    }

    // Simpan ke SQLite Database
    int insertedId = DateTime.now().millisecondsSinceEpoch;
    try {
      insertedId = await DatabaseHelper.instance.insertNotification(
        userEmail: email,
        title: title,
        message: message,
        type: type.name,
        time: 'Baru saja',
        actionLabel: actionLabel,
      );
    } catch (e) {
      debugPrint('Error inserting notification to database: $e');
    }

    final iconProps = _getIconPropsForType(type);
    final iconData = iconProps['icon'] as IconData;
    final iconColor = iconProps['color'] as Color;
    final iconBg = iconProps['bg'] as Color;

    // Tambahkan notifikasi ke dalam daftar reaktif
    final newItem = AppNotificationItem(
      id: insertedId,
      title: title,
      message: message,
      time: 'Baru saja',
      type: type,
      icon: iconData,
      iconColor: iconColor,
      iconBg: iconBg,
      isRead: false,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    final currentList = List<AppNotificationItem>.from(notificationsNotifier.value);
    currentList.insert(0, newItem);
    notificationsNotifier.value = currentList;
    updateUnreadCount();

    // Tampilkan floating banner di layar jika konteks aktif
    if (showInAppBanner && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E2822),
          elevation: 6,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: const Color(0xFF4ADE80),
                  onPressed: onAction ?? () {},
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    return true;
  }

  /// Tandai notifikasi sebagai terbaca
  static Future<void> markAsRead(int id) async {
    try {
      await DatabaseHelper.instance.markNotificationAsRead(id);
      final list = notificationsNotifier.value;
      for (final item in list) {
        if (item.id == id) {
          item.isRead = true;
          break;
        }
      }
      notificationsNotifier.value = List.from(list);
      updateUnreadCount();
    } catch (_) {}
  }

  /// Tandai semua notifikasi terbaca
  static Future<void> markAllAsRead([String? email]) async {
    try {
      await DatabaseHelper.instance.markAllNotificationsAsRead(email);
      final list = notificationsNotifier.value;
      for (final item in list) {
        item.isRead = true;
      }
      notificationsNotifier.value = List.from(list);
      updateUnreadCount();
    } catch (_) {}
  }

  /// Hapus satu notifikasi
  static Future<void> deleteNotification(int id) async {
    try {
      await DatabaseHelper.instance.deleteNotification(id);
      final list = notificationsNotifier.value;
      list.removeWhere((item) => item.id == id);
      notificationsNotifier.value = List.from(list);
      updateUnreadCount();
    } catch (_) {}
  }

  /// Hapus semua notifikasi
  static Future<void> clearAll([String? email]) async {
    try {
      await DatabaseHelper.instance.clearAllNotifications(email);
      notificationsNotifier.value = [];
      updateUnreadCount();
    } catch (_) {}
  }
}
