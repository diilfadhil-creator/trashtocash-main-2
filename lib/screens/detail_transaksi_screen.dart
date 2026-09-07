import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/helpers/trash_calculator_helper.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';
import 'package:trashtocash/screens/drop_location.dart';
import 'package:trashtocash/screens/home.dart';

class DetailTransaksiScreen extends StatefulWidget {
  final String categoryName;
  final String sampleItem;
  final double weightKg;
  final double ratePerKg;
  final double totalReward;
  final String wasteType;
  final String dropPointName;
  final String dropPointAddress;
  final String? transactionId;
  final String? transactionDate;
  final int ecoPointsPerKg;

  const DetailTransaksiScreen({
    super.key,
    this.categoryName = 'Plastik (PET)',
    this.sampleItem = 'Botol Minuman & Cup Plastik',
    this.weightKg = 2.5,
    this.ratePerKg = 10000.0,
    this.totalReward = 25000.0,
    this.wasteType = 'Non-Organik',
    this.dropPointName = 'Bank Sampah Melati - Drop Point Pusat',
    this.dropPointAddress = 'Jl. Kebon Kacang Raya No.10, Jakarta Pusat',
    this.transactionId,
    this.transactionDate,
    this.ecoPointsPerKg = 10,
  });

  @override
  State<DetailTransaksiScreen> createState() => _DetailTransaksiScreenState();
}

class _DetailTransaksiScreenState extends State<DetailTransaksiScreen> {
  CalculationResult get _calcResult => TrashToCashCalculator.calculateResult(
        weightKg: widget.weightKg,
        ratePerKg: widget.ratePerKg,
        ecoWeightPerKg: widget.ecoPointsPerKg.toDouble(),
        method: CollectionMethod.dropOff,
        currentMemberPoints: DatabaseHelper.userEcoPointsNotifier.value,
      );

  int get _calculatedEcoPoints => _calcResult.finalEcoPoints;
  double get _calculatedTCashReward => _calcResult.finalTCashReward;
  late String _transactionId;
  late DateTime _selectedDate;
  int _selectedDatePresetIndex = 0; // 0: Hari Ini, 1: Besok, 2: Lusa, 3: Custom Kalender
  TimeOfDay? _customTimeOfDay;
  String _customTimeDisplay = '14:00 (Siang)';

  @override
  void initState() {
    super.initState();
    _transactionId = widget.transactionId ??
        'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 12)}';
    _selectedDate = DateTime.now();
  }

  String _getFormattedTransactionDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final diff = selectedDay.difference(today).inDays;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthStr = months[_selectedDate.month - 1];

