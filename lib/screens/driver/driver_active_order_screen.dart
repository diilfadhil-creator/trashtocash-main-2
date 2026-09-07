import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/helpers/realtime_gps_sync_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/screens/driver/driver_chat_screen.dart';
import 'package:trashtocash/services/driver_api_service.dart';
import 'package:trashtocash/services/location_service.dart';
import 'package:trashtocash/widgets/live_google_map_widget.dart';

class DriverActiveOrderScreen extends StatefulWidget {
  final DriverOrderItemModel order;

  const DriverActiveOrderScreen({super.key, required this.order});

  @override
  State<DriverActiveOrderScreen> createState() =>
      _DriverActiveOrderScreenState();
}

class _DriverActiveOrderScreenState extends State<DriverActiveOrderScreen> {
  late DriverOrderItemModel _currentOrder;
  int _currentStepIndex = 0; // 0: Terima, 1: Menuju, 2: Tiba, 3: Timbang & PIN, 4: Selesai
  double _measuredWeightKg = 5.0;
  String? _capturedPhotoPath;
  final TextEditingController _pinController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isVerifying = false;
  String? _pinErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _measuredWeightKg = _currentOrder.estimatedWeightKg;

    // Request location permission & start hardware live GPS tracking
    LocationService.instance.requestLocationPermission().then((_) {
      LocationService.instance.startLiveTracking();
    });

    // Sync initial step
    if (_currentOrder.status == DriverOrderStatus.accepted) {
      _currentStepIndex = 0;
    } else if (_currentOrder.status == DriverOrderStatus.headingToUser) {
      _currentStepIndex = 1;
      RealtimeGpsSyncHelper.instance.startRealtimeGpsBroadcasting(
        transactionId: _currentOrder.transactionId,
        driverId: 'T2C-8842',
      );
    } else if (_currentOrder.status == DriverOrderStatus.arrivedAtLocation) {
      _currentStepIndex = 2;
    } else if (_currentOrder.status == DriverOrderStatus.weighingAndVerify) {
      _currentStepIndex = 3;
    } else if (_currentOrder.status == DriverOrderStatus.completed) {
      _currentStepIndex = 4;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    RealtimeGpsSyncHelper.instance.stopRealtimeGpsBroadcasting();
    DriverApiService.instance.stopGpsTracking();
    super.dispose();
  }

  double get _calculatedTotalReward =>
      _measuredWeightKg * _currentOrder.ratePerKg;

  double get _driverCommissionRp => _measuredWeightKg * 2500.0;

  Future<void> _pickProofPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _capturedPhotoPath = photo.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  // --- 5 ACTIVE STEP ADVANCEMENT HANDLERS ---

  /// Step 0 -> Step 1: Mulai Menuju Alamat Warga
  Future<void> _advanceToHeadingToUser() async {
    HapticFeedback.mediumImpact();
    await DriverHelper.instance.updateActiveOrderStatus(
      DriverOrderStatus.headingToUser,
      context: context,
    );
    RealtimeGpsSyncHelper.instance.startRealtimeGpsBroadcasting(
      transactionId: _currentOrder.transactionId,
      driverId: 'T2C-8842',
    );
    setState(() {
      _currentStepIndex = 1;
      _currentOrder.status = DriverOrderStatus.headingToUser;
    });
  }

  /// Step 1 -> Step 2: Konfirmasi Tiba di Lokasi Warga
  Future<void> _advanceToArrived() async {
    HapticFeedback.mediumImpact();
    RealtimeGpsSyncHelper.instance.stopRealtimeGpsBroadcasting();
    DriverApiService.instance.stopGpsTracking();
    await DriverHelper.instance.updateActiveOrderStatus(
      DriverOrderStatus.arrivedAtLocation,
      context: context,
    );
    setState(() {
      _currentStepIndex = 2;
      _currentOrder.status = DriverOrderStatus.arrivedAtLocation;
    });
  }

