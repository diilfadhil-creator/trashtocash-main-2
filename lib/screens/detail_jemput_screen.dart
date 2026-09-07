import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/helpers/trash_calculator_helper.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';
import 'package:trashtocash/screens/home.dart';
import 'package:trashtocash/screens/pickup_status.dart';
import 'package:trashtocash/services/driver_api_service.dart';
import 'package:trashtocash/services/location_service.dart';

class DetailJemputScreen extends StatefulWidget {
  final String categoryName;
  final String sampleItem;
  final double weightKg;
  final double ratePerKg;
  final double totalReward;
  final String wasteType;
  final int ecoPointsPerKg;

  const DetailJemputScreen({
    super.key,
    this.categoryName = 'Plastik (PET)',
    this.sampleItem = 'Botol Minuman & Cup Plastik',
    this.weightKg = 2.5,
    this.ratePerKg = 10000.0,
    this.totalReward = 25000.0,
    this.wasteType = 'Non-Organik',
    this.ecoPointsPerKg = 10,
  });

  @override
  State<DetailJemputScreen> createState() => _DetailJemputScreenState();
}

class _DetailJemputScreenState extends State<DetailJemputScreen> {
  CalculationResult get _calcResult => TrashToCashCalculator.calculateResult(
        weightKg: widget.weightKg,
        ratePerKg: widget.ratePerKg,
        ecoWeightPerKg: widget.ecoPointsPerKg.toDouble(),
        method: CollectionMethod.pickup,
        currentMemberPoints: DatabaseHelper.userEcoPointsNotifier.value,
      );

  int get _calculatedEcoPoints => _calcResult.finalEcoPoints;
  double get _calculatedTCashReward => _calcResult.finalTCashReward;
  DateTime _selectedDate = DateTime.now();
  int _selectedDatePresetIndex =
      0; // 0: Hari Ini, 1: Besok, 2: Lusa, 3: Custom Kalender

  String _customTimeDisplay = '14:00 (Siang)';
  TimeOfDay? _customTimeOfDay = const TimeOfDay(hour: 14, minute: 0);

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isDetectingGps = false;