    if (diff == 0) {
      return 'Hari Ini (${_selectedDate.day} $monthStr)';
    } else if (diff == 1) {
      return 'Besok (${_selectedDate.day} $monthStr)';
    } else if (diff == 2) {
      return 'Lusa (${_selectedDate.day} $monthStr)';
    } else {
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final dayStr = days[_selectedDate.weekday % 7];
      return '$dayStr, ${_selectedDate.day} $monthStr ${_selectedDate.year}';
    }
  }

  String _getFormattedTransactionTime() {
    if (_customTimeDisplay.isNotEmpty) {
      return _customTimeDisplay;
    }
    return '14:00 (Siang)';
  }

  Future<void> _pickDateFromCalendar() async {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31);
    final lastDate = endOfYear.isBefore(now)
        ? DateTime(now.year + 1, 12, 31)
        : endOfYear;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now)
          ? now
          : (_selectedDate.isAfter(lastDate) ? lastDate : _selectedDate),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: lastDate,
      helpText: 'PILIH TANGGAL DROP-OFF KALENDER',
      cancelText: 'BATAL',
      confirmText: 'PILIH TANGGAL',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D6938),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E2822),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D6938),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final diff = DateTime(
          picked.year,
          picked.month,
          picked.day,
        ).difference(DateTime(now.year, now.month, now.day)).inDays;
        if (diff == 0) {
          _selectedDatePresetIndex = 0;
        } else if (diff == 1) {
          _selectedDatePresetIndex = 1;
        } else if (diff == 2) {
          _selectedDatePresetIndex = 2;
        } else {
          _selectedDatePresetIndex = 3;
        }
      });
    }
  }

  Future<void> _pickCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _customTimeOfDay ?? const TimeOfDay(hour: 14, minute: 0),
      helpText: 'PILIH JAM DROP-OFF BEBAS (00:00 - 24:00)',
      cancelText: 'BATAL',
      confirmText: 'PILIH JAM',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF0D6938),
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E2822),
                      onSurface: Colors.white,
                    )
                  : const ColorScheme.light(
                      primary: Color(0xFF0D6938),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      String timeLabel;
      if (picked.hour == 0 && picked.minute == 0) {
        timeLabel = '24:00 (12 Malam / Tengah Malam)';
      } else {
        final hStr = picked.hour.toString().padLeft(2, '0');
        final mStr = picked.minute.toString().padLeft(2, '0');
        String category = '';
        if (picked.hour >= 5 && picked.hour < 11) {
          category = 'Pagi';
        } else if (picked.hour >= 11 && picked.hour < 15) {
          category = 'Siang';
        } else if (picked.hour >= 15 && picked.hour < 18) {
          category = 'Sore';
        } else {
          category = 'Malam';
        }
        timeLabel = '$hStr:$mStr ($category)';
      }

      setState(() {
        _customTimeOfDay = picked;
        _customTimeDisplay = timeLabel;
      });
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickupDate = _getFormattedTransactionDate();
    final pickupTime = _getFormattedTransactionTime();

    // 1. Simpan transaksi drop-off ke database SQLite (AWAIT)
    final pickup = WastePickupModel(
      transactionId: _transactionId,
      wasteName: widget.categoryName,
      wasteType: widget.wasteType,
      weightKg: widget.weightKg,
      ratePerKg: widget.ratePerKg,
      totalReward: widget.totalReward,
      method: 'Drop-off',
      dropPointName: widget.dropPointName,
      pickupAddress: widget.dropPointAddress,
      pickupDate: pickupDate,
      pickupTime: pickupTime,
      status: 'Selesai',
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await DatabaseHelper.instance.insertWastePickup(pickup);
    } catch (e) {
      debugPrint('Error inserting drop-off transaction into database: $e');
    }

    // 2. Tambah saldo ke dompet pengguna di database SQLite secara real-time (AWAIT)
    try {
      await DatabaseHelper.instance.creditUserBalance(
        amount: widget.totalReward,
        title: 'Setor Sampah ${widget.categoryName}',
        description: '${widget.weightKg.toStringAsFixed(1)} kg • Drop-off di ${widget.dropPointName}',
        transactionId: _transactionId,
        ecoPoints: _calculatedEcoPoints,
        weightKg: widget.weightKg,
        channel: 'Drop-off Mandiri',
      );
    } catch (e) {
      debugPrint('Error crediting user wallet in database: $e');
    }

    // Pemicu pembaruan real-time di seluruh UI & history
    DatabaseHelper.notifyHistoryChanged();

    // Mainkan efek suara koin berdenting & picu notifikasi saldo masuk
    SoundHelper.playCoinSound(force: true);
    if (!context.mounted) return;
    NotificationHelper.triggerNotification(
      context: context,
      type: NotificationType.rewardDeposit,
      title: 'Setoran Berhasil! Saldo Masuk +${DatabaseHelper.formatRupiah(widget.totalReward)} 🪙',
      message: 'Setoran sampah ${widget.categoryName} (${widget.weightKg.toStringAsFixed(1)} kg) berhasil diproses. Saldo & Poin Eco telah ditambahkan ke dompet Anda.',
      actionLabel: 'Lihat Saldo',
      showInAppBanner: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0D6938),
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Setoran Berhasil Didaftarkan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiket drop-off Anda telah aktif untuk $pickupDate • $pickupTime. Silakan bawa sampah ke ${widget.dropPointName} untuk ditimbang ulang dan klaim saldo.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263229)
                      : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimasi Saldo',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '+${DatabaseHelper.formatRupiah(widget.totalReward)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimasi Bonus Poin Eco',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '+$_calculatedEcoPoints Poin Eco',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double bonusMitra = widget.totalReward > 0 ? (widget.totalReward * 0.1) : 0.0;
    final double grandTotal = widget.totalReward + bonusMitra;
    final formattedDateTimeStr = '${_getFormattedTransactionDate()} • ${_getFormattedTransactionTime()}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan tiket transaksi disalin ke clipboard!'),
                  duration: Duration(seconds: 1),
                ),
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
            // 1. Transaction Status Header Card
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NO. TRANSAKSI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#$_transactionId',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D6938),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Siap di Drop-off',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6938),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderMeta(
                        'METODE',
                        'Drop-off Mandiri',
                        Icons.pin_drop_outlined,
                      ),
                      _buildHeaderMeta(
                        'WAKTU DIBUAT',
                        formattedDateTimeStr,
                        Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tanggal & Waktu Drop-off Picker Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tanggal & Waktu Drop-off',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getFormattedTransactionDate(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chip Presets Tanggal Drop-off
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip Hari Ini
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                              _selectedDatePresetIndex = 0;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDatePresetIndex == 0
                                  ? const Color(0xFF0D6938)
                                  : (isDark
                                        ? const Color(0xFF263229)
                                        : const Color(0xFFF4F8F5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Hari Ini',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedDatePresetIndex == 0
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        // Chip Besok
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = DateTime.now().add(
                                const Duration(days: 1),
                              );
                              _selectedDatePresetIndex = 1;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDatePresetIndex == 1
                                  ? const Color(0xFF0D6938)
                                  : (isDark
                                        ? const Color(0xFF263229)
                                        : const Color(0xFFF4F8F5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Besok',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedDatePresetIndex == 1
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        // Chip Lusa
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = DateTime.now().add(
                                const Duration(days: 2),
                              );
                              _selectedDatePresetIndex = 2;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDatePresetIndex == 2
                                  ? const Color(0xFF0D6938)
                                  : (isDark
                                        ? const Color(0xFF263229)
                                        : const Color(0xFFF4F8F5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lusa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedDatePresetIndex == 2
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                        // Chip Kalender Lengkap
                        GestureDetector(
                          onTap: _pickDateFromCalendar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDatePresetIndex == 3
                                  ? const Color(0xFF0D6938)
                                  : (isDark
                                        ? const Color(0xFF1E382A)
                                        : const Color(0xFFE8F2EC)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0D6938),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 15,
                                  color: _selectedDatePresetIndex == 3
                                      ? Colors.white
                                      : const Color(0xFF0D6938),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pilih dari Kalender 📅',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedDatePresetIndex == 3
                                        ? Colors.white
                                        : const Color(0xFF0D6938),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Divider(height: 1),
                  ),

                  // Header Jam Drop-off Bebas 24 Jam
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              color: Color(0xFF0D6938),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Waktu Drop-off Bebas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          '24 JAM FLEXIBLE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tombol Set Jam Bebas Single Banner
                  InkWell(
                    onTap: _pickCustomTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E382A)
                            : const Color(0xFFE8F2EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0D6938),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D6938),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Set Jam Bebas (Pilih Sendiri)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFormattedTransactionTime(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
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
                              color: const Color(0xFF0D6938),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Set Jam Bebas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Drop Point Destination Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Titik Pengumpulan (Drop Point)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DropPointLocationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.map_outlined,
                          size: 14,
                          color: Color(0xFF0D6938),
                        ),
                        label: const Text(
                          'Pilih Lain',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D6938),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_mall_directory_outlined,
                          color: Color(0xFF0D6938),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.dropPointName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.dropPointAddress,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Buka 08:00 - 17:00 WIB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.directions_walk,
                                  size: 12,
                                  color: Color(0xFF0D6938),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '1.2 km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF0D6938),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Rincian Item Sampah (Waste Item Breakdown)
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
                    'Rincian Sampah Daur Ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAF4EE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.recycling,
                                  color: Color(0xFF0D6938),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.categoryName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      widget.sampleItem,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pricing Calculations
                  _buildPriceRow(
                    'Tarif per kg',
                    '${DatabaseHelper.formatRupiah(widget.ratePerKg)} / kg',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    'Subtotal Estimasi (${widget.weightKg.toStringAsFixed(1)} kg)',
                    '+${DatabaseHelper.formatRupiah(widget.totalReward)}',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    'Estimasi Bonus Poin Eco',
                    '+$_calculatedEcoPoints Poin Eco',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    'Bonus Reward Eco-Hero (+10%)',
                    '+${DatabaseHelper.formatRupiah(bonusMitra)}',
                    isBonus: true,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimasi Reward',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+${DatabaseHelper.formatRupiah(grandTotal)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Dampak Lingkungan (Eco Impact)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2F23) : const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF4EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Color(0xFF0D6938),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dampak Positif Anda',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Setoran ini membantu mereduksi ${(widget.weightKg * 1.25).toStringAsFixed(1)} kg emisi karbon CO2 dan menyelamatkan ${(widget.weightKg * 2.8).toStringAsFixed(1)} liter air.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Tiket QR Code untuk Drop-off
            Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  const Text(
                    'Tiket Digital Drop-off',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tunjukkan QR Code ini ke petugas loket di Drop Point',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Simulated QR Code Frame
                  Container(
                    width: 160,
                    height: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0D6938),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 130,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'KODE: $_transactionId',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSuccessDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Konfirmasi & Selesaikan Setoran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DropPointLocationScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.navigation_outlined,
                  color: Color(0xFF0D6938),
                  size: 18,
                ),
                label: const Text(
                  'Petunjuk Arah ke Drop Point',
                  style: TextStyle(
                    color: Color(0xFF0D6938),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0D6938), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMeta(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D6938)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBonus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isBonus ? const Color(0xFF0D6938) : Colors.grey.shade700,
            fontWeight: isBonus ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isBonus ? const Color(0xFF0D6938) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
