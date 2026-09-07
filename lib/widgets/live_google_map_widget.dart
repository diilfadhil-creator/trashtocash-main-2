import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtocash/services/driver_api_service.dart';
import 'package:trashtocash/services/google_maps_service.dart';
import 'package:trashtocash/services/location_service.dart';

enum MapPerspective { customer, driver }

enum GoogleMapDisplayMode {
  vectorInteractive,
  googleMapsNormal,
  googleMapsSatellite,
  googleMapsTerrain,
}

class LiveGoogleMapWidget extends StatefulWidget {
  final MapPerspective perspective;
  final String? customerName;
  final String? customerAddress;
  final double customerLat;
  final double customerLng;
  final String driverName;
  final String driverPlate;
  final double height;
  final bool showNavigationBanner;
  final bool isArrived;

  const LiveGoogleMapWidget({
    super.key,
    this.perspective = MapPerspective.customer,
    this.customerName = 'Siti Rahmawati',
    this.customerAddress = 'Jl. Kebon Kacang Raya No. 10, Jakarta Pusat',
    this.customerLat = -6.2088,
    this.customerLng = 106.8456,
    this.driverName = 'Budi Santoso',
    this.driverPlate = 'B 1234 XYZ',
    this.height = 360,
    this.showNavigationBanner = true,
    this.isArrived = false,
  });

  @override
  State<LiveGoogleMapWidget> createState() => _LiveGoogleMapWidgetState();
}

