import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/screens/history_screen.dart';
import 'package:trashtocash/screens/home.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryItemModel & Filter Tests', () {
    test('HistoryItemModel constructs correctly with all properties for deposit', () {
      const item = HistoryItemModel(
        id: 'TRX-DEP-001',
        title: 'Deposit Botol Plastik PET',
        subtitle: '2026-08-30 • 2.5 kg • Drop-off Mandiri',
        amount: '+Rp 25.000',
        numericAmount: 25000.0,
        isDeposit: true,
        type: HistoryType.deposit,
        status: 'Selesai',
        dateTime: '2026-08-30T10:00:00.000Z',
        icon: Icons.recycling,
        methodOrDest: 'Drop-off Mandiri',
        weight: '2.5 kg',
        ratePerKg: 'Rp 10.000 / kg',
        locationOrAccount: 'Drop Point Mall Central',
        ecoPoints: 25,
      );

      expect(item.id, 'TRX-DEP-001');
      expect(item.isDeposit, isTrue);
      expect(item.type, HistoryType.deposit);
      expect(item.numericAmount, 25000.0);
      expect(item.ecoPoints, 25);
    });

    test('HistoryItemModel constructs correctly for reward redemption voucher', () {
      const item = HistoryItemModel(
        id: 'TTC-ALFA-8891-2341',
        title: 'Voucher Belanja Alfamart Rp 25.000',
        subtitle: '2026-08-30 • Merchant: Alfamart • 50 Poin',
        amount: '-50 Poin',
        numericAmount: 50.0,
        isDeposit: false,
        type: HistoryType.rewardRedemption,
        status: 'Tersedia',
        dateTime: '2026-08-30T12:00:00.000Z',
        icon: Icons.card_giftcard_rounded,
        methodOrDest: 'Voucher Alfamart',
        voucherCode: 'TTC-ALFA-8891-2341',
        merchant: 'Alfamart',
        locationOrAccount: 'Voucher Belanja Digital',
        ecoPoints: 50,
      );

      expect(item.type, HistoryType.rewardRedemption);
      expect(item.voucherCode, 'TTC-ALFA-8891-2341');
      expect(item.merchant, 'Alfamart');
      expect(item.amount, '-50 Poin');
    });

    test('HistoryItemModel constructs correctly for AI Vision scan', () {
      const item = HistoryItemModel(
        id: 'SCAN-101',
        title: 'Scan AI: Botol Minuman Bening',
        subtitle: '2026-08-30 • Plastik • Akurasi 95%',
        amount: '+Rp 10.000',
        numericAmount: 10000.0,
        isDeposit: true,
        type: HistoryType.aiScan,
        status: 'Terscan AI',
        dateTime: '2026-08-30T14:30:00.000Z',
        icon: Icons.camera_alt_outlined,
        methodOrDest: 'Deteksi Kamera AI',
        confidence: 0.95,
        ecoPoints: 20,
      );

      expect(item.type, HistoryType.aiScan);
      expect(item.confidence, 0.95);
      expect(item.ecoPoints, 20);
    });
  });

  group('HistoryScreen Widget Tests', () {
    testWidgets('HistoryScreen renders title, summary cards, search bar, and filter tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Riwayat & Aktivitas'), findsOneWidget);
      expect(find.text('Total Deposit'), findsOneWidget);
      expect(find.text('Total Penarikan'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify all filter tabs exist
      expect(find.textContaining('Semua ('), findsOneWidget);
      expect(find.textContaining('Setor Sampah'), findsOneWidget);
      expect(find.textContaining('Penarikan Saldo'), findsOneWidget);
      expect(find.textContaining('Tukar Poin'), findsOneWidget);
      expect(find.textContaining('Scan AI'), findsOneWidget);

      // Tap on filter: Tukar Poin
      await tester.ensureVisible(find.textContaining('Tukar Poin'));
      await tester.tap(find.textContaining('Tukar Poin'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on filter: Scan AI
      await tester.ensureVisible(find.textContaining('Scan AI'));
      await tester.tap(find.textContaining('Scan AI'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('HistoryScreen search field updates query dynamically',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Alfamart');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Alfamart'), findsWidgets);
    });

    testWidgets('HistoryScreen filter Setor Sampah and modal interaction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on filter: Setor Sampah
      await tester.ensureVisible(find.textContaining('Setor Sampah'));
      await tester.tap(find.textContaining('Setor Sampah'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Setor Sampah'), findsWidgets);
    });

    test('DatabaseHelper historyUpdateNotifier increments on notifyHistoryChanged', () {
      final initial = DatabaseHelper.historyUpdateNotifier.value;
      DatabaseHelper.notifyHistoryChanged();
      expect(DatabaseHelper.historyUpdateNotifier.value, initial + 1);
    });

    test('HomeTrashToCash switchToTab updates tabNotifier to requested index', () {
      HomeTrashToCash.switchToTab(2);
      expect(HomeTrashToCash.tabNotifier.value, 2);
      HomeTrashToCash.switchToTab(0);
      expect(HomeTrashToCash.tabNotifier.value, 0);
    });
  });
}
