import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtocash/services/google_maps_service.dart';
import 'package:trashtocash/widgets/live_google_map_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleMapsService Unit Tests', () {
    test('GoogleMapsService is a singleton', () {
      final s1 = GoogleMapsService.instance;
      final s2 = GoogleMapsService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('calculateBearing calculates valid angle', () {
      const p1 = LatLng(-6.2088, 106.8456);
      const p2 = LatLng(-6.2115, 106.8480);
      final bearing = GoogleMapsService.instance.calculateBearing(p1, p2);
      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThanOrEqualTo(360.0));
    });

    test('interpolateLatLng interpolates correctly', () {
      const p1 = LatLng(0.0, 0.0);
      const p2 = LatLng(10.0, 20.0);
      final mid = GoogleMapsService.instance.interpolateLatLng(p1, p2, 0.5);
      expect(mid.latitude, 5.0);
      expect(mid.longitude, 10.0);
    });

    test('generateRoutePoints creates multiple points', () {
      const p1 = LatLng(-6.2088, 106.8456);
      const p2 = LatLng(-6.2115, 106.8480);
      final points = GoogleMapsService.instance.generateRoutePoints(p1, p2);
      expect(points.length, greaterThanOrEqualTo(3));
      expect(points.first, p1);
      expect(points.last, p2);
    });
  });

  group('LiveGoogleMapWidget Tests', () {
    testWidgets('LiveGoogleMapWidget renders in customer perspective with auto-follow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveGoogleMapWidget(
              perspective: MapPerspective.customer,
              customerName: 'Siti Rahmawati',
              driverName: 'Budi Santoso',
              height: 350,
            ),
          ),
        ),
      );

      // Single frame pump for repeat animation controller
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LiveGoogleMapWidget), findsOneWidget);
      expect(find.text('Buka Maps'), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.text('Kamera: Ikuti Driver 🛵'), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });

    testWidgets('LiveGoogleMapWidget renders in driver perspective', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveGoogleMapWidget(
              perspective: MapPerspective.driver,
              customerName: 'Pak RT Andi',
              driverName: 'Mitra T2C',
              height: 250,
              showNavigationBanner: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LiveGoogleMapWidget), findsOneWidget);
      expect(find.text('Buka Maps'), findsOneWidget);
      expect(find.text('Kamera: Ikuti Driver 🛵'), findsOneWidget);
    });
  });
}
