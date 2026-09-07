import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/screens/drop_location.dart';
import 'package:trashtocash/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService Unit Tests', () {
    test('LocationService is a singleton', () {
      final s1 = LocationService.instance;
      final s2 = LocationService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('UserGpsState correctly formats coordinates and address', () {
      final state = UserGpsState(
        latitude: -6.2088,
        longitude: 106.8456,
        accuracy: 4.5,
        streetAddress: 'Jl. Melati No. 5',
        district: 'Kebayoran Baru',
        city: 'Jakarta Selatan',
        lastUpdated: DateTime.now(),
      );

      expect(state.coordinatesDisplay, '-6.20880, 106.84560');
      expect(state.fullAddress, 'Jl. Melati No. 5, Kebayoran Baru, Jakarta Selatan');
      expect(state.accuracy, 4.5);

      final copy = state.copyWith(accuracy: 3.0, hasPermission: true);
      expect(copy.accuracy, 3.0);
      expect(copy.hasPermission, true);
      expect(copy.streetAddress, 'Jl. Melati No. 5');
    });

    test('calculateDistanceKm calculates distance in kilometers correctly', () {
      // Jakarta to nearby point (~1-2 km)
      final dist = LocationService.instance.calculateDistanceKm(
        -6.2088,
        106.8456,
        -6.2115,
        106.8480,
      );

      expect(dist, greaterThanOrEqualTo(0.1));
      expect(dist, lessThan(5.0));
    });

    test('getEtaEstimate returns valid driving and walking ETA strings', () {
      final eta = LocationService.instance.getEtaEstimate(2.5);
      expect(eta['driving'], contains('mnt'));
      expect(eta['walking'], contains('mnt'));
    });
  });

  group('DropPointLocationScreen Widget Tests', () {
    testWidgets('DropPointLocationScreen renders with GPS bar and drop point cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DropPointLocationScreen(),
        ),
      );

      // Single frame pump for repeat animation
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lokasi Drop Point & GPS'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsWidgets);
    });
  });
}
