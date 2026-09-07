import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/trash_calculator_helper.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/screens/detail_jemput_screen.dart';
import 'package:trashtocash/screens/detail_transaksi_screen.dart';
import 'package:trashtocash/screens/live_camera_scan_screen.dart';
import 'package:trashtocash/screens/panduan_sampah_screen.dart';

class WasteCategory {
  final String id;
  final String name;
  final String type; // 'Organik' or 'Non-Organik'
  final String sampleItem;
  final double ratePerKg;
  final int ecoPoints;
  final IconData icon;
  final String imageUrl;
  final String description;
  final String handlingTip;

  const WasteCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.sampleItem,
    required this.ratePerKg,
    this.ecoPoints = 10,
    required this.icon,
    required this.imageUrl,
    this.description = '',
    this.handlingTip = '',
  });

  bool get isOrganic => type.toLowerCase() == 'organik';

  factory WasteCategory.fromModel(WasteItemModel model) {
    return WasteCategory(
      id: model.id?.toString() ?? model.name.toLowerCase().replaceAll(' ', '_'),
      name: model.name,
      type: model.type,
      sampleItem: model.sampleItem,
      ratePerKg: model.ratePerKg,
      ecoPoints: model.ecoPoints,
      icon: model.icon,
      imageUrl: model.imageUrl,
      description: model.description,
      handlingTip: model.handlingTip,
    );
  }
}

class ScanSampahScreen extends StatefulWidget {
  final bool isPickup;

  const ScanSampahScreen({super.key, this.isPickup = false});

  @override
  State<ScanSampahScreen> createState() => _ScanSampahScreenState();
}