  Future<void> _detectGpsAddress() async {
    setState(() {
      _isDetectingGps = true;
    });

    final granted = await LocationService.instance.requestLocationPermission();
    if (granted) {
      await LocationService.instance.refreshCurrentLocation();
      final userState = LocationService.instance.currentState;
      if (!mounted) return;
      setState(() {
        _addressController.text = userState.fullAddress;
        _isDetectingGps = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D6938),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS Berhasil: ${userState.fullAddress} (±${userState.accuracy.toStringAsFixed(0)}m)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isDetectingGps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Izin GPS tidak diberikan. Silakan ketik alamat manual.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultNote = prefs.getString('appCourierNote') ?? '';
    final defaultTime = prefs.getString('appPickupTime') ?? '';
    final userAddress = prefs.getString('userAddress') ?? '';
    final userPhone = prefs.getString('userPhone') ?? '';

    if (mounted) {
      setState(() {
        if (defaultNote.isNotEmpty) {
          _notesController.text = defaultNote;
        }
        if (defaultTime.isNotEmpty) {
          _customTimeDisplay = defaultTime;
        }
        if (userAddress.isNotEmpty) {
          _addressController.text = userAddress;
        }
        if (userPhone.isNotEmpty) {
          _phoneController.text = userPhone;
        }
      });
    }
  }

  String _getFormattedPickupDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final diff = target.difference(today).inDays;

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

  String _getFormattedPickupTime() {
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
      helpText: 'PILIH TANGGAL PENJEMPUTAN KALENDER',
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
      helpText: 'PILIH JAM JEMPUT BEBAS (00:00 - 24:00)',
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
        } else if (picked.hour >= 18 && picked.hour < 22) {
          category = 'Malam';
        } else {
          category = 'Tengah Malam (24.00)';
        }
        timeLabel = '$hStr:$mStr ($category)';
      }

      setState(() {
        _customTimeOfDay = picked;
        _customTimeDisplay = timeLabel;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showValidationDialog({
    required bool missingAddress,
    required bool missingPhone,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String messageText = '';

    if (missingAddress && missingPhone) {
      messageText =
          'Mohon isi alamat lengkap penjemputan dan nomor telepon WhatsApp Anda terlebih dahulu sebelum melanjutkan pesanan.';
    } else if (missingAddress) {
      messageText =
          'Mohon isi alamat lengkap penjemputan Anda terlebih dahulu.';
    } else {
      messageText =
          'Mohon isi nomor telepon WhatsApp Anda terlebih dahulu.';
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data Belum Lengkap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          messageText,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.grey.shade800,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'isi data dengan lengkap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPressSubmit() {
    final String address = _addressController.text.trim();
    final String phone = _phoneController.text.trim();

    if (address.isEmpty || phone.isEmpty) {
      _showValidationDialog(
        missingAddress: address.isEmpty,
        missingPhone: phone.isEmpty,
      );
      return;
    }

    _showCourierInfoDialog();
  }

  void _showCourierInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF0D6938),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Catatan Penting Kurir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perhatikan ringkasan ketentuan sistem penjemputan berikut sebelum melanjutkan:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 14),
              _buildDialogNoteItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Potong Saldo Otomatis',
                desc:
                    'Ongkos jemput dipotong otomatis dari reward sampah di aplikasi (tanpa bayar tunai ke kurir).',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDialogNoteItem(
                icon: Icons.scale_outlined,
                title: 'Syarat Minimal Berat',
                desc:
                    'Penjemputan berlaku untuk batas minimum berat sampah agar proses armada kurir optimal.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDialogNoteItem(
                icon: Icons.storefront_outlined,
                title: 'Alternatif Bebas Ongkir',
                desc:
                    'Ingin reward 100% penuh tanpa potongan? Pilih opsi Drop-off mandiri ke Drop Point terdekat.',
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _confirmPickup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6938),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPickup() async {
    // 1. Simpan data penjemputan sampah ke database SQLite (AWAIT)
    final pickup = WastePickupModel(
      transactionId:
          'TRX-JMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 12)}',
      wasteName: widget.categoryName,
      wasteType: widget.wasteType,
      weightKg: widget.weightKg,
      ratePerKg: widget.ratePerKg,
      totalReward: widget.totalReward,
      method: 'Jemput Sampah',
      pickupAddress: _addressController.text.trim(),
      pickupDate: _getFormattedPickupDate(),
      pickupTime: _getFormattedPickupTime(),
      pickupNotes: _notesController.text.trim(),
      status: 'Menunggu Penjemputan',
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await DatabaseHelper.instance.insertWastePickup(pickup);
    } catch (e) {
      debugPrint('Error inserting pickup into database: $e');
    }

    // Pemicu pembaruan real-time di seluruh UI & history
    DatabaseHelper.notifyHistoryChanged();

    // Dispatch order to Backend API Gateway for external TrashToCash Driver app
    DriverApiService.instance.createPickupRequest(
      pickup: pickup,
      userPhone: _phoneController.text.trim(),
      handoverPin: '8842',
    ).catchError((e) {
      debugPrint('Error dispatching pickup to API Gateway: $e');
      return <String, dynamic>{};
    });

    // Notify Driver Helper Radar
    DriverHelper.instance.notifyNewPickupOrder(pickup);

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Color(0xFF0D6938),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pesanan Jemput Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kurir mitra sedang ditugaskan untuk menjemput sampah Anda pada ${_getFormattedPickupDate()}, jam ${_getFormattedPickupTime()}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
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
                          Expanded(
                            child: Text(
                              'Estimasi Reward',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '+${DatabaseHelper.formatRupiah(_calculatedTCashReward)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6938),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Estimasi Bonus Poin Eco (${_calcResult.tier.nameLabel})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PickupStatusScreen(
                            categoryName: widget.categoryName,
                            weightKg: widget.weightKg,
                            estimatedReward: _calculatedTCashReward,
                            ecoPoints: _calculatedEcoPoints,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Status Penjemputan',
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
                      HomeTrashToCash.switchToTab(2);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    label: Text(
                      'Lihat di Riwayat Transaksi',
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penjemputan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Status Card
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'METODE LAYANAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 18,
                              color: Color(0xFF0D6938),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Jemput Sampah ke Lokasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Mitra Kurir',
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
            const SizedBox(height: 16),

            // 2. Rincian Sampah yang Dipindai (Overflow Safe)
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
                    'Sampah yang Akan Dijemput',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF263229)
                          : const Color(0xFFF4F8F5),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.sampleItem,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey.shade600,
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Alamat Penjemputan Card
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
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFF0D6938),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alamat Penjemputan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _isDetectingGps ? null : _detectGpsAddress,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4EE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0D6938),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isDetectingGps)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF0D6938),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.my_location,
                                    size: 13,
                                    color: Color(0xFF0D6938),
                                  ),
                                const SizedBox(width: 4),
                                const Text(
                                  'GPS Saya 📍',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            LocationService.instance
                                .openGoogleMapsAtUserLocation(
                              context: context,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0288D1),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 13,
                                  color: Color(0xFF0288D1),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Google Maps 🗺️',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0288D1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Masukkan alamat lengkap penjemputan...',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF263229)
                          : const Color(0xFFF4F8F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Nomor WhatsApp / HP',
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF263229)
                                : const Color(0xFFF4F8F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Jadwal Penjemputan (Kalender Lengkap & Jam Bebas s.d 24:00)
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
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Color(0xFF0D6938),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pilih Hari Penjemputan',
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
                          color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Kalender Aktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Display Banner Tanggal Terpilih
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF263229)
                          : const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          color: Color(0xFF0D6938),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TANGGAL PENJEMPUTAN TERPILIH',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getFormattedPickupDate(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D6938),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: _pickDateFromCalendar,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6938),
                            foregroundColor: Colors.white,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Ubah',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal Quick Presets + Kalender Button
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

                  // Header Jam Penjemputan Bebas 24 Jam
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
                                'Waktu Jemput Bebas',
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
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '24 Jam (s.d 12 Malem)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Display Banner Waktu Terpilih
                  GestureDetector(
                    onTap: _pickCustomTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF263229)
                            : const Color(0xFFF4F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF0D6938),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JAM PENJEMPUTAN AKTIF',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFormattedPickupTime(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: _pickCustomTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6938),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.more_time_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Ubah',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

            // 5. Catatan untuk Kurir
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
                    'Catatan Tambahan untuk Kurir',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Sampah sudah diikat karung di depan pagar...',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF263229)
                          : const Color(0xFFF4F8F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Rincian Estimasi Biaya & Reward
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
                    'Ringkasan Transaksi Penjemputan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    'Estimasi Reward (${widget.weightKg.toStringAsFixed(1)} kg)',
                    '+${DatabaseHelper.formatRupiah(widget.totalReward)}',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    'Estimasi Bonus Poin Eco',
                    '+$_calculatedEcoPoints Poin Eco',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    'Biaya Kurir Jemput',
                    'GRATIS (Promo)',
                    isFree: true,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Estimasi Bersih',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '+${DatabaseHelper.formatRupiah(widget.totalReward)}',
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
            const SizedBox(height: 24),

            // 7. Tombol Konfirmasi & Pesan Penjemputan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onPressSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Pesan Penjemputan Sekarang',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
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

  Widget _buildDialogNoteItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0D6938).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0D6938)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isFree = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isFree
                ? const Color(0xFF0D6938)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
