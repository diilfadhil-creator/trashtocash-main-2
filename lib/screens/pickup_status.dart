import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/helpers/external_driver_launcher.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/helpers/realtime_gps_sync_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/screens/courier_chat_screen.dart';
import 'package:trashtocash/screens/driver/driver_active_order_screen.dart';
import 'package:trashtocash/screens/driver/driver_home_screen.dart';
import 'package:trashtocash/screens/home.dart';
import 'package:trashtocash/services/driver_api_service.dart';
import 'package:trashtocash/widgets/live_google_map_widget.dart';

class PickupStatusScreen extends StatefulWidget {
  final String courierName;
  final String courierId;
  final double courierRating;
  final String categoryName;
  final double weightKg;
  final double estimatedReward;
  final int? ecoPoints;

  const PickupStatusScreen({
    super.key,
    this.courierName = 'Budi Santoso',
    this.courierId = 'T2C-8842',
    this.courierRating = 4.9,
    this.categoryName = 'Plastik & Kardus Daur Ulang',
    this.weightKg = 4.5,
    this.estimatedReward = 45.0,
    this.ecoPoints,
  });

  @override
  State<PickupStatusScreen> createState() => _PickupStatusScreenState();
}

class _PickupStatusScreenState extends State<PickupStatusScreen> {
  int _currentStep = 1; // 0: Kurir ditugaskan, 1: Menuju lokasi, 2: Tiba di lokasi, 3: Selesai
  int _userRating = 0;
  bool _isHandoverAgreed = false;

  @override
  void initState() {
    super.initState();
    // Sync with Driver updates & Realtime GPS database
    DriverHelper.instance.activeOrderNotifier.addListener(_onDriverStateChanged);
    DriverHelper.instance.completedOrdersNotifier.addListener(_onDriverStateChanged);
    DriverApiService.instance.subscribeToDriverLiveTracking(widget.courierId);
    RealtimeGpsSyncHelper.instance.syncLatestGpsFromDatabase('TRX-ACTIVE');
  }

  void _onDriverStateChanged() {
    final active = DriverHelper.instance.activeOrderNotifier.value;
    if (active != null && mounted) {
      setState(() {
        if (active.status == DriverOrderStatus.headingToUser) {
          _currentStep = 1;
        } else if (active.status == DriverOrderStatus.arrivedAtLocation ||
            active.status == DriverOrderStatus.weighingAndVerify) {
          _currentStep = 2;
        } else if (active.status == DriverOrderStatus.completed) {
          _currentStep = 3;
        }
      });
    } else {
      final completed = DriverHelper.instance.completedOrdersNotifier.value;
      if (completed.isNotEmpty && mounted && _currentStep != 3) {
        setState(() {
          _currentStep = 3;
        });
      }
    }
  }

  @override
  void dispose() {
    DriverHelper.instance.activeOrderNotifier.removeListener(_onDriverStateChanged);
    DriverHelper.instance.completedOrdersNotifier.removeListener(_onDriverStateChanged);
    DriverApiService.instance.dispose();
    super.dispose();
  }

