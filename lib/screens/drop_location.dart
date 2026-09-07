import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/screens/onging_deposit.dart';
import 'package:trashtocash/services/location_service.dart';

enum MapThemeStyle { googleStandard, satellite, vectorEco }

class DropPointLocationScreen extends StatefulWidget {
  const DropPointLocationScreen({super.key});

  @override
  State<DropPointLocationScreen> createState() =>
      _DropPointLocationScreenState();
}

class _DropPointLocationScreenState extends State<DropPointLocationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedPointIndex = 0;
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;
  late AnimationController _pulseController;
  bool _isRequestingGps = false;
  MapThemeStyle _currentTheme = MapThemeStyle.googleStandard;

  List<Map<String, dynamic>> _baseDropPoints = [
    {
      'id': 1,
      'name': 'Recycling Center Central',
      'address': 'Jl. Hijau Daun No. 45, Jakarta Selatan',
      'lat': -6.2115,
      'lng': 106.8480,
      'hours': 'Buka 08:00 - 17:00',
      'status': 'Buka Sekarang',
      'categories': ['Plastik', 'Kertas', 'Logam', 'E-Waste'],
      'mapX': 0.35,
      'mapY': 0.40,
    },
    {
      'id': 2,
      'name': 'Bank Sampah Melati Pusat',
      'address': 'Jl. Kebon Kacang Raya Blok C2, Jakarta Pusat',
      'lat': -6.2085,
      'lng': 106.8450,
      'hours': 'Buka 08:30 - 17:30',
      'status': 'Buka Sekarang',
      'categories': ['Plastik PET', 'Kardus', 'Kaca', 'Minyak'],
      'mapX': 0.65,
      'mapY': 0.35,
    },
    {
      'id': 3,
      'name': 'Eco Point Gandaria',
      'address': 'Jl. Gandaria Indah No. 12, Jakarta Selatan',
      'lat': -6.2440,
      'lng': 106.7860,
      'hours': 'Buka 08:30 - 18:00',
      'status': 'Buka Sekarang',
      'categories': ['Semua Jenis Sampah', 'Kompos', 'Elektronik'],
      'mapX': 0.55,
      'mapY': 0.75,
    },
    {
      'id': 4,
      'name': 'Depo Daur Ulang Kebayoran',
      'address': 'Jl. Kebayoran Baru No. 88, Jakarta Selatan',
      'lat': -6.2480,
      'lng': 106.7980,
      'hours': 'Buka 08:00 - 16:00',
      'status': 'Buka Sekarang',
      'categories': ['Plastik', 'Logam', 'Baterai & Aki'],
      'mapX': 0.20,
      'mapY': 0.70,
    },
    {
      'id': 5,
      'name': 'Bank Sampah Berseri Senayan',
      'address': 'Jl. Asia Afrika Pintu 9, Gelora, Jakarta Pusat',
      'lat': -6.2210,
      'lng': 106.8020,
      'hours': 'Buka 09:00 - 17:00',
      'status': 'Buka Sekarang',
      'categories': ['Botol Plastik', 'Kaleng', 'Kertas HVS', 'Jelantah'],
      'mapX': 0.80,
      'mapY': 0.50,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _loadDropPointsFromDb();
    _initGpsLocation();
    LocationService.instance.userLocationNotifier.addListener(_onLocationUpdate);
  }

  Future<void> _loadDropPointsFromDb() async {
    try {
      final dbPoints = await DatabaseHelper.instance.getAllDropPoints();
      if (dbPoints.isNotEmpty && mounted) {
        setState(() {
          _baseDropPoints = dbPoints.map((dp) {
            final catStr = dp['categories'] as String? ?? '';
            final catList = catStr.split(',').map((s) => s.trim()).toList();
            return {
              'id': dp['id'],
              'name': dp['name'],
              'address': dp['address'],
              'lat': (dp['lat'] as num).toDouble(),
              'lng': (dp['lng'] as num).toDouble(),
              'hours': dp['hours'] ?? 'Buka 08:00 - 17:00',
              'status': dp['status'] ?? 'Buka Sekarang',
              'categories': catList,
              'mapX': (dp['map_x'] as num?)?.toDouble() ?? 0.5,
              'mapY': (dp['map_y'] as num?)?.toDouble() ?? 0.5,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _onLocationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initGpsLocation() async {
    setState(() {
      _isRequestingGps = true;
    });

    await LocationService.instance.requestLocationPermission();
    LocationService.instance.startLiveTracking();

    if (mounted) {
      setState(() {
        _isRequestingGps = false;
      });
    }
  }

  @override
  void dispose() {
    LocationService.instance.userLocationNotifier
        .removeListener(_onLocationUpdate);
    LocationService.instance.stopLiveTracking();
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _computedDropPoints {
    final userState = LocationService.instance.currentState;
    final query = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> points = _baseDropPoints.map((point) {
      final double pLat = (point['lat'] as num).toDouble();
      final double pLng = (point['lng'] as num).toDouble();

      final double distanceKm = LocationService.instance.calculateDistanceKm(
        userState.latitude,
        userState.longitude,
        pLat,
        pLng,
      );

      final eta = LocationService.instance.getEtaEstimate(distanceKm);

      return {
        ...point,
        'distanceKm': distanceKm,
        'distanceStr': '$distanceKm km',
        'drivingEta': eta['driving'],
        'walkingEta': eta['walking'],
      };
    }).toList();

    // Sort by nearest distance to user's real GPS
    points.sort((a, b) =>
        (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    if (query.isEmpty) return points;

    return points.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final address = (p['address'] as String).toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();
  }

  void _resetMapCamera() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoomLevel = 1.0;
      _mapOffset = Offset.zero;
    });
  }

  Future<void> _onGpsRecenterPressed() async {
    _resetMapCamera();
    await LocationService.instance.refreshCurrentLocation();
    if (!mounted) return;
    final latestState = LocationService.instance.currentState;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D6938),
        content: Row(
          children: [
            const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lokasi GPS Diperbarui: ${latestState.streetAddress} (±${latestState.accuracy.toStringAsFixed(0)}m)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userState = LocationService.instance.currentState;
    final filtered = _computedDropPoints;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text(
          'Lokasi Drop Point & GPS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isRequestingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Pusatkan ke Lokasi Saya (GPS)',
            onPressed: _onGpsRecenterPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live GPS Info & Permission Banner
          _buildGpsStatusBar(isDark, userState),

          // 2. Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Cari area, nama jalan, atau cabang drop point...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D6938), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF263229)
                    : const Color(0xFFF4F8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              ),
            ),
          ),

          // 3. Interactive Vector Map Canvas
          _buildMapSection(isDark, filtered, userState),

          // 4. Drop Points List Section Header & Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drop Point Terdekat (${filtered.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.near_me, size: 12, color: Color(0xFF0D6938)),
                          SizedBox(width: 4),
                          Text(
                            'GPS Terurut Otomatis',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D6938),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lokasi Drop Point Tidak Ditemukan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba gunakan kata kunci pencarian yang lain.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final isSelected = _selectedPointIndex == index;
                    return _buildDropPointCard(
                      context,
                      point,
                      index,
                      isSelected,
                      isDark,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GPS STATUS BAR & PERMISSION PROMPT ---
  Widget _buildGpsStatusBar(bool isDark, UserGpsState userState) {
    if (!userState.hasPermission) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF3E0),
          border: Border(
            bottom: BorderSide(color: Color(0xFFFFB74D), width: 1),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_disabled, color: Color(0xFFE65100), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Izin GPS Belum Aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  Text(
                    'Izinkan akses lokasi ponsel agar jarak ke drop point terhitung akurat.',
                    style: TextStyle(fontSize: 10.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _initGpsLocation,
              child: const Text(
                'Izinkan',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Active Live GPS Bar
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFD6EFE2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'GPS Real-Time: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF0D6938),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${userState.streetAddress} (±${userState.accuracy.toStringAsFixed(0)}m)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            userState.coordinatesDisplay,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: isDark ? Colors.white38 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // --- MAP SECTION WIDGET ---
  Widget _buildMapSection(
    bool isDark,
    List<Map<String, dynamic>> points,
    UserGpsState userState,
  ) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231D) : const Color(0xFFE5EEE7),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Interactive Pan & Zoom Map Canvas
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _mapOffset += details.delta;
              });
            },
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: _ModernMapPainter(
                  isDark: isDark,
                  theme: _currentTheme,
                  zoom: _zoomLevel,
                  offset: _mapOffset,
                  selectedPoint: points.isNotEmpty &&
                          _selectedPointIndex < points.length
                      ? points[_selectedPointIndex]
                      : null,
                ),
              ),
            ),
          ),

          // Top Left: Map Style Theme Switcher Pills
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2822).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemePill(
                    label: 'Peta 🗺️',
                    theme: MapThemeStyle.googleStandard,
                    isDark: isDark,
                  ),
                  _buildThemePill(
                    label: 'Satelit 🛰️',
                    theme: MapThemeStyle.satellite,
                    isDark: isDark,
                  ),
                  _buildThemePill(
                    label: 'Eco 🌱',
                    theme: MapThemeStyle.vectorEco,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // User Real GPS Location Marker (Authentic Google Maps Blue Dot with Ripple Halo)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final userX = (constraints.maxWidth * 0.5) + _mapOffset.dx;
                final userY = (constraints.maxHeight * 0.5) + _mapOffset.dy;

                return Stack(
                  children: [
                    // Outer Google Maps blue pulsing wave
                    Positioned(
                      left: userX - 26,
                      top: userY - 26,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (ctx, child) {
                          final scale = 1.0 + (_pulseController.value * 1.4);
                          final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4285F4)
                                    .withValues(alpha: opacity * 0.30),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Inner Google Maps Blue GPS Dot
                    Positioned(
                      left: userX - 10,
                      top: userY - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A73E8),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Drop Point Interactive Google Maps Red Teardrop Pins
          Positioned.fill(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return Stack(
                  children: points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final isSelected = _selectedPointIndex == index;

                    final double pinX =
                        (constraints.maxWidth * (point['mapX'] as double)) +
                            _mapOffset.dx;
                    final double pinY =
                        (constraints.maxHeight * (point['mapY'] as double)) +
                            _mapOffset.dy;

                    return Positioned(
                      left: pinX - 24,
                      top: pinY - 44,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedPointIndex = index;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Distance Badge Bubble
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEA4335)
                                    : (isDark
                                        ? const Color(0xFF263229)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFEA4335)
                                      : Colors.grey.shade400,
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                point['distanceStr'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF3C4043)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Authentic Google Maps Red Teardrop Pin
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: isSelected ? 34 : 28,
                                  color: isSelected
                                      ? const Color(0xFFEA4335)
                                      : const Color(0xFFD93025),
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: isSelected ? 6 : 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.recycling,
                                      size: isSelected ? 12 : 10,
                                      color: const Color(0xFF0D6938),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Google Maps Watermark Logo in Bottom-Left Corner
          Positioned(
            bottom: 6,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'o',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'o',
                    style: TextStyle(
                      color: Color(0xFFFBBC05),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'g',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'l',
                    style: TextStyle(
                      color: Color(0xFF34A853),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'e',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Google Maps Scale Bar in Bottom-Right Corner
          Positioned(
            bottom: 6,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '200 m ───',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F6368),
                ),
              ),
            ),
          ),

          // Floating Map Controls (Zoom In, Zoom Out, Center)
          Positioned(
            top: 10,
            right: 12,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () {
                    setState(() {
                      _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.5);
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    setState(() {
                      _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.5);
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.my_location,
                  tooltip: 'Pusatkan Peta',
                  onTap: _resetMapCamera,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.map_outlined,
                  tooltip: 'Buka di Google Maps',
                  onTap: () {
                    LocationService.instance.openGoogleMapsAtUserLocation(
                      context: context,
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Bottom Left: Active Points Count Badge
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF263229) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D6938),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${points.length} Drop Point Aktif (GPS Terdekat)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0D6938),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF263229) : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildThemePill({
    required String label,
    required MapThemeStyle theme,
    required bool isDark,
  }) {
    final isSelected = _currentTheme == theme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentTheme = theme;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6938)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // --- DROP POINT CARD WIDGET ---
  Widget _buildDropPointCard(
    BuildContext context,
    Map<String, dynamic> point,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    final categories = point['categories'] as List<String>;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPointIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D6938)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0D6938).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Distance & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            point['hours'] as String,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me,
                          size: 11, color: Color(0xFF0D6938)),
                      const SizedBox(width: 4),
                      Text(
                        point['distanceStr'] as String,
                        style: const TextStyle(
                          color: Color(0xFF0D6938),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    point['address'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Live ETA Travel Time Badges
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF263229)
                        : const Color(0xFFF0F4F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car,
                          size: 12, color: Color(0xFF0D6938)),
                      const SizedBox(width: 4),
                      Text(
                        'Mobil: ${point['drivingEta']}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF263229)
                        : const Color(0xFFF0F4F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_walk,
                          size: 12, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        'Jalan Kaki: ${point['walkingEta']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: categories.map((cat) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF263229)
                        : const Color(0xFFF4F8F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Action Buttons (Navigasi & Pilih Lokasi)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final double destLat = (point['lat'] as num).toDouble();
                      final double destLng = (point['lng'] as num).toDouble();
                      final String name = point['name'] as String;

                      LocationService.instance.openDirectionsTo(
                        destLat: destLat,
                        destLng: destLng,
                        destName: name,
                        context: context,
                      );
                    },
                    icon: const Icon(Icons.directions,
                        size: 16, color: Color(0xFF0D6938)),
                    label: const Text(
                      'Navigasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DepositBerlangsung(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'Pilih Lokasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM MAP VECTOR PAINTER WITH 3D BUILDINGS & MULTI-THEMES ---
class _ModernMapPainter extends CustomPainter {
  final bool isDark;
  final MapThemeStyle theme;
  final double zoom;
  final Offset offset;
  final Map<String, dynamic>? selectedPoint;

  _ModernMapPainter({
    required this.isDark,
    required this.theme,
    required this.zoom,
    required this.offset,
    this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double ox = offset.dx;
    final double oy = offset.dy;

    // 1. Background Fill (Base Land Terrain)
    final Color landColor;
    switch (theme) {
      case MapThemeStyle.satellite:
        landColor = const Color(0xFF14211A);
        break;
      case MapThemeStyle.vectorEco:
        landColor = const Color(0xFF0F1A14);
        break;
      case MapThemeStyle.googleStandard:
        landColor = isDark ? const Color(0xFF21262D) : const Color(0xFFEDE8DC);
        break;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = landColor,
    );

    // 2. City Blocks & 3D Building Footprints
    _drawCityBuildingBlocks(canvas, size, ox, oy);

    // 3. Green Nature Parks & Botanical Gardens
    _drawGreenParks(canvas, size, ox, oy);

    // 4. Curved River Waterway with Bridges
    _drawWaterCanalWithBridges(canvas, size, ox, oy);

    // 5. City Street Grid & Highway Roundabout
    _drawRoadNetworks(canvas, size, ox, oy);

    // 6. Navigation Route Line to Selected Drop Point
    if (selectedPoint != null) {
      _drawNavigationRoute(canvas, size, ox, oy);
    }

    // 7. Dynamic Street Name Badges & Landmarks
    _drawLandmarksAndLabels(canvas, size, ox, oy);
  }

  void _drawCityBuildingBlocks(Canvas canvas, Size size, double ox, double oy) {
    final Color blockColor;
    final Color roofColor;
    final Color shadowColor = Colors.black.withValues(alpha: isDark ? 0.25 : 0.06);

    switch (theme) {
      case MapThemeStyle.satellite:
        blockColor = const Color(0xFF223028);
        roofColor = const Color(0xFF2A3C32);
        break;
      case MapThemeStyle.vectorEco:
        blockColor = const Color(0xFF16251D);
        roofColor = const Color(0xFF1E3529);
        break;
      case MapThemeStyle.googleStandard:
        blockColor = isDark ? const Color(0xFF2D333B) : const Color(0xFFE2DDD2);
        roofColor = isDark ? const Color(0xFF373E47) : const Color(0xFFF3EFE6);
        break;
    }

    final buildings = [
      // Cluster 1 (Top Left)
      Rect.fromLTWH((size.width * 0.06) + ox, (size.height * 0.40) + oy, 38 * zoom, 28 * zoom),
      Rect.fromLTWH((size.width * 0.18) + ox, (size.height * 0.42) + oy, 44 * zoom, 32 * zoom),
      Rect.fromLTWH((size.width * 0.10) + ox, (size.height * 0.52) + oy, 32 * zoom, 24 * zoom),
      // Cluster 2 (Center Top)
      Rect.fromLTWH((size.width * 0.40) + ox, (size.height * 0.08) + oy, 50 * zoom, 35 * zoom),
      Rect.fromLTWH((size.width * 0.55) + ox, (size.height * 0.06) + oy, 36 * zoom, 40 * zoom),
      // Cluster 3 (Right Center)
      Rect.fromLTWH((size.width * 0.72) + ox, (size.height * 0.32) + oy, 48 * zoom, 30 * zoom),
      Rect.fromLTWH((size.width * 0.85) + ox, (size.height * 0.36) + oy, 35 * zoom, 38 * zoom),
      // Cluster 4 (Bottom Left)
      Rect.fromLTWH((size.width * 0.12) + ox, (size.height * 0.72) + oy, 42 * zoom, 30 * zoom),
      Rect.fromLTWH((size.width * 0.25) + ox, (size.height * 0.76) + oy, 36 * zoom, 26 * zoom),
    ];

    for (final rect in buildings) {
      // Drop Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(2 * zoom, 3 * zoom),
          Radius.circular(4 * zoom),
        ),
        Paint()..color = shadowColor,
      );

      // Building Base Wall
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4 * zoom)),
        Paint()..color = blockColor,
      );

      // 3D Roof Top
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(0, -2 * zoom),
          Radius.circular(3 * zoom),
        ),
        Paint()..color = roofColor,
      );
    }
  }

  void _drawGreenParks(Canvas canvas, Size size, double ox, double oy) {
    final Color parkColor;
    final Color treeColor;

    switch (theme) {
      case MapThemeStyle.satellite:
        parkColor = const Color(0xFF1E3624);
        treeColor = const Color(0xFF2E4D34);
        break;
      case MapThemeStyle.vectorEco:
        parkColor = const Color(0xFF1B3322);
        treeColor = const Color(0xFF264C33);
        break;
      case MapThemeStyle.googleStandard:
        parkColor = isDark ? const Color(0xFF233628) : const Color(0xFFD2E8D4);
        treeColor = isDark ? const Color(0xFF2D4534) : const Color(0xFFB5DBB8);
        break;
    }

    final parkPaint = Paint()
      ..color = parkPaintColor(parkColor)
      ..style = PaintingStyle.fill;

    // Park 1 (Top Left Botanical Garden)
    final park1 = Path()
      ..moveTo((size.width * 0.04) + ox, (size.height * 0.08) + oy)
      ..lineTo((size.width * 0.32) + ox, (size.height * 0.06) + oy)
      ..lineTo((size.width * 0.28) + ox, (size.height * 0.32) + oy)
      ..lineTo((size.width * 0.02) + ox, (size.height * 0.28) + oy)
      ..close();
    canvas.drawPath(park1, parkPaint);

    // Park 2 (Bottom Right City Forest)
    final park2 = Path()
      ..moveTo((size.width * 0.62) + ox, (size.height * 0.60) + oy)
      ..lineTo((size.width * 0.96) + ox, (size.height * 0.54) + oy)
      ..lineTo((size.width * 0.98) + ox, (size.height * 0.94) + oy)
      ..lineTo((size.width * 0.66) + ox, (size.height * 0.90) + oy)
      ..close();
    canvas.drawPath(park2, parkPaint);

    // Mini Tree Canopies
    final treePaint = Paint()..color = treeColor;
    final trees = [
      Offset((size.width * 0.12) + ox, (size.height * 0.16) + oy),
      Offset((size.width * 0.20) + ox, (size.height * 0.14) + oy),
      Offset((size.width * 0.15) + ox, (size.height * 0.22) + oy),
      Offset((size.width * 0.75) + ox, (size.height * 0.70) + oy),
      Offset((size.width * 0.84) + ox, (size.height * 0.68) + oy),
      Offset((size.width * 0.78) + ox, (size.height * 0.80) + oy),
    ];

    for (final tree in trees) {
      canvas.drawCircle(tree, 5 * zoom, treePaint);
    }
  }

  Color parkPaintColor(Color color) => color.withValues(alpha: isDark ? 0.75 : 0.85);

  void _drawWaterCanalWithBridges(Canvas canvas, Size size, double ox, double oy) {
    final Color waterColor;
    switch (theme) {
      case MapThemeStyle.satellite:
        waterColor = const Color(0xFF132B3B);
        break;
      case MapThemeStyle.vectorEco:
        waterColor = const Color(0xFF102838);
        break;
      case MapThemeStyle.googleStandard:
        waterColor = isDark ? const Color(0xFF183244) : const Color(0xFFA5CCE5);
        break;
    }

    final riverPath = Path()
      ..moveTo(-40 + ox, (size.height * 0.88) + oy)
      ..quadraticBezierTo(
        (size.width * 0.45) + ox,
        (size.height * 0.52) + oy,
        (size.width + 40) + ox,
        (size.height * 0.12) + oy,
      );

    // Water Shoreline Shadow
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20 * zoom
        ..strokeCap = StrokeCap.round,
    );

    // Water River Main Stream
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = waterColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * zoom
        ..strokeCap = StrokeCap.round,
    );

    // Bridge Crossings
    final bridgePaint = Paint()
      ..color = isDark ? const Color(0xFF333333) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * zoom
      ..strokeCap = StrokeCap.butt;

    final bridge1 = Offset((size.width * 0.45) + ox, (size.height * 0.52) + oy);
    canvas.drawLine(
      bridge1.translate(-8 * zoom, -12 * zoom),
      bridge1.translate(8 * zoom, 12 * zoom),
      bridgePaint,
    );
  }

  void _drawRoadNetworks(Canvas canvas, Size size, double ox, double oy) {
    final Color secondaryColor;
    final Color highwayFill;
    final Color highwayBorder;

    switch (theme) {
      case MapThemeStyle.satellite:
        secondaryColor = Colors.white.withValues(alpha: 0.18);
        highwayFill = const Color(0xFFFFB74D);
        highwayBorder = const Color(0xFF3E2723);
        break;
      case MapThemeStyle.vectorEco:
        secondaryColor = Colors.white.withValues(alpha: 0.12);
        highwayFill = const Color(0xFF00E676);
        highwayBorder = const Color(0xFF0D6938);
        break;
      case MapThemeStyle.googleStandard:
        secondaryColor = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white;
        highwayFill = isDark ? const Color(0xFF4A453A) : const Color(0xFFFFE082);
        highwayBorder = isDark ? const Color(0xFF333028) : const Color(0xFFE8C76A);
        break;
    }

    // Secondary Street Grid
    final streetPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * zoom;

    for (double y = 25; y < size.height + 100; y += 45) {
      canvas.drawLine(
        Offset(-50 + ox, y + oy),
        Offset(size.width + 50 + ox, y + oy),
        streetPaint,
      );
    }
    for (double x = 35; x < size.width + 100; x += 55) {
      canvas.drawLine(
        Offset(x + ox, -50 + oy),
        Offset(x + ox, size.height + 50 + oy),
        streetPaint,
      );
    }

    // Main Arterial Highway 1 (Diagonal Primary)
    final h1 = Path()
      ..moveTo(-30 + ox, (size.height * 0.22) + oy)
      ..lineTo((size.width * 0.50) + ox, (size.height * 0.50) + oy)
      ..lineTo((size.width + 30) + ox, (size.height * 0.80) + oy);

    canvas.drawPath(
      h1,
      Paint()
        ..color = highwayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * zoom
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      h1,
      Paint()
        ..color = highwayFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5 * zoom
        ..strokeCap = StrokeCap.round,
    );

    // Highway 2 (Vertical Highway)
    final h2 = Path()
      ..moveTo((size.width * 0.50) + ox, -30 + oy)
      ..lineTo((size.width * 0.50) + ox, size.height + 30 + oy);

    canvas.drawPath(
      h2,
      Paint()
        ..color = highwayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * zoom
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      h2,
      Paint()
        ..color = highwayFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5 * zoom
        ..strokeCap = StrokeCap.round,
    );

    // Traffic Roundabout at Intersection
    final roundaboutCenter = Offset((size.width * 0.50) + ox, (size.height * 0.50) + oy);
    canvas.drawCircle(
      roundaboutCenter,
      14 * zoom,
      Paint()
        ..color = highwayBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * zoom,
    );
    canvas.drawCircle(
      roundaboutCenter,
      14 * zoom,
      Paint()
        ..color = highwayFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * zoom,
    );

    // Roundabout Center Monument Island
    canvas.drawCircle(
      roundaboutCenter,
      8 * zoom,
      Paint()..color = const Color(0xFF2E7D32),
    );
  }

  void _drawNavigationRoute(Canvas canvas, Size size, double ox, double oy) {
    final userX = (size.width * 0.5) + ox;
    final userY = (size.height * 0.5) + oy;
    final targetX = (size.width * (selectedPoint!['mapX'] as double)) + ox;
    final targetY = (size.height * (selectedPoint!['mapY'] as double)) + oy;

    final routePath = Path()
      ..moveTo(userX, userY)
      ..quadraticBezierTo(
        (userX + targetX) / 2 + 20,
        (userY + targetY) / 2 - 15,
        targetX,
        targetY,
      );

    // Outer Glow
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * zoom
        ..strokeCap = StrokeCap.round,
    );

    // Inner Route Polyline
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFF0D6938)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * zoom
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawLandmarksAndLabels(Canvas canvas, Size size, double ox, double oy) {
    _drawStreetBadge(
      canvas: canvas,
      text: 'Jl. Jend. Sudirman (Arteri)',
      position: Offset((size.width * 0.28) + ox, (size.height * 0.32) + oy),
      isHighway: true,
    );

    _drawStreetBadge(
      canvas: canvas,
      text: 'Bundaran HI',
      position: Offset((size.width * 0.50) + ox, (size.height * 0.44) + oy),
      isHighway: true,
    );

    _drawStreetBadge(
      canvas: canvas,
      text: 'Jl. Kebon Kacang Raya',
      position: Offset((size.width * 0.68) + ox, (size.height * 0.64) + oy),
      isHighway: false,
    );
  }

  void _drawStreetBadge({
    required Canvas canvas,
    required String text,
    required Offset position,
    bool isHighway = false,
  }) {
    final textStyle = TextStyle(
      fontSize: isHighway ? 8.5 : 8.0,
      fontWeight: isHighway ? FontWeight.bold : FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 10;
    final badgeHeight = textPainter.height + 4;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(5),
    );

    final badgeBg = isHighway
        ? (isDark ? const Color(0xFF3E3E3E) : const Color(0xFFFFF3CD))
        : (isDark ? const Color(0xFF263229) : Colors.white.withValues(alpha: 0.92));

    canvas.drawRRect(badgeRect, Paint()..color = badgeBg);
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = isDark ? Colors.white24 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - (textPainter.width / 2),
        position.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ModernMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.theme != theme ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}
