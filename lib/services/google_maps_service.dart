import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtocash/helpers/external_driver_launcher.dart';

class GoogleMapsService {
  GoogleMapsService._privateConstructor();
  static final GoogleMapsService instance = GoogleMapsService._privateConstructor();

  // Default Jakarta Central Coordinates
  static const LatLng defaultJakarta = LatLng(-6.2088, 106.8456);

  /// Calculate heading/bearing in degrees (0-360) from point A to point B
  double calculateBearing(LatLng start, LatLng end) {
    final double startLat = _degreesToRadians(start.latitude);
    final double startLng = _degreesToRadians(start.longitude);
    final double endLat = _degreesToRadians(end.latitude);
    final double endLng = _degreesToRadians(end.longitude);

    final double dLng = endLng - startLng;

    final double y = sin(dLng) * cos(endLat);
    final double x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(dLng);

    final double bearingRadians = atan2(y, x);
    final double bearingDegrees = _radiansToDegrees(bearingRadians);

    return (bearingDegrees + 360) % 360;
  }

  /// Interpolate LatLng along progress (0.0 to 1.0)
  LatLng interpolateLatLng(LatLng start, LatLng end, double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    final double lat = start.latitude + (end.latitude - start.latitude) * clamped;
    final double lng = start.longitude + (end.longitude - start.longitude) * clamped;
    return LatLng(lat, lng);
  }

  /// Generate a simulated route polyline points list between driver and customer
  List<LatLng> generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    final double midLat = (start.latitude + end.latitude) / 2;
    final double midLng = (start.longitude + end.longitude) / 2;

    // Slight curve in city grid
    points.add(LatLng(start.latitude, midLng));
    points.add(LatLng(midLat, midLng));
    points.add(LatLng(end.latitude, midLng));
    points.add(end);

    return points;
  }

  /// Open Native Google Maps App for Turn-by-Turn Navigation
  Future<void> launchNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
    BuildContext? context,
  }) async {
    await ExternalDriverLauncher.openGoogleMapsNavigation(
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      destinationLabel: destinationLabel,
      context: context,
    );
  }

  /// Open Google Maps search/pin location
  Future<void> launchLocationSearch({
    required double lat,
    required double lng,
    String? title,
    BuildContext? context,
  }) async {
    await ExternalDriverLauncher.openGoogleMapsLocation(
      lat: lat,
      lng: lng,
      title: title,
      context: context,
    );
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
  double _radiansToDegrees(double radians) => radians * (180.0 / pi);
}