  /// Step 2 -> Step 3: Mulai Timbang & Input PIN
  void _advanceToWeighingAndPin() {
    HapticFeedback.mediumImpact();
    DriverHelper.instance.updateActiveOrderStatus(
      DriverOrderStatus.weighingAndVerify,
      context: context,
    );
    setState(() {
      _currentStepIndex = 3;
      _currentOrder.status = DriverOrderStatus.weighingAndVerify;
    });
  }

  /// Step 3 -> Step 4: Verifikasi PIN & Selesaikan Penjemputan
  Future<void> _submitVerificationAndComplete() async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.isEmpty) {
      setState(() {
        _pinErrorMessage = 'Harap masukkan 4-digit PIN penyerahan dari warga.';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isVerifying = true;
      _pinErrorMessage = null;
    });

    final success = await DriverHelper.instance.verifyAndCompletePickup(
      actualWeightKg: _measuredWeightKg,
      enteredPin: enteredPin,
      proofPhotoPath: _capturedPhotoPath,
      context: context,
    );

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _currentStepIndex = 4;
        _currentOrder.status = DriverOrderStatus.completed;
      });
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      setState(() {
        _pinErrorMessage =
            'PIN tidak sesuai (PIN warga: ${_currentOrder.verificationPin}). Harap konfirmasi ke warga.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0D6938),
                  size: 54,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Penjemputan Sukses!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sampah seberat ${_measuredWeightKg.toStringAsFixed(1)} kg (${_currentOrder.wasteName}) berhasil diverifikasi & dituntaskan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263229)
                      : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Komisi Mitra Driver:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '+Rp ${_driverCommissionRp.toStringAsFixed(0)}',
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
                        const Text(
                          'Reward T-Cash Warga:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '+${_calculatedTotalReward.toStringAsFixed(2)} T-Cash',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Return to DriverHomeScreen
                  },
                  child: const Text(
                    'Kembali ke Layar Utama',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121A15) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor:
          isDark ? const Color(0xFF18221C) : const Color(0xFF0D6938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menjalankan Orderan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'ID: ${_currentOrder.transactionId}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            tooltip: 'Chat Warga',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverChatScreen(order: _currentOrder),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
            tooltip: 'Telepon Warga',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungi ${_currentOrder.userPhone}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Interactive 5-Step Progress Bar
            _buildInteractiveStepIndicator(isDark),

            // 2. Google Maps Live Driver Navigation Simulator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildInteractiveMapSimulator(isDark),
            ),

            // 3. Customer Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCustomerInfoCard(isDark),
            ),
            const SizedBox(height: 12),

            // 4. Active Workflow Step Content (5 Different Dedicated Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCurrentStepContent(isDark),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionButton(isDark),
    );
  }

  Widget _buildInteractiveMapSimulator(bool isDark) {
    return ValueListenableBuilder<UserGpsState>(
      valueListenable: LocationService.instance.userLocationNotifier,
      builder: (context, userGps, _) {
        return LiveGoogleMapWidget(
          perspective: MapPerspective.driver,
          customerName: _currentOrder.userName,
          customerAddress: _currentOrder.userAddress,
          customerLat: -6.2045,
          customerLng: 106.8512,
          driverName: 'Saya (Mitra Driver)',
          height: 270,
          isArrived: _currentStepIndex >= 2,
        );
      },
    );
  }

  /// 5 Interaktif Stepper Tabs yang Aktif
  Widget _buildInteractiveStepIndicator(bool isDark) {
    final steps = [
      {'title': 'Terima', 'icon': Icons.assignment_turned_in_outlined},
      {'title': 'Menuju', 'icon': Icons.two_wheeler},
      {'title': 'Tiba', 'icon': Icons.pin_drop_outlined},
      {'title': 'Timbang & PIN', 'icon': Icons.scale_outlined},
      {'title': 'Selesai', 'icon': Icons.verified_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18221C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (idx) {
          final isCompleted = idx < _currentStepIndex;
          final isCurrent = idx == _currentStepIndex;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _currentStepIndex = idx;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF0D6938)
                          : (isCurrent
                              ? const Color(0xFF00E676)
                              : (isDark
                                  ? const Color(0xFF263229)
                                  : Colors.grey.shade200)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF0D6938)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0D6938)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Icon(
                              steps[idx]['icon'] as IconData,
                              size: 15,
                              color: isCurrent
                                  ? const Color(0xFF0D6938)
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[idx]['title'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFF0D6938)
                          : (isCompleted
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCustomerInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFEAF4EE),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF0D6938),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _currentOrder.userPhone,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF0D6938),
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DriverChatScreen(order: _currentOrder),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF0D6938),
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Menghubungi ${_currentOrder.userPhone}...',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF0D6938),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentOrder.userAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (_currentOrder.pickupNotes != null &&
              _currentOrder.pickupNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: "${_currentOrder.pickupNotes}"',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5 DEDICATED ACTIVE STEP WORKFLOW CONTENTS ---
  Widget _buildCurrentStepContent(bool isDark) {
    if (_currentStepIndex == 0) {
      // 🛵 STEP 1: TERIMA ORDER & PERSIAPAN
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0D6938).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                size: 36,
                color: Color(0xFF0D6938),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Langkah 1: Order Diterima & Siap Jalan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan kendaraan mitra siap, kantong pemilahan tersedia, dan timbangan digital dalam kondisi aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStepBadge(
                    icon: Icons.inventory_2_outlined,
                    label: 'Jenis Sampah',
                    value: _currentOrder.wasteName,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStepBadge(
                    icon: Icons.scale_outlined,
                    label: 'Estimasi Berat',
                    value: '${_currentOrder.estimatedWeightKg} kg',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_currentStepIndex == 1) {
      // 🗺️ STEP 2: MENUJU ALAMAT WARGA
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0D6938).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 36,
                color: Color(0xFF0D6938),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Langkah 2: Sedang Menuju Lokasi Warga',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pelacakan GPS aktif dan siaran rute dipancarkan secara live ke layar warga. Ikuti peta menuju alamat penjemputan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Jarak Tempuh', '1.2 km'),
                  _buildMiniStat('Kecepatan', '34 km/j'),
                  _buildMiniStat('Estimasi Tiba', '4 Menit'),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_currentStepIndex == 2) {
      // 📍 STEP 3: TIBA DI LOKASI PENJEMPUTAN
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0D6938).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pin_drop_rounded,
                size: 36,
                color: Color(0xFF0D6938),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Langkah 3: Tiba di Alamat Warga',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Temui warga, cek kondisi sampah daur ulang, dan siapkan timbangan digital untuk penimbangan langsung.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline,
                        size: 15, color: Colors.white),
                    label: const Text('Chat Warga',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DriverChatScreen(order: _currentOrder),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D6938)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.phone,
                        size: 15, color: Color(0xFF0D6938)),
                    label: const Text('Telepon',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF0D6938))),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Menghubungi ${_currentOrder.userPhone}...'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_currentStepIndex == 3) {
      // ⚖️ STEP 4: TIMBANGAN DIGITAL & PIN VERIFIKASI
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0D6938).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.scale,
                  color: Color(0xFF0D6938),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Langkah 4: Timbangan Digital & PIN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Digital Scale Adjuster Widget
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'HASIL TIMBANGAN AKTUAL (KG)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 28,
                          color: Color(0xFF0D6938),
                        ),
                        onPressed: _measuredWeightKg > 0.5
                            ? () {
                                setState(() {
                                  _measuredWeightKg =
                                      (_measuredWeightKg - 0.5)
                                          .clamp(0.5, 200.0);
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_measuredWeightKg.toStringAsFixed(1)} KG',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ADE80),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 28,
                          color: Color(0xFF0D6938),
                        ),
                        onPressed: () {
                          setState(() {
                            _measuredWeightKg =
                                (_measuredWeightKg + 0.5).clamp(0.5, 200.0);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Weight Preset Chips
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildPresetChip('+1 kg', 1.0),
                      _buildPresetChip('+5 kg', 5.0),
                      _buildPresetChip('+10 kg', 10.0),
                      _buildPresetChip('Reset (5 kg)', 0.0, isReset: true),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Slider(
                    value: _measuredWeightKg.clamp(0.5, 50.0),
                    min: 0.5,
                    max: 50.0,
                    divisions: 99,
                    activeColor: const Color(0xFF0D6938),
                    onChanged: (val) {
                      setState(() {
                        _measuredWeightKg =
                            double.parse(val.toStringAsFixed(1));
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Reward Warga:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        '+${_calculatedTotalReward.toStringAsFixed(2)} T-Cash',
                        style: const TextStyle(
                          fontSize: 13,
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

            // Proof Photo Attachment
            Text(
              'Foto Bukti Timbangan (Opsional)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (_capturedPhotoPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_capturedPhotoPath!),
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                        onPressed: () =>
                            setState(() => _capturedPhotoPath = null),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label:
                          const Text('Kamera', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickProofPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library, size: 16),
                      label:
                          const Text('Galeri', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickProofPhoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // PIN Handover Input Field
            Text(
              'PIN Penyerahan Sampah dari Warga',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minta 4-digit PIN dari layar warga:',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _pinController.text = _currentOrder.verificationPin;
                      _pinErrorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0D6938)),
                    ),
                    child: Text(
                      'Isi Cepat (${_currentOrder.verificationPin})',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: _currentOrder.verificationPin,
                counterText: '',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF4F8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0D6938), width: 2),
                ),
              ),
            ),
            if (_pinErrorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _pinErrorMessage!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 11.5),
              ),
            ],
          ],
        ),
      );
    } else {
      // ✅ STEP 5: PENJEMPUTAN SELESAI & RANGKUMAN
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A241E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E676),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 40,
                color: Color(0xFF0D6938),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Langkah 5: Penjemputan Sukses & Selesai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sampah telah diverifikasi. Saldo komisi mitra dan poin reward warga telah ditambahkan ke dompet digital.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                      'Total Berat Aktual', '${_measuredWeightKg.toStringAsFixed(1)} kg'),
                  const Divider(height: 14),
                  _buildSummaryRow('Komisi Driver',
                      '+Rp ${_driverCommissionRp.toStringAsFixed(0)}'),
                  const Divider(height: 14),
                  _buildSummaryRow('Reward Warga',
                      '+${_calculatedTotalReward.toStringAsFixed(2)} T-Cash'),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStepBadge({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0D6938)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0D6938))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPresetChip(String label, double addValue, {bool isReset = false}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        setState(() {
          if (isReset) {
            _measuredWeightKg = 5.0;
          } else {
            _measuredWeightKg = (_measuredWeightKg + addValue).clamp(0.5, 200.0);
          }
        });
      },
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: Color(0xFF0D6938))),
      ],
    );
  }

  Widget _buildBottomActionButton(bool isDark) {
    String buttonLabel;
    VoidCallback? onPressed;

    if (_currentStepIndex == 0) {
      buttonLabel = 'Langkah 1/5: Mulai Menuju Alamat Warga 🛵';
      onPressed = _advanceToHeadingToUser;
    } else if (_currentStepIndex == 1) {
      buttonLabel = 'Langkah 2/5: Saya Sudah Tiba di Alamat Warga 📍';
      onPressed = _advanceToArrived;
    } else if (_currentStepIndex == 2) {
      buttonLabel = 'Langkah 3/5: Mulai Timbang & Input PIN ⚖️';
      onPressed = _advanceToWeighingAndPin;
    } else if (_currentStepIndex == 3) {
      buttonLabel = 'Langkah 4/5: Verifikasi & Selesaikan Order ✅';
      onPressed = _isVerifying ? null : _submitVerificationAndComplete;
    } else {
      buttonLabel = 'Langkah 5/5: Selesai & Kembali ke Layar Utama 🏠';
      onPressed = () => Navigator.pop(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18221C) : Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6938),
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onPressed,
            child: _isVerifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
