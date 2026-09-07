import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/models/reward_item_model.dart';
import 'package:trashtocash/screens/my_vouchers_screen.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'email': 'user@email.com',
      'userName': 'Faty Test',
      'phone': '081234567890',
    });
    DatabaseHelper.userEcoPointsNotifier.value = 150;
  });

  group('RewardItem & Default Catalog Tests', () {
    test('Default catalog contains all required categories and items', () {
      const catalog = RewardItem.defaultCatalog;
      expect(catalog.isNotEmpty, isTrue);
      expect(catalog.length, greaterThanOrEqualTo(15));

      final shoppingVouchers = catalog
          .where((r) => r.category == RewardCategory.voucherBelanja)
          .toList();
      expect(shoppingVouchers.isNotEmpty, isTrue);
      expect(shoppingVouchers.any((r) => r.merchant == 'Alfamart'), isTrue);
      expect(shoppingVouchers.any((r) => r.merchant == 'Indomaret'), isTrue);
      expect(shoppingVouchers.any((r) => r.merchant == 'Tokopedia'), isTrue);
      expect(shoppingVouchers.any((r) => r.merchant == 'Shopee'), isTrue);

      final ewalletVouchers = catalog
          .where((r) => r.category == RewardCategory.ewalletPulsa)
          .toList();
      expect(ewalletVouchers.isNotEmpty, isTrue);
      expect(ewalletVouchers.any((r) => r.merchant == 'GoPay'), isTrue);
      expect(ewalletVouchers.any((r) => r.merchant == 'DANA'), isTrue);

      final plnVouchers =
          catalog.where((r) => r.category == RewardCategory.tagihanPln).toList();
      expect(plnVouchers.isNotEmpty, isTrue);

      final merchandise = catalog
          .where((r) => r.category == RewardCategory.merchandise)
          .toList();
      expect(merchandise.isNotEmpty, isTrue);

      final donation =
          catalog.where((r) => r.category == RewardCategory.donasi).toList();
      expect(donation.isNotEmpty, isTrue);
    });

    test('RedeemedVoucher model correctly computes active, used, and expired status', () {
      final activeVoucher = RedeemedVoucher(
        id: 1,
        userEmail: 'user@email.com',
        rewardId: 1,
        title: 'Voucher Alfamart Rp 25.000',
        category: 'voucher_belanja',
        merchant: 'Alfamart',
        nominalValue: 'Rp 25.000',
        voucherCode: 'TTC-ALFA-1234-5678',
        barcode: '9842123456789',
        pointsUsed: 50,
        status: 'active',
        redeemedAt: DateTime.now().toIso8601String(),
        expiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      );

      expect(activeVoucher.isActive, isTrue);
      expect(activeVoucher.isUsed, isFalse);
      expect(activeVoucher.isExpired, isFalse);
      expect(activeVoucher.statusLabel, 'Tersedia (Aktif)');

      final usedVoucher = RedeemedVoucher(
        id: 2,
        userEmail: 'user@email.com',
        rewardId: 1,
        title: 'Voucher Alfamart Rp 25.000',
        category: 'voucher_belanja',
        merchant: 'Alfamart',
        nominalValue: 'Rp 25.000',
        voucherCode: 'TTC-ALFA-1234-5678',
        barcode: '9842123456789',
        pointsUsed: 50,
        status: 'used',
        redeemedAt: DateTime.now().toIso8601String(),
        expiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        usedAt: DateTime.now().toIso8601String(),
      );

      expect(usedVoucher.isUsed, isTrue);
      expect(usedVoucher.isActive, isFalse);
      expect(usedVoucher.statusLabel, 'Sudah Dipakai');

      final expiredVoucher = RedeemedVoucher(
        id: 3,
        userEmail: 'user@email.com',
        rewardId: 1,
        title: 'Voucher Alfamart Rp 25.000',
        category: 'voucher_belanja',
        merchant: 'Alfamart',
        nominalValue: 'Rp 25.000',
        voucherCode: 'TTC-ALFA-1234-5678',
        barcode: '9842123456789',
        pointsUsed: 50,
        status: 'active',
        redeemedAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        expiresAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      );

      expect(expiredVoucher.isExpired, isTrue);
      expect(expiredVoucher.isActive, isFalse);
      expect(expiredVoucher.statusLabel, 'Kedaluwarsa');
    });

    test('DatabaseHelper code generators generate valid codes and barcodes', () {
      final code = DatabaseHelper.generateVoucherCode('Alfamart');
      expect(code.startsWith('TTC-ALFA-'), isTrue);

      final barcode = DatabaseHelper.generateBarcode13();
      expect(barcode.length, 13);
      expect(barcode.startsWith('9842'), isTrue);
    });
  });

  group('RewardRedemptionScreen Widget Tests', () {
    testWidgets('RewardRedemptionScreen renders header, search, chips, and cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DatabaseHelper.userEcoPointsNotifier.value = 200;

      await tester.pumpWidget(
        const MaterialApp(
          home: RewardRedemptionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tukar Poin & Hadiah'), findsOneWidget);
      expect(find.text('200 Poin'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('🛒 Belanja'), findsOneWidget);
      expect(find.text('📱 E-Wallet'), findsOneWidget);
      expect(find.text('Voucher Belanja Alfamart Rp 25.000'), findsOneWidget);

      // Tap category chip: 🛒 Belanja
      await tester.tap(find.text('🛒 Belanja'));
      await tester.pumpAndSettle();

      expect(find.text('Voucher Belanja Alfamart Rp 25.000'), findsOneWidget);
      expect(find.text('Voucher Belanja Indomaret Rp 25.000'), findsOneWidget);

      // Tap on Alfamart reward card to open confirmation bottom sheet
      await tester.tap(find.text('Voucher Belanja Alfamart Rp 25.000'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Penukaran Poin'), findsOneWidget);
      expect(find.text('Biaya Penukaran Voucher'), findsOneWidget);
      expect(find.text('-50 Poin'), findsOneWidget);
      expect(find.text('Tukar Sekarang (50 Poin) 🎁'), findsOneWidget);
    });

    testWidgets('RewardRedemptionScreen search filters rewards in real-time',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: RewardRedemptionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Indomaret');
      await tester.pumpAndSettle();

      expect(find.text('Voucher Belanja Indomaret Rp 25.000'), findsOneWidget);
      expect(find.text('Voucher Belanja Alfamart Rp 25.000'), findsNothing);
    });
  });

  group('MyVouchersScreen Widget Tests', () {
    testWidgets('MyVouchersScreen renders TabBar with 4 tabs and empty or initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyVouchersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voucher & Hadiah Saya'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Terpakai'), findsOneWidget);
      expect(find.text('Kedaluwarsa'), findsOneWidget);
    });
  });
}