  void _showHandoverConfirmationModal() {
    _userRating = 0;
    _isHandoverAgreed = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle Bar
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

                // Header Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.handshake_outlined,
                        color: Color(0xFF0D6938),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Konfirmasi Penyerahan Sampah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pastikan sampah telah diserahkan dan ditimbang oleh kurir mitra sebelum menyelesaikan transaksi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // PIN / Verification Code for Courier
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE PIN PENYERAHAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Berikan kode ini ke kurir',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6938),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '8842',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Waste & Reward Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.recycling,
                                  size: 18,
                                  color: Color(0xFF0D6938),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${widget.categoryName} (${widget.weightKg.toStringAsFixed(1)} kg)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${DatabaseHelper.formatRupiah(widget.estimatedReward)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0D6938),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFFEAF4EE),
                            child: Icon(Icons.person, color: Color(0xFF0D6938), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kurir: ${widget.courierName} (${widget.courierId})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Courier Rating
                const Text(
                  'Beri Rating untuk Kurir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final isSelected = star <= _userRating;
                    return IconButton(
                      icon: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected ? Colors.amber : Colors.grey.shade400,
                        size: 32,
                      ),
                      onPressed: () {
                        setModalState(() {
                          _userRating = star;
                        });
                        setState(() {
                          _userRating = star;
                        });
                      },
                    );
                  }),
                ),
                Center(
                  child: Text(
                    _userRating == 0
                        ? 'Ketuk bintang di atas untuk memberi rating'
                        : '⭐ $_userRating Dari 5 Bintang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          _userRating == 0 ? FontWeight.normal : FontWeight.bold,
                      color:
                          _userRating == 0 ? Colors.grey : const Color(0xFF0D6938),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Agreement Checkbox
                GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _isHandoverAgreed = !_isHandoverAgreed;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isHandoverAgreed,
                        activeColor: const Color(0xFF0D6938),
                        onChanged: (val) {
                          setModalState(() {
                            _isHandoverAgreed = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Saya menyatakan sampah telah diserahkan sesuai dengan data di atas.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_userRating > 0 && _isHandoverAgreed)
                        ? () {
                            Navigator.pop(ctx);
                            _completeHandover();
                          }
                        : null,
                    child: Text(
                      'Selesaikan & Klaim Saldo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: (_userRating > 0 && _isHandoverAgreed)
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                if (_userRating == 0 || !_isHandoverAgreed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        _userRating == 0 && !_isHandoverAgreed
                            ? '* Harap beri rating bintang & centang pernyataan di atas'
                            : (_userRating == 0
                                  ? '* Harap pilih rating bintang terlebih dahulu'
                                  : '* Harap centang pernyataan penyerahan di atas'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeHandover() async {
    setState(() {
      _currentStep = 3; // Finished
    });

    // 1. Update status transaksi di SQLite database menjadi 'Selesai' (AWAIT)
    try {
      await DatabaseHelper.instance.markLatestPickupAsSuccess();
    } catch (e) {
      debugPrint('Error updating pickup status to success: $e');
    }

    // 2. Tambah saldo ke dompet pengguna di database SQLite secara real-time (AWAIT)
    try {
      await DatabaseHelper.instance.creditUserBalance(
        amount: widget.estimatedReward,
        title: 'Setor Sampah ${widget.categoryName}',
        description: '${widget.weightKg.toStringAsFixed(1)} kg • Dijemput oleh ${widget.courierName}',
        transactionId: 'TRX-JMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 12)}',
        ecoPoints: widget.ecoPoints ?? (widget.weightKg * 10).toInt(),
        weightKg: widget.weightKg,
        channel: 'Jemput Sampah',
      );
    } catch (e) {
      debugPrint('Error crediting user wallet in database: $e');
    }

    // Pemicu pembaruan real-time di seluruh UI & history
    DatabaseHelper.notifyHistoryChanged();

    if (!mounted) return;
    // Trigger in-app notification & sound based on notification settings
    NotificationHelper.triggerNotification(
      context: context,
      type: NotificationType.rewardDeposit,
      title: 'Saldo Masuk +${DatabaseHelper.formatRupiah(widget.estimatedReward)}! 🪙',
      message: 'Setoran ${widget.categoryName} seberat ${widget.weightKg} kg berhasil diverifikasi kurir ${widget.courierName}.',
      actionLabel: 'Rincian',
      showInAppBanner: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Color(0xFF0D6938),
                    size: 52,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Penjemputan Selesai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Terima kasih telah berkontribusi menjaga lingkungan. Saldo telah berhasil ditambahkan ke dompet Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Reward Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6938), Color(0xFF13874B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Masuk',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              'Dompet Rupiah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '+${DatabaseHelper.formatRupiah(widget.estimatedReward)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF0D6938), size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '+${widget.ecoPoints ?? (widget.weightKg * 10).toInt()} Poin Eco Hero Didapatkan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Button to History & Home
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      HomeTrashToCash.switchToTab(2);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Lihat di Riwayat Transaksi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      HomeTrashToCash.switchToTab(0);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    label: Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Status Penjemputan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.two_wheeler, color: Colors.white),
            tooltip: 'Buka Dashboard Driver',
            onPressed: () {
              DriverHelper.instance.isDriverModeActive.value = true;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Mode Quick Switcher Chip / Simulation Banner
            InkWell(
              onTap: () {
                final active = DriverHelper.instance.activeOrderNotifier.value;
                if (active != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverActiveOrderScreen(order: active),
                    ),
                  );
                } else {
                  DriverHelper.instance.isDriverModeActive.value = true;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.electric_moped, color: Color(0xFF0D6938), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simulasi: Buka Tampilan Aplikasi Mitra Driver',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF0D6938),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF0D6938), size: 12),
                  ],
                ),
              ),
            ),

            // 1. Google Maps Real-Time Interactive Live View
            LiveGoogleMapWidget(
              perspective: MapPerspective.customer,
              customerName: 'Saya (Lokasi Jemput)',
              driverName: widget.courierName,
              height: 380,
              isArrived: _currentStep >= 2,
            ),
            const SizedBox(height: 12),

            // 2. Driver Info & Contact Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFEAF4EE),
                    child: Icon(Icons.person, color: Color(0xFF0D6938), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courierName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${widget.courierId} • ${widget.courierRating} ★ (Mitra Resmi)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // WhatsApp Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF4EE),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chat,
                        color: Color(0xFF25D366),
                        size: 18,
                      ),
                      tooltip: 'WhatsApp Kurir',
                      onPressed: () {
                        ExternalDriverLauncher.openCourierWhatsApp(
                          context,
                          phoneNumber: '081234567890',
                          courierName: widget.courierName,
                          transactionId: widget.courierId,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Call Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF4EE),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: Color(0xFF0D6938),
                        size: 18,
                      ),
                      tooltip: 'Telepon Kurir',
                      onPressed: () {
                        ExternalDriverLauncher.callCourier(
                          context,
                          phoneNumber: '081234567890',
                          courierName: widget.courierName,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Chat Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF4EE),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF0D6938),
                        size: 18,
                      ),
                      tooltip: 'In-App Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourierChatScreen(
                              courierName: widget.courierName,
                              courierId: widget.courierId,
                              courierRating: widget.courierRating,
                              categoryName: widget.categoryName,
                              weightKg: widget.weightKg,
                              estimatedReward: widget.estimatedReward,
                              pickupPin: '8842',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // External Driver App Deep Link Card
            InkWell(
              onTap: () {
                ExternalDriverLauncher.openExternalDriverApp(
                  context,
                  transactionId: widget.courierId,
                  pin: '8842',
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new, color: Color(0xFF0D6938), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buka di Aplikasi TrashToCash Driver',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Deep link: trashtocash-driver://order/${widget.courierId}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF0D6938), size: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),

            // 2. Process Steps Card (Langkah Proses)
            Container(
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
                  const Text(
                    'LANGKAH PROSES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepRow(
                    title: 'Kurir Ditugaskan',
                    subtitle: 'Budi Santoso telah menerima pesanan',
                    time: '09:15 WIB',
                    isDone: true,
                    showLine: true,
                  ),
                  _buildStepRow(
                    title: 'Sedang Menuju Lokasi',
                    subtitle: 'Kurir sedang di perjalanan menuju alamat Anda',
                    time: '09:20 WIB',
                    isDone: _currentStep >= 1,
                    showLine: true,
                  ),
                  _buildStepRow(
                    title: 'Tiba di Lokasi & Penimbangan',
                    subtitle: 'Kurir memeriksa dan menimbang sampah',
                    time: _currentStep >= 2 ? '09:35 WIB' : '',
                    isDone: _currentStep >= 2,
                    showLine: true,
                  ),
                  _buildStepRow(
                    title: 'Penyerahan Selesai',
                    subtitle: 'Saldo T-Cash berhasil ditambahkan',
                    time: _currentStep >= 3 ? '09:40 WIB' : '',
                    isDone: _currentStep >= 3,
                    showLine: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Konfirmasi Penyerahan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep >= 3
                      ? Colors.grey
                      : const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: _currentStep >= 3
                    ? null
                    : _showHandoverConfirmationModal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentStep >= 3
                          ? Icons.check_circle_outline
                          : Icons.handshake_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentStep >= 3
                            ? 'Penyerahan Telah Selesai'
                            : 'Konfirmasi Penyerahan Sampah →',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Return to Home Link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(
                  Icons.home_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                label: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required String time,
    required bool isDone,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF0D6938) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF0D6938)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 38,
                color: isDone
                    ? const Color(0xFF0D6938)
                    : Colors.grey.shade300,
              ),
          ],
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                        color: isDone ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
