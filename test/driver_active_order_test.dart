import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/screens/driver/driver_active_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testOrder = DriverOrderItemModel(
    transactionId: 'TRX-TEST-5STEPS',
    userName: 'Ibu Ratna',
    userPhone: '081298765432',
    userAddress: 'Jl. Melati Blok C2 No. 15, Jakarta Pusat',
    wasteName: 'Plastik PET & Botol Daur Ulang',
    wasteType: 'Non-Organik',
    estimatedWeightKg: 5.0,
    ratePerKg: 10.0,
    estimatedReward: 50.0,
    deliveryFee: 15000.0,
    pickupDate: 'Hari Ini',
    pickupTime: '14:00',
    verificationPin: '8842',
    status: DriverOrderStatus.accepted,
    createdAt: DateTime.now().toIso8601String(),
  );

  group('DriverActiveOrderScreen 5-Step Workflow Tests', () {
    testWidgets('DriverActiveOrderScreen renders 5 interactive step tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverActiveOrderScreen(order: testOrder),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Menjalankan Orderan'), findsOneWidget);
      expect(find.text('ID: TRX-TEST-5STEPS'), findsOneWidget);

      // Verify all 5 step headers exist
      expect(find.text('Terima'), findsOneWidget);
      expect(find.text('Menuju'), findsOneWidget);
      expect(find.text('Tiba'), findsOneWidget);
      expect(find.text('Timbang & PIN'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Step 1 initial content
      expect(find.text('Langkah 1: Order Diterima & Siap Jalan'), findsOneWidget);
      expect(find.textContaining('Langkah 1/5'), findsOneWidget);
    });

    testWidgets('DriverActiveOrderScreen switches to Step 2 (Menuju)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverActiveOrderScreen(order: testOrder),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Step 2 'Menuju' tab
      await tester.tap(find.text('Menuju'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Langkah 2: Sedang Menuju Lokasi Warga'), findsOneWidget);
      expect(find.textContaining('Langkah 2/5'), findsOneWidget);
    });

    testWidgets('DriverActiveOrderScreen switches to Step 3 (Tiba)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverActiveOrderScreen(order: testOrder),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Step 3 'Tiba' tab
      await tester.tap(find.text('Tiba'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Langkah 3: Tiba di Alamat Warga'), findsOneWidget);
      expect(find.textContaining('Langkah 3/5'), findsOneWidget);
    });

    testWidgets('DriverActiveOrderScreen switches to Step 4 (Timbang & PIN)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverActiveOrderScreen(order: testOrder),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Step 4 'Timbang & PIN' tab
      await tester.tap(find.text('Timbang & PIN'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Langkah 4: Timbangan Digital & PIN'), findsOneWidget);
      expect(find.text('HASIL TIMBANGAN AKTUAL (KG)'), findsOneWidget);
      expect(find.text('Isi Cepat (8842)'), findsOneWidget);
      expect(find.textContaining('Langkah 4/5'), findsOneWidget);
    });

    testWidgets('DriverActiveOrderScreen switches to Step 5 (Selesai)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverActiveOrderScreen(order: testOrder),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Step 5 'Selesai' tab
      await tester.tap(find.text('Selesai'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Langkah 5: Penjemputan Sukses & Selesai'), findsOneWidget);
      expect(find.textContaining('Langkah 5/5'), findsOneWidget);
    });
  });
}
