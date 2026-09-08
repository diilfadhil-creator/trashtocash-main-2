import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/trash_calculator_helper.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/screens/detail_jemput_screen.dart';
import 'package:trashtocash/screens/detail_transaksi_screen.dart';
import 'package:trashtocash/screens/panduan_sampah_screen.dart';
import 'package:trashtocash/services/backend_api_service.dart';
import 'package:trashtocash/services/camera_service.dart';

class LiveCameraScanScreen extends StatefulWidget {
  final bool isPickup;
  final WasteItemModel? preselectedItem;

  const LiveCameraScanScreen({
    super.key,
    this.isPickup = false,
    this.preselectedItem,
  });

  @override
  State<LiveCameraScanScreen> createState() => _LiveCameraScanScreenState();
}

class _LiveCameraScanScreenState extends State<LiveCameraScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _cameraError = false;
  String _errorMessage = '';

  // Flash & Zoom controls
  FlashMode _currentFlashMode = FlashMode.off;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 4.0;
  double _currentZoomLevel = 1.0;
  double _baseScale = 1.0;

  // Tap to focus animation
  Offset? _focusPoint;
  bool _showFocusRing = false;

  // Grid guidelines
  bool _showGrid = true;

  // Scanner Modes: 0 = AI Waste Scanner, 1 = QR Code Scanner
  int _scanMode = 0;

  // Category filter for AI
  String _categoryFilter = 'Semua'; // 'Semua', 'Organik', 'Non-Organik'

  // Animations
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // AI & Capture state
  bool _isCapturing = false;
  bool _isAnalyzing = false;

  // Catalog items for manual override
  List<WasteItemModel> _allWasteItems = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initAnimations();
    _loadCatalogItems();
    _initCameraSystem();
  }

  void _initAnimations() {
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCatalogItems() async {
    try {
      final items = await DatabaseHelper.instance.getAllWasteItems();
      if (items.isNotEmpty && mounted) {
        setState(() {
          _allWasteItems = items;
        });
      }
    } catch (e) {
      debugPrint('Error loading waste catalog: $e');
    }
  }

  Future<void> _initCameraSystem() async {
    try {
      _cameras = await CameraService.instance.initializeCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _errorMessage =
                'Kamera tidak terdeteksi pada perangkat ini. Mode simulasi AI & galeri tetap aktif.';
          });
        }
        return;
      }

      // Default to back camera
      _selectedCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          _selectedCameraIndex = i;
          break;
        }
      }

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _errorMessage = 'Gagal mengakses kamera: $e';
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription cameraDescription) async {
    final prevController = _cameraController;
    if (prevController != null) {
      await prevController.dispose();
    }

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = (await controller.getMaxZoomLevel()).clamp(1.0, 5.0);
      _currentZoomLevel = _minZoomLevel;

      await controller.setFlashMode(_currentFlashMode);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = false;
        });
      }
    } catch (e) {
      debugPrint('Error setting up camera controller: $e');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _errorMessage = 'Gagal menginisialisasi kamera: $e';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // --- CAMERA CONTROLS ---

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    HapticFeedback.lightImpact();

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() {
        _currentFlashMode = nextMode;
      });

      String flashLabel = 'Mati';
      if (nextMode == FlashMode.torch) flashLabel = 'Senter Hidup';
      if (nextMode == FlashMode.auto) flashLabel = 'Flash Otomatis';
      if (nextMode == FlashMode.always) flashLabel = 'Flash Selalu Nyala';

      _showMiniToast('Flash: $flashLabel');
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showMiniToast('Hanya ada 1 kamera pada perangkat');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final targetZoom = zoom.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _cameraController!.setZoomLevel(targetZoom);
      setState(() {
        _currentZoomLevel = targetZoom;
      });
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  Future<void> _onTapToFocus(TapUpDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    HapticFeedback.selectionClick();

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusRing = true;
    });

    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showFocusRing = false;
        });
      }
    });
  }

  // --- CAPTURE & AI ANALYSIS ---

  Future<void> _captureAndAnalyze() async {
    if (_isCapturing || _isAnalyzing) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _isCapturing = true;
    });

    File? capturedFile;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile file = await _cameraController!.takePicture();
        capturedFile = File(file.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }

    setState(() {
      _isCapturing = false;
      _isAnalyzing = true;
    });

    if (_scanMode == 0) {
      // Mode AI Waste Scan via NodeJS Gemini Backend API
      final result = await BackendApiService.instance.analyzeWasteImageWithBackend(
        imageFile: capturedFile,
        categoryFilter: _categoryFilter,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        _showAiResultSheet(result);
      }
    } else {
      // Mode QR Code Scan
      final qrResult = await CameraService.instance.parseQrCode(
        'DROP-POINT-MELATI-${DateTime.now().millisecond}',
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        _showQrResultSheet(qrResult);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (picked != null && mounted) {
        final file = File(picked.path);
        setState(() {
          _isAnalyzing = true;
        });

        final result = await BackendApiService.instance.analyzeWasteImageWithBackend(
          imageFile: file,
          categoryFilter: _categoryFilter,
        );

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });

          _showAiResultSheet(result);
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      _showMiniToast('Gagal memuat foto dari galeri');
    }
  }

  Future<void> _pickFromSystemCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (picked != null && mounted) {
        final file = File(picked.path);
        setState(() {
          _isAnalyzing = true;
        });

        final result = await BackendApiService.instance.analyzeWasteImageWithBackend(
          imageFile: file,
          categoryFilter: _categoryFilter,
        );

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });

          _showAiResultSheet(result);
        }
      }
    } catch (e) {
      debugPrint('Error picking from system camera: $e');
      _showMiniToast('Gagal membuka kamera sistem');
    }
  }

  void _showMiniToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        backgroundColor: const Color(0xFF0D6938),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 90, left: 40, right: 40),
      ),
    );
  }

  // --- RESULT SHEETS ---

  void _showAiResultSheet(AiWasteScanResult result) {
    double currentWeight = result.estimatedWeightKg;
    WasteItemModel selectedItem = result.wasteItem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final method = widget.isPickup ? CollectionMethod.pickup : CollectionMethod.dropOff;
            final calcResult = TrashToCashCalculator.calculateResult(
              weightKg: currentWeight,
              ratePerKg: selectedItem.ratePerKg,
              ecoWeightPerKg: selectedItem.ecoPoints.toDouble(),
              method: method,
              currentMemberPoints: DatabaseHelper.userEcoPointsNotifier.value,
            );
            final double reward = calcResult.finalTCashReward;
            final int points = calcResult.finalEcoPoints;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2822) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header with Status Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF00E676),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFF00C853),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Vision: ${(result.confidenceScore * 100).toStringAsFixed(1)}% Akurat',
                                    style: const TextStyle(
                                      color: Color(0xFF00C853),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Preview & Detected Item Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D6938), Color(0xFF1B5E20)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Captured image or fallback icon
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 76,
                                    height: 76,
                                    child: result.capturedFile != null
                                        ? Image.file(
                                            result.capturedFile!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            selectedItem.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              color: Colors.white24,
                                              child: Icon(
                                                selectedItem.icon,
                                                color: Colors.white,
                                                size: 36,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedItem.isOrganic
                                              ? const Color(0xFF66BB6A)
                                              : const Color(0xFF29B6F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          selectedItem.type.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedItem.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tarif: ${DatabaseHelper.formatRupiah(selectedItem.ratePerKg >= 100 ? selectedItem.ratePerKg : selectedItem.ratePerKg * 1000)}/kg • +${selectedItem.ecoPoints} Poin/kg',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Weight Adjustment Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF263229)
                                  : const Color(0xFFF4F8F5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFD6EFE2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Estimasi Berat Sampah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D6938),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${currentWeight.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: currentWeight > 0.5
                                          ? () {
                                              setSheetState(() {
                                                currentWeight = double.parse(
                                                  (currentWeight - 0.5)
                                                      .toStringAsFixed(1),
                                                );
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: const Color(0xFF0D6938),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: currentWeight,
                                        min: 0.5,
                                        max: 30.0,
                                        divisions: 59,
                                        activeColor: const Color(0xFF0D6938),
                                        inactiveColor: isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300,
                                        onChanged: (val) {
                                          setSheetState(() {
                                            currentWeight = double.parse(
                                              val.toStringAsFixed(1),
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: currentWeight < 50.0
                                          ? () {
                                              setSheetState(() {
                                                currentWeight = double.parse(
                                                  (currentWeight + 0.5)
                                                      .toStringAsFixed(1),
                                                );
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: const Color(0xFF0D6938),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Reward Calculation Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF81C784),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'Estimasi Saldo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DatabaseHelper.formatRupiah(reward >= 100 ? reward : reward * 1000),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Bonus EcoPoints',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+$points Poin 🌱',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Recycling Tip
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF263229)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tips Pemilahan Sampah:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        result.recyclingAdvice,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6938),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _proceedToTransaction(selectedItem, currentWeight);
                            },
                            child: Text(
                              widget.isPickup
                                  ? 'Lanjut Jemput Sampah (Detail) 🛵'
                                  : 'Lanjut Drop-off Sampah (Setor) 📦',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text(
                                  'Foto Ulang',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: Color(0xFF0D6938),
                                ),
                                label: const Text(
                                  'Ganti Jenis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _showManualItemPickerDialog(currentWeight);
                                },
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
          },
        );
      },
    );
  }

  void _showQrResultSheet(QrCodeScanResult qrResult) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF0D6938),
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                qrResult.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                qrResult.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A362D) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Kode: ${qrResult.rawCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6938),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loket Drop Point Berhasil Diverifikasi!'),
                        backgroundColor: Color(0xFF0D6938),
                      ),
                    );
                  },
                  child: const Text(
                    'Konfirmasi Drop Point Ini',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualItemPickerDialog(double currentWeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Kategori Sampah Manual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _allWasteItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = _allWasteItems[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isOrganic
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFE1F5FE),
                        child: Icon(
                          item.icon,
                          color: item.isOrganic
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF0288D1),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${item.type} • ${DatabaseHelper.formatRupiah(item.ratePerKg >= 100 ? item.ratePerKg : item.ratePerKg * 1000)}/kg',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        _proceedToTransaction(item, currentWeight);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _proceedToTransaction(WasteItemModel item, double weight) {
    final double totalReward = weight * item.ratePerKg;

    if (widget.isPickup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailJemputScreen(
            categoryName: item.name,
            sampleItem: item.sampleItem,
            weightKg: weight,
            ratePerKg: item.ratePerKg,
            totalReward: totalReward,
            wasteType: item.type,
            ecoPointsPerKg: item.ecoPoints,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailTransaksiScreen(
            categoryName: item.name,
            sampleItem: item.sampleItem,
            weightKg: weight,
            ratePerKg: item.ratePerKg,
            totalReward: totalReward,
            wasteType: item.type,
            ecoPointsPerKg: item.ecoPoints,
            dropPointName: 'Bank Sampah Melati - Drop Point Pusat',
            dropPointAddress: 'Jl. Kebon Kacang Raya No.10, Jakarta Pusat',
          ),
        ),
      );
    }
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Preview / Simulation
              _buildCameraFeed(constraints),

              // 2. Grid Guidelines (Rule of thirds)
              if (_showGrid) _buildGridOverlay(),

              // 3. Animated Scanning Laser & Viewfinder Reticle
              _buildScannerReticle(constraints),

              // 4. Tap-to-Focus Indicator
              if (_showFocusRing && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 30,
                  top: _focusPoint!.dy - 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00E676),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              // 5. Top Bar HUD (Back, Mode, Flash, Switch, Grid)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHudBar(),
              ),

              // 6. Category Filter Chip Bar (When in AI Mode)
              if (_scanMode == 0)
                Positioned(
                  top: 110,
                  left: 0,
                  right: 0,
                  child: _buildCategoryFilterBar(),
                ),

              // 7. Zoom Preset Selector Pills
              Positioned(
                bottom: 155,
                left: 0,
                right: 0,
                child: _buildZoomSelector(),
              ),

              // 8. Bottom Control Deck (Gallery, Shutter, Guide/Items)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControlDeck(),
              ),

              // 9. Neural AI Analyzing Progress Overlay
              if (_isAnalyzing) _buildAnalyzingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraFeed(BoxConstraints constraints) {
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return GestureDetector(
        onScaleStart: (details) {
          _baseScale = _currentZoomLevel;
        },
        onScaleUpdate: (details) {
          _setZoom(_baseScale * details.scale);
        },
        onTapUp: (details) => _onTapToFocus(details, constraints),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ??
                  constraints.maxWidth,
              height: _cameraController!.value.previewSize?.width ??
                  constraints.maxHeight,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    // Fallback Simulation Viewfinder (when camera hardware is not available)
    return GestureDetector(
      onTapUp: (details) => _onTapToFocus(details, constraints),
      child: Container(
        color: const Color(0xFF0B140E),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.network(
                  'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=1200',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.expand(),
                ),
              ),
            ),
            if (_cameraError)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_enhance_outlined,
                        color: Color(0xFF00E676),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Simulasi Kamera AI Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildScannerReticle(BoxConstraints constraints) {
    final double boxWidth = constraints.maxWidth * 0.76;
    final double boxHeight = _scanMode == 0 ? 250 : boxWidth;
    final double topOffset = (constraints.maxHeight - boxHeight) / 2 - 20;
    final double leftOffset = (constraints.maxWidth - boxWidth) / 2;

    return Positioned(
      top: topOffset,
      left: leftOffset,
      child: SizedBox(
        width: boxWidth,
        height: boxHeight,
        child: Stack(
          children: [
            // Dark vignette mask outside reticle border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),

            // 4 Futuristic Glowing Corner Brackets
            // Top-Left
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF00E676), width: 4),
                    left: BorderSide(color: Color(0xFF00E676), width: 4),
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),
            ),
            // Top-Right
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF00E676), width: 4),
                    right: BorderSide(color: Color(0xFF00E676), width: 4),
                  ),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                ),
              ),
            ),
            // Bottom-Left
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF00E676), width: 4),
                    left: BorderSide(color: Color(0xFF00E676), width: 4),
                  ),
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(16)),
                ),
              ),
            ),
            // Bottom-Right
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF00E676), width: 4),
                    right: BorderSide(color: Color(0xFF00E676), width: 4),
                  ),
                  borderRadius:
                      BorderRadius.only(bottomRight: Radius.circular(16)),
                ),
              ),
            ),

            // Animated Laser Sweep Line
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                return Positioned(
                  top: boxHeight * _laserAnimation.value,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF00E676),
                          Colors.white,
                          Color(0xFF00E676),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.9),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Scanner Status Pill inside Reticle
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _scanMode == 0
                        ? '⚡ Arahkan kamera ke objek sampah'
                        : '📷 Arahkan ke QR Code loket/kurir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHudBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),

                // Mode Switcher (AI Sampah vs QR Scanner)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      _buildModeSegment(
                        label: 'AI Sampah',
                        icon: Icons.auto_awesome,
                        isSelected: _scanMode == 0,
                        onTap: () {
                          setState(() => _scanMode = 0);
                        },
                      ),
                      _buildModeSegment(
                        label: 'Scan QR',
                        icon: Icons.qr_code_scanner,
                        isSelected: _scanMode == 1,
                        onTap: () {
                          setState(() => _scanMode = 1);
                        },
                      ),
                    ],
                  ),
                ),

                // Guide/Panduan Button
                IconButton(
                  icon: const Icon(
                    Icons.menu_book_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Panduan Scan',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PanduanDaurUlangScreen(
                          initialTabIndex: 0,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Sub-bar controls (Flash, Grid, Flip)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHudIconButton(
                    icon: _getFlashIcon(),
                    label: _getFlashLabel(),
                    onTap: _toggleFlash,
                  ),
                  const SizedBox(width: 16),
                  _buildHudIconButton(
                    icon: _showGrid ? Icons.grid_on : Icons.grid_off,
                    label: 'Grid',
                    isSelected: _showGrid,
                    onTap: () {
                      setState(() => _showGrid = !_showGrid);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildHudIconButton(
                    icon: Icons.flip_camera_ios_outlined,
                    label: 'Putar',
                    onTap: _switchCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6938) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00E676) : Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudIconButton({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00E676) : Colors.white,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00E676) : Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.torch:
        return Icons.highlight;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
    }
  }

  String _getFlashLabel() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return 'Flash Off';
      case FlashMode.torch:
        return 'Torch';
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'Flash On';
    }
  }

  Widget _buildCategoryFilterBar() {
    final categories = ['Semua', 'Organik', 'Non-Organik'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((cat) {
          final isSelected = _categoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selected: isSelected,
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  _categoryFilter = cat;
                });
              },
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              selectedColor: const Color(0xFF0D6938),
              checkmarkColor: const Color(0xFF00E676),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildZoomSelector() {
    final zoomPresets = [1.0, 2.0, 3.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: zoomPresets.map((zoom) {
        final isSelected = (_currentZoomLevel - zoom).abs() < 0.2;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _setZoom(zoom);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
              ),
            ),
            child: Text(
              '${zoom.toInt()}x',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomControlDeck() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.9),
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Gallery & System Camera Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _pickFromGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Galeri',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _pickFromSystemCamera,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.camera_enhance_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kamera HP',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),

          // 2. Large Interactive Shutter Button
          GestureDetector(
            onTap: _captureAndAnalyze,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E676),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFF0D6938),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Manual Catalog Picker Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _showManualItemPickerDialog(2.5),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Katalog',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00E676),
                    width: 2,
                  ),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF00E676),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🧠 AI Vision Mengidentifikasi Sampah...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Menganalisis jenis material, kemurnian & estimasi nilai',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Vertical lines
    final double oneThirdW = size.width / 3;
    final double twoThirdW = (size.width / 3) * 2;
    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdW, 0), Offset(twoThirdW, size.height), paint);

    // Horizontal lines
    final double oneThirdH = size.height / 3;
    final double twoThirdH = (size.height / 3) * 2;
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdH), Offset(size.width, twoThirdH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