class _ScanSampahScreenState extends State<ScanSampahScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  bool _isFlashOn = false;
  final bool _isScanning = true;
  double _weight = 2.5; // default 2.5 kg

  File? _capturedImageFile;
  bool _isAiAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  String _filterType = 'Semua'; // 'Semua', 'Organik', 'Non-Organik'
  List<WasteCategory> _allCategories = [];
  late WasteCategory _selectedCategory;
  bool _isLoading = true;

  // Fallback initial categories if DB is loading
  static const List<WasteCategory> _fallbackCategories = [
    WasteCategory(
      id: 'plastik_pet',
      name: 'Plastik PET (Botol Mineral Bening)',
      type: 'Non-Organik',
      sampleItem: 'Botol air mineral bening, botol jus transparan',
      ratePerKg: 10000.0,
      ecoPoints: 20,
      icon: Icons.local_drink_outlined,
      imageUrl:
          'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=600',
      description: 'Plastik PET bening bernilai daur ulang tinggi untuk serat tekstil daur ulang.',
      handlingTip: 'Bilas bersih, lepas tutup botol & label plastik, lalu kempeskan botol.',
    ),
    WasteCategory(
      id: 'sisa_makanan',
      name: 'Sisa Makanan & Dapur',
      type: 'Organik',
      sampleItem: 'Sisa nasi, lauk pauk, sisa hidangan basi & mie',
      ratePerKg: 4000.0,
      ecoPoints: 10,
      icon: Icons.compost,
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=600',
      description: 'Limbah sisa makanan dapur untuk biokonversi maggot atau pupuk kompos cair.',
      handlingTip: 'Tiriskan air kuah dan buang plastik pembungkus sebelum disetor.',
    ),
    WasteCategory(
      id: 'kardus',
      name: 'Kardus Box & Karton Cokelat',
      type: 'Non-Organik',
      sampleItem: 'Kardus paket pengiriman, karton tebal gelombang',
      ratePerKg: 8000.0,
      ecoPoints: 15,
      icon: Icons.inventory_outlined,
      imageUrl:
          'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?auto=format&fit=crop&q=80&w=600',
      description: 'Kardus gelombang bebas isolasi untuk bubur kertas daur ulang.',
      handlingTip: 'Bongkar dan lipat pipih, lepaskan lakban/isolasi plastik dan staples.',
    ),
    WasteCategory(
      id: 'daun_ranting',
      name: 'Daun, Ranting & Rumput Kebun',
      type: 'Organik',
      sampleItem: 'Daun kering gugur, rumput tebas, potongan ranting',
      ratePerKg: 3000.0,
      ecoPoints: 8,
      icon: Icons.energy_savings_leaf,
      imageUrl:
          'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&q=80&w=600',
      description: 'Bahan organik cokelat kaya karbon padat untuk bahan dasar kompos padat.',
      handlingTip: 'Kumpulkan dalam keadaan kering atau masukkan karung terikat rapi.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _fallbackCategories[0];
    _allCategories = _fallbackCategories;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadWasteDataFromDatabase();
  }

  // Load organic and non-organic waste data from SQLite Database
  Future<void> _loadWasteDataFromDatabase() async {
    try {
      final dbItems = await DatabaseHelper.instance.getAllWasteItems();
      if (dbItems.isNotEmpty && mounted) {
        setState(() {
          _allCategories = dbItems.map((e) => WasteCategory.fromModel(e)).toList();
          _selectedCategory = _allCategories.first;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading waste items from SQLite: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<WasteCategory> get _filteredCategories {
    if (_filterType == 'Semua') {
      return _allCategories;
    }
    return _allCategories.where((c) => c.type.toLowerCase() == _filterType.toLowerCase()).toList();
  }

  int get _organicCount => _allCategories.where((c) => c.type.toLowerCase() == 'organik').length;
  int get _nonOrganicCount => _allCategories.where((c) => c.type.toLowerCase() == 'non-organik').length;

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  CalculationResult get _calcResult => TrashToCashCalculator.calculateResult(
        weightKg: _weight,
        ratePerKg: _selectedCategory.ratePerKg,
        ecoWeightPerKg: _selectedCategory.ecoPoints.toDouble(),
        method: CollectionMethod.dropOff,
        currentMemberPoints: DatabaseHelper.userEcoPointsNotifier.value,
      );

  double get _totalEstimatedReward => _calcResult.finalTCashReward;
  int get _totalEstimatedEcoPoints => _calcResult.finalEcoPoints;

  void _incrementWeight(double amount) {
    setState(() {
      _weight = (_weight + amount).clamp(0.1, 100.0);
      _weight = double.parse(_weight.toStringAsFixed(1));
    });
  }

  void _proceedToDetail() {
    if (widget.isPickup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailJemputScreen(
            categoryName: _selectedCategory.name,
            sampleItem: _selectedCategory.sampleItem,
            weightKg: _weight,
            ratePerKg: _selectedCategory.ratePerKg,
            totalReward: _totalEstimatedReward,
            wasteType: _selectedCategory.type,
            ecoPointsPerKg: _selectedCategory.ecoPoints,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailTransaksiScreen(
            categoryName: _selectedCategory.name,
            sampleItem: _selectedCategory.sampleItem,
            weightKg: _weight,
            ratePerKg: _selectedCategory.ratePerKg,
            totalReward: _totalEstimatedReward,
            wasteType: _selectedCategory.type,
            ecoPointsPerKg: _selectedCategory.ecoPoints,
            dropPointName: 'Bank Sampah Melati - Drop Point Pusat',
            dropPointAddress: 'Jl. Kebon Kacang Raya No.10, Jakarta Pusat',
          ),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _capturedImageFile = File(picked.path);
          _isAiAnalyzing = true;
        });

        // Simulasi analisis AI Vision
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          setState(() {
            _isAiAnalyzing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0D6938),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Berhasil Mendeteksi: ${_selectedCategory.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _openLiveCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveCameraScanScreen(
          isPickup: widget.isPickup,
          preselectedItem: WasteItemModel(
            name: _selectedCategory.name,
            type: _selectedCategory.type,
            sampleItem: _selectedCategory.sampleItem,
            ratePerKg: _selectedCategory.ratePerKg,
            ecoPoints: _selectedCategory.ecoPoints,
            iconName: 'recycle',
            imageUrl: _selectedCategory.imageUrl,
            description: _selectedCategory.description,
            handlingTip: _selectedCategory.handlingTip,
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Foto Sampah untuk Deteksi AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text(
                  'Ambil foto langsung, gunakan Live Camera AI real-time, atau unggah dari galeri.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Row(
                    children: [
                      Text(
                        'Buka Live Camera AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '⭐ Real-Time',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Kamera interaktif + HUD scan laser + deteksi instan',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openLiveCamera();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera, color: Color(0xFF0D6938)),
                  ),
                  title: const Text(
                    'Kamera Sistem Ponsel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Ambil foto menggunakan aplikasi kamera bawaan',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Color(0xFF0D6938)),
                  ),
                  title: const Text(
                    'Pilih dari Galeri Foto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Pilih foto dari penyimpanan perangkat',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_capturedImageFile != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh, color: Colors.redAccent),
                    ),
                    title: const Text(
                      'Kembalikan ke Contoh Bawaan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _capturedImageFile = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPickup
              ? 'Scan Sampah (Jemput)'
              : 'Scan Sampah (Drop-off)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            tooltip: 'Buka Live Camera Scanner',
            onPressed: _openLiveCamera,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: Colors.white),
            tooltip: 'Panduan Daur Ulang & Scan Foto',
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
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFlashOn ? 'Flash dinyalakan' : 'Flash dimatikan',
                  ),
                  duration: const Duration(milliseconds: 700),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Scanner Camera Viewfinder Section (Green Theme)
            Container(
              height: 280,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background Camera / Photo Viewfinder
                    Positioned.fill(
                      child: _capturedImageFile != null
                          ? Image.file(
                              _capturedImageFile!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _selectedCategory.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Dark tint overlay for scanner contrast
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),

                    // Viewfinder box borders
                    Center(
                      child: Container(
                        width: 220,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    // Scanner Corner Accents (Top-Left)
                    Positioned(
                      top: 40,
                      left: (MediaQuery.of(context).size.width - 32 - 220) / 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                            left: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scanner Corner Accents (Top-Right)
                    Positioned(
                      top: 40,
                      right: (MediaQuery.of(context).size.width - 32 - 220) / 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                            right: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scanner Corner Accents (Bottom-Left)
                    Positioned(
                      bottom: 40,
                      left: (MediaQuery.of(context).size.width - 32 - 220) / 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                            left: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scanner Corner Accents (Bottom-Right)
                    Positioned(
                      bottom: 40,
                      right: (MediaQuery.of(context).size.width - 32 - 220) / 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                            right: BorderSide(
                              color: Color(0xFF00E676),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Animated Laser Scanning Line (Green Laser)
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 40 + (200 * _scanAnimation.value),
                            left:
                                (MediaQuery.of(context).size.width - 32 - 200) /
                                2,
                            child: Container(
                              width: 200,
                              height: 3,
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
                                    color: const Color(0xFF00E676).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // AI Analyzing Overlay when image is processing
                    if (_isAiAnalyzing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF00E676),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '⚡ AI Memindai Gambar...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // AI Detection Badge Top-Left Overlay (Green Accent)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00E676),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCategory.isOrganic
                                  ? '🌱 AI Detect: Organik (98%)'
                                  : '♻️ AI Detect: Non-Organik (99%)',
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

                    // Quick Camera Capture Button (Top-Right)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showImageSourceDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6938),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00E676),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Ambil Foto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scan instruction chip at bottom
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0D6938).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Kategori: ${_selectedCategory.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Guide Banner Link under Viewfinder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2C21)
                          : const Color(0xFFEAF4EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Color(0xFF0D6938),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tips Foto: Pastikan cahaya cukup & sampah bersih. Baca panduan lengkap →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D6938),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Kategori Sampah yang Terdeteksi & Filter Spesifik
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategori Sampah Terdeteksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filtered.length} Jenis Tersedia',
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
            const SizedBox(height: 10),

            // Filter Tabs Spesifik (Semua, Organik, Non-Organik) - All Green Palette
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterTab(
                    label: 'Semua (${_allCategories.length})',
                    icon: Icons.layers_outlined,
                    isSelected: _filterType == 'Semua',
                    onTap: () {
                      setState(() {
                        _filterType = 'Semua';
                        if (filtered.isNotEmpty && !filtered.contains(_selectedCategory)) {
                          _selectedCategory = filtered.first;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: '🌱 Organik ($_organicCount)',
                    icon: Icons.eco,
                    isSelected: _filterType == 'Organik',
                    onTap: () {
                      setState(() {
                        _filterType = 'Organik';
                        final org = _allCategories.where((c) => c.isOrganic).toList();
                        if (org.isNotEmpty) {
                          _selectedCategory = org.first;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: '♻️ Non-Org ($_nonOrganicCount)',
                    icon: Icons.recycling,
                    isSelected: _filterType == 'Non-Organik',
                    onTap: () {
                      setState(() {
                        _filterType = 'Non-Organik';
                        final nonOrg = _allCategories.where((c) => !c.isOrganic).toList();
                        if (nonOrg.isNotEmpty) {
                          _selectedCategory = nonOrg.first;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Category Selector Cards (Green Style)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0xFF0D6938)),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada sampah kategori $_filterType ditemukan di database.',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = filtered[index];
                    final isSelected = cat.id == _selectedCategory.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 126,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF0D6938).withValues(alpha: 0.35)
                                  : const Color(0xFFD6EFE2))
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D6938)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  cat.icon,
                                  color: const Color(0xFF0D6938),
                                  size: 22,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cat.isOrganic ? 'Organik' : 'Non-Org',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D6938),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              textAlign: TextAlign.start,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0D6938)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DatabaseHelper.formatRupiah(cat.ratePerKg),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                                Text(
                                  '/kg',
                                  style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // 3. Detail Spesifik Sampah Terpilih (Green Theme Card)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.15),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedCategory.icon,
                          color: const Color(0xFF0D6938),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCategory.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D6938),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _selectedCategory.type,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tarif: ${DatabaseHelper.formatRupiah(_selectedCategory.ratePerKg)}/kg • +${_selectedCategory.ecoPoints} Poin Eco/kg',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D6938),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Detail Contoh Barang
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.category_outlined, size: 15, color: Color(0xFF0D6938)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contoh Sampah Spesifik:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCategory.sampleItem,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Panduan / Tips Penanganan Khusus
                  if (_selectedCategory.handlingTip.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2C21)
                            : const Color(0xFFF0F9F4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0D6938).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Color(0xFF0D6938),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCategory.isOrganic
                                      ? 'Panduan Pilah Organik:'
                                      : 'Panduan Pilah Non-Organik:',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedCategory.handlingTip,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Penyesuaian Berat Sampah (Green Theme)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        'Perkiraan Berat Sampah',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${DatabaseHelper.formatRupiah(_selectedCategory.ratePerKg)} / kg',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Counter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWeightButton(
                        icon: Icons.remove,
                        onTap: () => _incrementWeight(-0.5),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF263229)
                              : const Color(0xFFF4F8F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _weight.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6938),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildWeightButton(
                        icon: Icons.add,
                        onTap: () => _incrementWeight(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Preset quick buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetChip('+0.5 kg', 0.5),
                      _buildPresetChip('+1.0 kg', 1.0),
                      _buildPresetChip('+2.0 kg', 2.0),
                      _buildPresetChip('+5.0 kg', 5.0),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Ringkasan Estimasi Saldo (All Green Gradient)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D6938), Color(0xFF13874B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Pendapatan Saldo',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${DatabaseHelper.formatRupiah(_totalEstimatedReward)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+$_totalEstimatedEcoPoints Poin Eco',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Tombol Lanjut ke Detail Transaksi (Green Theme)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6938),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isPickup
                            ? 'Lanjut ke Detail Penjemputan'
                            : 'Lanjut ke Detail Transaksi',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0D6938)
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF263229)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D6938) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF0D6938),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFEAF4EE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: const Color(0xFF0D6938),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double addWeight) {
    return GestureDetector(
      onTap: () => _incrementWeight(addWeight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0D6938).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D6938),
          ),
        ),
      ),
    );
  }
}
