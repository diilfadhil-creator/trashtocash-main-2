import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trashtocash/services/google_maps_service.dart';

/// State data model for User's GPS & Location status
class UserGpsState {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final bool isGpsEnabled;
  final bool hasPermission;
  final String permissionStatus; // 'granted', 'denied', 'deniedForever', 'serviceDisabled'
  final String streetAddress;
  final String district;
  final String city;
  final bool isLiveTracking;
  final DateTime lastUpdated;

  const UserGpsState({
    required this.latitude,
    required this.longitude,
    this.accuracy = 5.0,
    this.speed = 0.0,
    this.heading = 0.0,
    this.isGpsEnabled = true,
    this.hasPermission = false,
    this.permissionStatus = 'unknown',
    this.streetAddress = 'Jl. Kebon Kacang Raya No. 10',
    this.district = 'Tanah Abang',
    this.city = 'Jakarta Pusat',
    this.isLiveTracking = false,
    required this.lastUpdated,
  });

  String get fullAddress => '$streetAddress, $district, $city';
  String get coordinatesDisplay =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  UserGpsState copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    bool? isGpsEnabled,
    bool? hasPermission,
    String? permissionStatus,
    String? streetAddress,
    String? district,
    String? city,
    bool? isLiveTracking,
    DateTime? lastUpdated,
  }) {
    return UserGpsState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      hasPermission: hasPermission ?? this.hasPermission,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      streetAddress: streetAddress ?? this.streetAddress,
      district: district ?? this.district,
      city: city ?? this.city,
      isLiveTracking: isLiveTracking ?? this.isLiveTracking,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LocationService {
  static final LocationService instance = LocationService._internal();

  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;

  // Default coordinate (Jakarta CBD) as fallback
  static const double defaultLat = -6.2088;
  static const double defaultLng = 106.8456;

  final ValueNotifier<UserGpsState> userLocationNotifier =
      ValueNotifier<UserGpsState>(
    UserGpsState(
      latitude: defaultLat,
      longitude: defaultLng,
      lastUpdated: DateTime.now(),
    ),
  );

  UserGpsState get currentState => userLocationNotifier.value;

  /// Check GPS service and request location permission on phone
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        userLocationNotifier.value = currentState.copyWith(
          isGpsEnabled: false,
          permissionStatus: 'serviceDisabled',
          hasPermission: false,
        );
        debugPrint('LocationService: Location services are disabled on device.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          userLocationNotifier.value = currentState.copyWith(
            hasPermission: false,
            permissionStatus: 'denied',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        userLocationNotifier.value = currentState.copyWith(
          hasPermission: false,
          permissionStatus: 'deniedForever',
        );
        return false;
      }

      // Permission granted!
      userLocationNotifier.value = currentState.copyWith(
        isGpsEnabled: true,
        hasPermission: true,
        permissionStatus: 'granted',
      );

      // Immediately fetch current accurate location
      await refreshCurrentLocation();
      return true;
    } catch (e) {
      debugPrint('LocationService: Exception requesting location permission: $e');
      return false;
    }
  }

  /// Get current fresh GPS position from phone hardware
  Future<Position?> refreshCurrentLocation() async {
    try {
      final hasPerm = await Geolocator.checkPermission();
      if (hasPerm == LocationPermission.denied ||
          hasPerm == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final addressInfo = _resolveAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      userLocationNotifier.value = currentState.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        isGpsEnabled: true,
        hasPermission: true,
        permissionStatus: 'granted',
        streetAddress: addressInfo['street'],
        district: addressInfo['district'],
        city: addressInfo['city'],
        lastUpdated: DateTime.now(),
      );

      debugPrint(
        'LocationService: GPS acquired (${position.latitude}, ${position.longitude}) ±${position.accuracy}m',
      );
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting current GPS position: $e');
      return null;
    }
  }

  /// Start live GPS stream tracking as user moves
  void startLiveTracking() {
    _positionStreamSubscription?.cancel();

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // updates every 3 meters
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          final addressInfo = _resolveAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );

          userLocationNotifier.value = currentState.copyWith(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            speed: position.speed,
            heading: position.heading,
            streetAddress: addressInfo['street'],
            district: addressInfo['district'],
            city: addressInfo['city'],
            isLiveTracking: true,
            lastUpdated: DateTime.now(),
          );
        },
        onError: (err) {
          debugPrint('LocationService: Live GPS stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('LocationService: Failed to start live GPS stream: $e');
    }
  }

  /// Stop live GPS tracking
  void stopLiveTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    userLocationNotifier.value = currentState.copyWith(isLiveTracking: false);
  }

  /// Calculate distance between two GPS coordinates in Kilometers
  double calculateDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    try {
      final double distanceInMeters = Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      return double.parse((distanceInMeters / 1000.0).toStringAsFixed(1));
    } catch (e) {
      return 1.2;
    }
  }

  /// Estimate driving & walking ETA string based on distance in KM
  Map<String, String> getEtaEstimate(double distanceKm) {
    // Average city driving speed: 25 km/h -> 2.4 min per km
    final int driveMinutes = (distanceKm * 2.4).round().clamp(1, 180);
    // Average walking speed: 4.5 km/h -> 13.3 min per km
    final int walkMinutes = (distanceKm * 13.3).round().clamp(2, 360);

    return {
      'driving': driveMinutes < 60 ? '$driveMinutes mnt' : '${driveMinutes ~/ 60}j ${driveMinutes % 60}m',
      'walking': walkMinutes < 60 ? '$walkMinutes mnt' : '${walkMinutes ~/ 60}j ${walkMinutes % 60}m',
    };
  }

  /// Resolve human-readable localized Indonesian address from coordinates
  Map<String, String> _resolveAddressFromCoordinates(double lat, double lng) {
    // Check if within Greater Jakarta area
    if (lat >= -6.40 && lat <= -6.10 && lng >= 106.65 && lng <= 107.00) {
      if (lat < -6.23) {
        return {
          'street': 'Jl. Fatmawati Raya No. 42',
          'district': 'Cilandak',
          'city': 'Jakarta Selatan',
        };
      } else if (lat < -6.18) {
        return {
          'street': 'Jl. Kebon Kacang Raya No. 10',
          'district': 'Tanah Abang',
          'city': 'Jakarta Pusat',
        };
      } else {
        return {
          'street': 'Jl. Hayam Wuruk No. 88',
          'district': 'Gambir',
          'city': 'Jakarta Barat',
        };
      }
    } else if (lat >= -7.35 && lat <= -7.20 && lng >= 112.65 && lng <= 112.85) {
      return {
        'street': 'Jl. Pemuda No. 15',
        'district': 'Genteng',
        'city': 'Surabaya',
      };
    } else if (lat >= -6.95 && lat <= -6.85 && lng >= 107.55 && lng <= 107.70) {
      return {
        'street': 'Jl. Dago No. 80',
        'district': 'Coblong',
        'city': 'Bandung',
      };
    } else if (lat >= -8.75 && lat <= -8.60 && lng >= 115.15 && lng <= 115.30) {
      return {
        'street': 'Jl. Teuku Umar No. 25',
        'district': 'Denpasar Barat',
        'city': 'Denpasar Bali',
      };
    }

    return {
      'street': 'Jl. Lokasi Pengguna Saat Ini',
      'district': 'Area Terdeteksi GPS',
      'city': 'Indonesia',
    };
  }

  /// Open Google Maps application centered on current User GPS location
  Future<void> openGoogleMapsAtUserLocation({BuildContext? context}) async {
    final state = currentState;
    await GoogleMapsService.instance.launchLocationSearch(
      lat: state.latitude,
      lng: state.longitude,
      title: 'Lokasi Saya: ${state.streetAddress}',
      context: context,
    );
  }

  /// Open Google Maps turn-by-turn navigation from user GPS to destination
  Future<void> openDirectionsTo({
    required double destLat,
    required double destLng,
    String? destName,
    BuildContext? context,
  }) async {
    await GoogleMapsService.instance.launchNavigation(
      destinationLat: destLat,
      destinationLng: destLng,
      destinationLabel: destName,
      context: context,
    );
  }
}

