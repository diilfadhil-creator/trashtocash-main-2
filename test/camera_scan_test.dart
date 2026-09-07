import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/screens/live_camera_scan_screen.dart';
import 'package:trashtocash/services/camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraService Unit Tests', () {
    test('CameraService is a singleton', () {
      final s1 = CameraService.instance;
      final s2 = CameraService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('analyzeWasteImage returns valid AiWasteScanResult with confidence and reward calculation', () async {
      const sampleItem = WasteItemModel(
        id: 1,
        name: 'Plastik PET (Botol Mineral Bening)',
        type: 'Non-Organik',
        sampleItem: 'Botol air mineral',
        ratePerKg: 10.0,
        ecoPoints: 20,
        iconName: 'bottle',
        imageUrl: 'https://example.com/pet.jpg',
        description: 'Plastik daur ulang',
        handlingTip: 'Bilas bersih',
      );

      final result = await CameraService.instance.analyzeWasteImage(
        targetWasteItem: sampleItem,
      );

      expect(result.wasteItem.name, 'Plastik PET (Botol Mineral Bening)');
      expect(result.confidenceScore, greaterThanOrEqualTo(0.90));
      expect(result.confidenceScore, lessThanOrEqualTo(1.0));
      expect(result.estimatedWeightKg, greaterThan(0));
      expect(result.estimatedReward, equals(result.estimatedWeightKg * sampleItem.ratePerKg));
      expect(result.estimatedEcoPoints, equals((result.estimatedWeightKg * sampleItem.ecoPoints).toInt()));
      expect(result.tags, isNotEmpty);
    });

    test('parseQrCode correctly parses drop point and pickup order QR formats', () async {
      final dropResult = await CameraService.instance.parseQrCode('DROP-POINT-MELATI-01');
      expect(dropResult.type, 'drop_point');
      expect(dropResult.rawCode, 'DROP-POINT-MELATI-01');
      expect(dropResult.title, contains('Drop Point'));

      final pickupResult = await CameraService.instance.parseQrCode('TRX-JMP-882190');
      expect(pickupResult.type, 'pickup_order');
      expect(pickupResult.rawCode, 'TRX-JMP-882190');
      expect(pickupResult.description, contains('serah terima'));
    });
  });

  group('LiveCameraScanScreen Widget Tests', () {
    testWidgets('LiveCameraScanScreen renders correctly in simulation mode with HUD elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveCameraScanScreen(isPickup: false),
        ),
      );

      // Pump single frame for repeating animation
      await tester.pump(const Duration(milliseconds: 100));

      // Verify mode tabs and buttons render
      expect(find.text('AI Sampah'), findsOneWidget);
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Katalog'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });
}