class _LiveGoogleMapWidgetState extends State<LiveGoogleMapWidget>
    with TickerProviderStateMixin {
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;
  bool _autoFollowDriver = true;
  GoogleMapDisplayMode _displayMode = GoogleMapDisplayMode.vectorInteractive;
  GoogleMapController? _googleMapController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeAnimController;

  // Coordinates
  late LatLng _customerLatLng;

  @override
  void initState() {
    super.initState();
    _customerLatLng = LatLng(widget.customerLat, widget.customerLng);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Hook driver location listener for camera tracking
    DriverApiService.instance.driverLocationNotifier.addListener(_onDriverMoved);
  }

  @override
  void dispose() {
    DriverApiService.instance.driverLocationNotifier
        .removeListener(_onDriverMoved);
    _pulseController.dispose();
    _routeAnimController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _onDriverMoved() {
    if (!_autoFollowDriver || !mounted) return;
    final loc = DriverApiService.instance.driverLocationNotifier.value;
    if (_googleMapController != null) {
      final target = LatLng(loc.latitude, loc.longitude);
      _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 16.5,
            tilt: 35.0,
            bearing: loc.headingDegrees,
          ),
        ),
      );
    }
  }

  void _recenterOnDriver() {
    HapticFeedback.mediumImpact();
    setState(() {
      _autoFollowDriver = true;
      _zoomLevel = 1.0;
      _mapOffset = Offset.zero;
    });

    final loc = DriverApiService.instance.driverLocationNotifier.value;
    if (_googleMapController != null) {
      _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(loc.latitude, loc.longitude),
            zoom: 16.0,
            tilt: 30.0,
            bearing: loc.headingDegrees,
          ),
        ),
      );
    }
  }

  void _cycleMapMode() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_displayMode) {
        case GoogleMapDisplayMode.vectorInteractive:
          _displayMode = GoogleMapDisplayMode.googleMapsNormal;
          break;
        case GoogleMapDisplayMode.googleMapsNormal:
          _displayMode = GoogleMapDisplayMode.googleMapsSatellite;
          break;
        case GoogleMapDisplayMode.googleMapsSatellite:
          _displayMode = GoogleMapDisplayMode.googleMapsTerrain;
          break;
        case GoogleMapDisplayMode.googleMapsTerrain:
          _displayMode = GoogleMapDisplayMode.vectorInteractive;
          break;
      }
    });
  }

  String get _displayModeLabel {
    switch (_displayMode) {
      case GoogleMapDisplayMode.vectorInteractive:
        return 'Peta Vektor HUD';
      case GoogleMapDisplayMode.googleMapsNormal:
        return 'Google Maps Standar';
      case GoogleMapDisplayMode.googleMapsSatellite:
        return 'Google Maps Satelit';
      case GoogleMapDisplayMode.googleMapsTerrain:
        return 'Google Maps Medan';
    }
  }

  MapType get _googleMapType {
    switch (_displayMode) {
      case GoogleMapDisplayMode.googleMapsSatellite:
        return MapType.satellite;
      case GoogleMapDisplayMode.googleMapsTerrain:
        return MapType.terrain;
      default:
        return MapType.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<UserGpsState>(
      valueListenable: LocationService.instance.userLocationNotifier,
      builder: (context, userGps, _) {
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF0D6938).withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              children: [
                // 1. Map Layer: Native Google Maps or Vector HUD
                if (_displayMode != GoogleMapDisplayMode.vectorInteractive &&
                    !kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS))
                  _buildNativeGoogleMap(isSystemDark, userGps)
                else
                  _buildVectorInteractiveMap(isSystemDark, userGps),

                // 2. Real-Time Moving Entities & HUD Overlay (for Vector HUD mode)
                if (_displayMode == GoogleMapDisplayMode.vectorInteractive)
                  _buildVectorHudOverlay(userGps),

                // 3. Top Dynamic Street Name & Live Navigation Header
                if (widget.showNavigationBanner)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: ValueListenableBuilder<RemoteDriverLocation>(
                      valueListenable:
                          DriverApiService.instance.driverLocationNotifier,
                      builder: (context, loc, _) {
                        final double effectiveProgress =
                            widget.isArrived ? 1.0 : loc.progress.clamp(0.0, 1.0);
                        final double remainingKm = widget.isArrived
                            ? 0.0
                            : double.parse(
                                (1.2 * (1.0 - effectiveProgress))
                                    .toStringAsFixed(1),
                              );
                        final int etaMin =
                            (remainingKm * 3.5).ceil().clamp(1, 15);

                        return _buildGoogleNavigationBanner(
                          userGps: userGps,
                          remainingKm: remainingKm,
                          etaMin: etaMin,
                          isArrived: widget.isArrived,
                        );
                      },
                    ),
                  ),

                // 4. Auto-Follow Driver Status Badge (Top Left Under Banner)
                Positioned(
                  top: widget.showNavigationBanner ? 80 : 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: _recenterOnDriver,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _autoFollowDriver
                            ? const Color(0xFF0D6938)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _autoFollowDriver
                              ? const Color(0xFF00E676)
                              : Colors.grey.shade400,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _autoFollowDriver
                                  ? const Color(0xFF00E676)
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _autoFollowDriver
                                ? 'Kamera: Ikuti Driver 🛵'
                                : 'Pusatkan ke Driver 🎯',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _autoFollowDriver
                                  ? Colors.white
                                  : const Color(0xFF0D6938),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Compass Dial (Top Right Under Banner)
                Positioned(
                  top: widget.showNavigationBanner ? 80 : 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🧭 N',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Floating Google Maps Control Tools (Right Side)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFloatingBtn(
                        icon: Icons.layers_outlined,
                        tooltip: 'Ganti Mode: $_displayModeLabel',
                        onTap: _cycleMapMode,
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingBtn(
                        icon: Icons.add,
                        tooltip: 'Perbesar',
                        onTap: () {
                          setState(() {
                            _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.5);
                          });
                          _googleMapController?.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingBtn(
                        icon: Icons.remove,
                        tooltip: 'Perkecil',
                        onTap: () {
                          setState(() {
                            _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.5);
                          });
                          _googleMapController?.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingBtn(
                        icon: _autoFollowDriver
                            ? Icons.gps_fixed
                            : Icons.my_location,
                        tooltip: 'Pusatkan ke Driver',
                        onTap: _recenterOnDriver,
                      ),
                    ],
                  ),
                ),

                // 7. "Buka di Google Maps 🗺️" Bottom Left Pill
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        GoogleMapsService.instance.launchNavigation(
                          destinationLat: widget.customerLat,
                          destinationLng: widget.customerLng,
                          destinationLabel: widget.customerName,
                          context: context,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4285F4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Google_Maps_icon_%282020%29.svg/100px-Google_Maps_icon_%282020%29.svg.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.map,
                                color: Color(0xFF4285F4),
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Buka di Google Maps',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Color(0xFF1A73E8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NATIVE GOOGLE MAPS FLUTTER WIDGET ---
  Widget _buildNativeGoogleMap(bool isDark, UserGpsState userGps) {
    return ValueListenableBuilder<RemoteDriverLocation>(
      valueListenable: DriverApiService.instance.driverLocationNotifier,
      builder: (context, loc, _) {
        final LatLng currentDriverLatLng = LatLng(loc.latitude, loc.longitude);

        final routePoints = GoogleMapsService.instance.generateRoutePoints(
          currentDriverLatLng,
          _customerLatLng,
        );

        final Set<Marker> markers = {
          Marker(
            markerId: const MarkerId('customer_location'),
            position: _customerLatLng,
            infoWindow: InfoWindow(
              title: widget.customerName ?? 'Lokasi Penjemputan',
              snippet: widget.customerAddress ?? userGps.fullAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
          Marker(
            markerId: const MarkerId('driver_courier'),
            position: currentDriverLatLng,
            rotation: loc.headingDegrees,
            infoWindow: InfoWindow(
              title: '${widget.driverName} (${widget.driverPlate})',
              snippet:
                  'Di: ${userGps.streetAddress} • ${loc.speedKmph.toStringAsFixed(0)} km/j',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        };

        final Set<Polyline> polylines = {
          Polyline(
            polylineId: const PolylineId('driver_to_customer_route'),
            points: routePoints,
            color: const Color(0xFF1A73E8),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: currentDriverLatLng,
            zoom: 16.0,
            tilt: 35.0,
            bearing: loc.headingDegrees,
          ),
          mapType: _googleMapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          zoomControlsEnabled: false,
          trafficEnabled: true,
          markers: markers,
          polylines: polylines,
          onCameraMove: (_) {
            if (_autoFollowDriver) {
              // User panned manually
            }
          },
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
        );
      },
    );
  }

  // --- VECTOR INTERACTIVE MAP ENGINE WITH DYNAMIC LIVE ROAD MOVEMENT ---
  Widget _buildVectorInteractiveMap(bool isDark, UserGpsState userGps) {
    return ValueListenableBuilder<RemoteDriverLocation>(
      valueListenable: DriverApiService.instance.driverLocationNotifier,
      builder: (context, loc, _) {
        final double progress =
            widget.isArrived ? 1.0 : loc.progress.clamp(0.0, 1.0);

        return Positioned.fill(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _autoFollowDriver = false;
                _mapOffset += details.delta;
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _GoogleMapCanvasPainter(
                isDark: isDark,
                isSatellite:
                    _displayMode == GoogleMapDisplayMode.googleMapsSatellite,
                zoom: _zoomLevel,
                offset: _mapOffset,
                driverProgress: progress,
                autoFollow: _autoFollowDriver,
                routeAnimValue: _routeAnimController.value,
                driverStreet: userGps.streetAddress,
                districtName: userGps.district,
                cityName: userGps.city,
                customerStreet:
                    widget.customerAddress ?? 'Jl. Lokasi Penjemputan',
              ),
            ),
          ),
        );
      },
    );
  }

  // --- REAL-TIME VECTOR HUD OVERLAY ---
  Widget _buildVectorHudOverlay(UserGpsState userGps) {
    return ValueListenableBuilder<RemoteDriverLocation>(
      valueListenable: DriverApiService.instance.driverLocationNotifier,
      builder: (context, loc, _) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            final double effectiveProgress =
                widget.isArrived ? 1.0 : loc.progress.clamp(0.0, 1.0);

            // Dynamic coordinates: When autoFollow is true, viewport camera pans with driver
            final double baseStartX = w * 0.22;
            final double baseStartY = h * 0.70;
            final double baseTargetX = w * 0.78;
            final double baseTargetY = h * 0.38;

            final double currentDriverX =
                baseStartX + (baseTargetX - baseStartX) * effectiveProgress;
            final double currentDriverY =
                baseStartY + (baseTargetY - baseStartY) * effectiveProgress -
                    (sin(effectiveProgress * pi) * 38.0);

            // If auto-following, center the driver scooter dynamically
            final double cameraShiftX = _autoFollowDriver
                ? ((w * 0.45) - currentDriverX) * 0.6
                : 0.0;
            final double cameraShiftY = _autoFollowDriver
                ? ((h * 0.65) - currentDriverY) * 0.6
                : 0.0;

            final double finalDriverX =
                currentDriverX + _mapOffset.dx + cameraShiftX;
            final double finalDriverY =
                currentDriverY + _mapOffset.dy + cameraShiftY;

            final double finalStartX =
                baseStartX + _mapOffset.dx + cameraShiftX;
            final double finalStartY =
                baseStartY + _mapOffset.dy + cameraShiftY;

            final double finalTargetX =
                baseTargetX + _mapOffset.dx + cameraShiftX;
            final double finalTargetY =
                baseTargetY + _mapOffset.dy + cameraShiftY;

            // Bearing in degrees
            final double angleRadians = atan2(
              finalTargetY - finalStartY,
              finalTargetX - finalStartX,
            );

            return Stack(
              children: [
                // Dynamic Route Polyline
                CustomPaint(
                  size: Size(w, h),
                  painter: _LiveRoutePainter(
                    startX: finalStartX,
                    startY: finalStartY,
                    currentX: finalDriverX,
                    currentY: finalDriverY,
                    targetX: finalTargetX,
                    targetY: finalTargetY,
                    isArrived: widget.isArrived,
                    zoom: _zoomLevel,
                  ),
                ),

                // Customer Red Google Maps Pin with Address Tag
                Positioned(
                  left: finalTargetX - 22,
                  top: finalTargetY - 46,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE53935),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              color: Color(0xFFE53935),
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.perspective == MapPerspective.driver
                                  ? 'Lokasi Jemput Warga'
                                  : 'Lokasi Anda',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE53935),
                        size: 32,
                      ),
                    ],
                  ),
                ),

                // Driver Moving Scooter Marker with Live Street Tag & Glowing Headlight
                Positioned(
                  left: finalDriverX - 28,
                  top: finalDriverY - 42,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6938),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isArrived
                                  ? '🛵 Kurir Tiba!'
                                  : '${widget.driverName} • ${loc.speedKmph.toStringAsFixed(0)} km/j',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radar Pulse Beacon
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          // Scooter Body with Orientation Angle
                          Transform.rotate(
                            angle: angleRadians + (pi / 2),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6938),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.navigation_rounded,
                                  color: Color(0xFF00E676),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGoogleNavigationBanner({
    required UserGpsState userGps,
    required double remainingKm,
    required int etaMin,
    required bool isArrived,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D6938),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isArrived ? Icons.check_circle : Icons.turn_right_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArrived
                          ? 'Kurir Telah Tiba di Lokasi'
                          : 'Dalam 250m Belok Kanan ke ${userGps.streetAddress}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArrived
                          ? 'Silakan serahkan sampah & konfirmasi PIN'
                          : 'Sisa $remainingKm km • Tiba dlm $etaMin mnt (GPS ±${userGps.accuracy.toStringAsFixed(0)}m)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isArrived ? 'TIBA' : '$etaMin mnt',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
      ),
    );
  }
}

/// Custom Google Maps Canvas Painter with Real-Time Moving Roads & Dynamic Badges
class _GoogleMapCanvasPainter extends CustomPainter {
  final bool isDark;
  final bool isSatellite;
  final double zoom;
  final Offset offset;
  final double driverProgress;
  final bool autoFollow;
  final double routeAnimValue;
  final String driverStreet;
  final String districtName;
  final String cityName;
  final String customerStreet;

  _GoogleMapCanvasPainter({
    required this.isDark,
    required this.isSatellite,
    required this.zoom,
    required this.offset,
    required this.driverProgress,
    required this.autoFollow,
    required this.routeAnimValue,
    required this.driverStreet,
    required this.districtName,
    required this.cityName,
    required this.customerStreet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic road shift as driver moves
    final double flowShiftX =
        autoFollow ? (driverProgress * -40.0) + offset.dx : offset.dx;
    final double flowShiftY =
        autoFollow ? (driverProgress * 25.0) + offset.dy : offset.dy;

    // 1. Terrain Land Fill
    final Color terrainColor;
    if (isSatellite) {
      terrainColor = const Color(0xFF233529);
    } else if (isDark) {
      terrainColor = const Color(0xFF21262D);
    } else {
      terrainColor = const Color(0xFFEDE8DC);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = terrainColor,
    );

    // 2. City Blocks & Parks
    final parkColor = isSatellite
        ? const Color(0xFF18281D)
        : (isDark ? const Color(0xFF233628) : const Color(0xFFC8E6C9));

    final parkPaint = Paint()
      ..color = parkColor.withValues(alpha: isSatellite ? 0.9 : 0.75)
      ..style = PaintingStyle.fill;

    // Park 1 (Top Left)
    final parkPath1 = Path()
      ..moveTo(
          (size.width * 0.05) + flowShiftX, (size.height * 0.15) + flowShiftY)
      ..lineTo(
          (size.width * 0.35) + flowShiftX, (size.height * 0.10) + flowShiftY)
      ..lineTo(
          (size.width * 0.30) + flowShiftX, (size.height * 0.38) + flowShiftY)
      ..lineTo(
          (size.width * 0.02) + flowShiftX, (size.height * 0.32) + flowShiftY)
      ..close();
    canvas.drawPath(parkPath1, parkPaint);

    // Park 2 (Bottom Right)
    final parkPath2 = Path()
      ..moveTo(
          (size.width * 0.60) + flowShiftX, (size.height * 0.60) + flowShiftY)
      ..lineTo(
          (size.width * 0.95) + flowShiftX, (size.height * 0.55) + flowShiftY)
      ..lineTo(
          (size.width * 0.92) + flowShiftX, (size.height * 0.92) + flowShiftY)
      ..lineTo(
          (size.width * 0.65) + flowShiftX, (size.height * 0.88) + flowShiftY)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    // 3. Water River Curve (Google Maps Blue)
    final riverColor = isSatellite
        ? const Color(0xFF152A38)
        : (isDark ? const Color(0xFF183244) : const Color(0xFFA5CCE5));

    final riverPaint = Paint()
      ..color = riverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16 * zoom
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-30 + flowShiftX, (size.height * 0.90) + flowShiftY)
      ..quadraticBezierTo(
        (size.width * 0.45) + flowShiftX,
        (size.height * 0.55) + flowShiftY,
        (size.width + 30) + flowShiftX,
        (size.height * 0.15) + flowShiftY,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Secondary Grid Streets
    final streetColor = isSatellite
        ? Colors.white.withValues(alpha: 0.18)
        : (isDark ? Colors.white.withValues(alpha: 0.09) : Colors.white);

    final streetPaint = Paint()
      ..color = streetColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * zoom;

    for (double y = 25; y < size.height + 80; y += 48) {
      canvas.drawLine(
        Offset(-50 + flowShiftX, y + flowShiftY),
        Offset(size.width + 50 + flowShiftX, y + flowShiftY),
        streetPaint,
      );
    }
    for (double x = 35; x < size.width + 80; x += 55) {
      canvas.drawLine(
        Offset(x + flowShiftX, -50 + flowShiftY),
        Offset(x + flowShiftX, size.height + 50 + flowShiftY),
        streetPaint,
      );
    }

    // 5. Main Arterial Highways (Yellow Google Maps Road Style)
    final highwayBorder = Paint()
      ..color = isDark ? const Color(0xFF333333) : const Color(0xFFE0C17B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * zoom
      ..strokeCap = StrokeCap.round;

    final highwayFill = Paint()
      ..color = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFFEE180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * zoom
      ..strokeCap = StrokeCap.round;

    // Diagonal Highway 1
    final h1 = Path()
      ..moveTo(-30 + flowShiftX, (size.height * 0.3) + flowShiftY)
      ..lineTo(
          (size.width * 0.55) + flowShiftX, (size.height * 0.52) + flowShiftY)
      ..lineTo((size.width + 30) + flowShiftX, (size.height * 0.78) + flowShiftY);

    canvas.drawPath(h1, highwayBorder);
    canvas.drawPath(h1, highwayFill);

    // Vertical Highway 2
    final h2 = Path()
      ..moveTo((size.width * 0.55) + flowShiftX, -30 + flowShiftY)
      ..lineTo(
          (size.width * 0.55) + flowShiftX, size.height + 30 + flowShiftY);

    canvas.drawPath(h2, highwayBorder);
    canvas.drawPath(h2, highwayFill);

    // 6. REAL-TIME STREET NAMES & ROAD BADGES RENDERING
    // Highway Label 1 (Arteri Utama)
    _drawStreetBadge(
      canvas: canvas,
      text: 'Jl. Jend. Sudirman (Arteri)',
      position: Offset(
        (size.width * 0.26) + flowShiftX,
        (size.height * 0.38) + flowShiftY,
      ),
      isHighway: true,
      isDark: isDark,
    );

    // Highway Label 2 (Arteri Vertikal)
    _drawStreetBadge(
      canvas: canvas,
      text: 'Jl. M.H. Thamrin',
      position: Offset(
        (size.width * 0.55) + flowShiftX,
        (size.height * 0.20) + flowShiftY,
      ),
      isHighway: true,
      isDark: isDark,
    );

    // Driver's Current Street (Dynamically updated from GPS!)
    _drawStreetBadge(
      canvas: canvas,
      text: '📍 $driverStreet',
      position: Offset(
        (size.width * 0.22) + flowShiftX,
        (size.height * 0.76) + flowShiftY,
      ),
      isCurrentStreet: true,
      isDark: isDark,
    );

    // Cross Street 1 (District name)
    _drawStreetBadge(
      canvas: canvas,
      text: 'Jl. $districtName Raya',
      position: Offset(
        (size.width * 0.72) + flowShiftX,
        (size.height * 0.28) + flowShiftY,
      ),
      isHighway: false,
      isDark: isDark,
    );

    // Cross Street 2 (Local neighborhood)
    _drawStreetBadge(
      canvas: canvas,
      text: 'Gg. Melati No. 4',
      position: Offset(
        (size.width * 0.40) + flowShiftX,
        (size.height * 0.85) + flowShiftY,
      ),
      isHighway: false,
      isDark: isDark,
    );

    // POI / Landmark 1 (Park)
    _drawPoiBadge(
      canvas: canvas,
      icon: '🌳',
      name: 'Taman Kota $districtName',
      position: Offset(
        (size.width * 0.16) + flowShiftX,
        (size.height * 0.24) + flowShiftY,
      ),
      isDark: isDark,
    );

    // POI / Landmark 2 (Mall/Pasar)
    _drawPoiBadge(
      canvas: canvas,
      icon: '🏬',
      name: 'Pasar $districtName',
      position: Offset(
        (size.width * 0.78) + flowShiftX,
        (size.height * 0.74) + flowShiftY,
      ),
      isDark: isDark,
    );
  }

  void _drawStreetBadge({
    required Canvas canvas,
    required String text,
    required Offset position,
    bool isHighway = false,
    bool isCurrentStreet = false,
    required bool isDark,
  }) {
    final textStyle = TextStyle(
      fontSize: isCurrentStreet ? 9.5 : (isHighway ? 9.0 : 8.5),
      fontWeight:
          isCurrentStreet || isHighway ? FontWeight.bold : FontWeight.w600,
      color: isCurrentStreet
          ? Colors.white
          : (isDark ? Colors.white : Colors.black87),
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 12;
    final badgeHeight = textPainter.height + 6;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(6),
    );

    final Color badgeBg;
    if (isCurrentStreet) {
      badgeBg = const Color(0xFF0D6938);
    } else if (isHighway) {
      badgeBg = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFFFF3CD);
    } else {
      badgeBg = isDark
          ? const Color(0xFF263229).withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.95);
    }

    // Shadow
    canvas.drawRRect(
      badgeRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // Fill
    canvas.drawRRect(badgeRect, Paint()..color = badgeBg);

    // Border
    final borderColor = isCurrentStreet
        ? const Color(0xFF00E676)
        : (isHighway
            ? const Color(0xFFE0C17B)
            : (isDark ? Colors.white24 : Colors.black12));
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Text Paint
    textPainter.paint(
      canvas,
      Offset(
        position.dx - (textPainter.width / 2),
        position.dy - (textPainter.height / 2),
      ),
    );
  }

  void _drawPoiBadge({
    required Canvas canvas,
    required String icon,
    required String name,
    required Offset position,
    required bool isDark,
  }) {
    final textStyle = TextStyle(
      fontSize: 8.0,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : const Color(0xFF333333),
    );

    final textSpan = TextSpan(text: '$icon $name', style: textStyle);
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

    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = isDark
            ? const Color(0xFF1E2822).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
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
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.isSatellite != isSatellite ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.driverProgress != driverProgress ||
        oldDelegate.autoFollow != autoFollow ||
        oldDelegate.driverStreet != driverStreet ||
        oldDelegate.districtName != districtName ||
        oldDelegate.cityName != cityName ||
        oldDelegate.customerStreet != customerStreet ||
        oldDelegate.routeAnimValue != routeAnimValue;
  }
}

/// Dynamic Live Route Polyline Painter
class _LiveRoutePainter extends CustomPainter {
  final double startX;
  final double startY;
  final double currentX;
  final double currentY;
  final double targetX;
  final double targetY;
  final bool isArrived;
  final double zoom;

  _LiveRoutePainter({
    required this.startX,
    required this.startY,
    required this.currentX,
    required this.currentY,
    required this.targetX,
    required this.targetY,
    required this.isArrived,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final routeGlow = Paint()
      ..color = const Color(0xFF4285F4).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * zoom
      ..strokeCap = StrokeCap.round;

    final routeMain = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * zoom
      ..strokeCap = StrokeCap.round;

    final remainingPath = Path()
      ..moveTo(currentX, currentY)
      ..quadraticBezierTo(
        (currentX + targetX) / 2 + 15,
        (currentY + targetY) / 2 - 20,
        targetX,
        targetY,
      );

    canvas.drawPath(remainingPath, routeGlow);
    canvas.drawPath(remainingPath, routeMain);

    if (!isArrived && (currentX - startX).abs() > 5) {
      final traveledPath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(
          (startX + currentX) / 2 + 10,
          (startY + currentY) / 2 - 15,
          currentX,
          currentY,
        );

      final traveledPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * zoom
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(traveledPath, traveledPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) {
    return oldDelegate.currentX != currentX ||
        oldDelegate.currentY != currentY ||
        oldDelegate.isArrived != isArrived ||
        oldDelegate.zoom != zoom;
  }
}
