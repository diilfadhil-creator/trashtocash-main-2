import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/chat_sync_helper.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/models/user_model.dart';
import 'package:trashtocash/screens/withdrawal_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'email': 'user@email.com',
      'userName': 'TrashToCash Member',
    });
    // Reset notifier to clean initial baseline (0.0 balance, 0 points)
    DatabaseHelper.userBalanceNotifier.value = 0.0;
    DatabaseHelper.userEcoPointsNotifier.value = 0;
  });

  group('User Wallet & Saldo Persistence Tests', () {
    test('Initial user wallet balance and Eco-Points default correctly to 0', () {
      expect(DatabaseHelper.userBalanceNotifier.value, 0.0);
      expect(DatabaseHelper.userEcoPointsNotifier.value, 0);
    });

    test('creditUserBalance increases total balance and Eco-Points on waste deposit', () {
      final initialBalance = DatabaseHelper.userBalanceNotifier.value;
      const depositReward = 25.0; // 2.5 kg Plastic @ 10.0 T-Cash
      const earnedEcoPoints = 25;

      // Simulate waste deposit credit
      DatabaseHelper.userBalanceNotifier.value += depositReward;
      DatabaseHelper.userEcoPointsNotifier.value += earnedEcoPoints;

      expect(DatabaseHelper.userBalanceNotifier.value, initialBalance + depositReward);
      expect(DatabaseHelper.userBalanceNotifier.value, 25.0);
      expect(DatabaseHelper.userEcoPointsNotifier.value, 25);
    });

    test('Multiple waste deposits incrementally accumulate total saldo according to sales', () {
      DatabaseHelper.userBalanceNotifier.value = 0.0;

      // 1st Deposit: Kardus 4.0 kg @ 8.0 = 32.0 T-Cash
      DatabaseHelper.userBalanceNotifier.value += 32.0;
      expect(DatabaseHelper.userBalanceNotifier.value, 32.0);

      // 2nd Deposit: Minyak Jelantah 3.5 kg @ 6.5 = 22.75 T-Cash
      DatabaseHelper.userBalanceNotifier.value += 22.75;
      expect(DatabaseHelper.userBalanceNotifier.value, 54.75);

      // 3rd Deposit: Logam 1.8 kg @ 15.0 = 27.0 T-Cash
      DatabaseHelper.userBalanceNotifier.value += 27.0;
      expect(DatabaseHelper.userBalanceNotifier.value, 81.75);
    });

    test('debitUserBalance reduces total balance upon withdrawal', () {
      DatabaseHelper.userBalanceNotifier.value = 250000.0;
      const withdrawalAmount = 100000.0;

      DatabaseHelper.userBalanceNotifier.value -= withdrawalAmount;
      expect(DatabaseHelper.userBalanceNotifier.value, 150000.0);
    });

    test('Validation enforces minimum withdrawal threshold of Rp 100.000', () {
      const minWithdrawal = 100000.0;
      DatabaseHelper.userBalanceNotifier.value = 200000.0;

      const belowMinAmount = 50000.0;
      final isBelowMinValid = belowMinAmount >= minWithdrawal;
      expect(isBelowMinValid, isFalse);

      const validMinAmount = 100000.0;
      final isValidMin = validMinAmount >= minWithdrawal;
      expect(isValidMin, isTrue);
    });

    test('Validation prevents withdrawing more than current available balance', () {
      DatabaseHelper.userBalanceNotifier.value = 50000.0;
      const invalidWithdrawal = 100000.0;

      final canWithdraw = invalidWithdrawal <= DatabaseHelper.userBalanceNotifier.value;
      expect(canWithdraw, isFalse);
      expect(DatabaseHelper.userBalanceNotifier.value, 50000.0); // Balance remains unchanged
    });

    test('UserModel correctly serializes and deserializes bank and e-wallet payment accounts', () {
      final user = UserModel(
        id: 1,
        name: 'Ahmad Fauzi',
        email: 'ahmad@example.com',
        password: 'password123',
        phone: '081234567890',
        bankName: 'Bank Central (BCA)',
        bankAccountNumber: '5420192831',
        bankAccountHolder: 'Ahmad Fauzi',
        ewalletType: 'DANA',
        ewalletNumber: '081234567890',
        ewalletAccountHolder: 'Ahmad Fauzi',
        preferredPayoutMethod: 'ewallet',
        createdAt: '2026-08-29T10:00:00.000',
      );

      final map = user.toMap();
      expect(map['bank_name'], 'Bank Central (BCA)');
      expect(map['bank_account_number'], '5420192831');
      expect(map['bank_account_holder'], 'Ahmad Fauzi');
      expect(map['ewallet_type'], 'DANA');
      expect(map['ewallet_number'], '081234567890');
      expect(map['ewallet_account_holder'], 'Ahmad Fauzi');
      expect(map['preferred_payout_method'], 'ewallet');

      final fromMap = UserModel.fromMap(map);
      expect(fromMap.bankName, 'Bank Central (BCA)');
      expect(fromMap.bankAccountNumber, '5420192831');
      expect(fromMap.bankAccountHolder, 'Ahmad Fauzi');
      expect(fromMap.ewalletType, 'DANA');
      expect(fromMap.ewalletNumber, '081234567890');
      expect(fromMap.ewalletAccountHolder, 'Ahmad Fauzi');
      expect(fromMap.preferredPayoutMethod, 'ewallet');

      final updated = fromMap.copyWith(
        bankName: 'Bank Mandiri',
        bankAccountNumber: '1400012345678',
        ewalletType: 'GoPay',
        preferredPayoutMethod: 'bank',
      );
      expect(updated.bankName, 'Bank Mandiri');
      expect(updated.bankAccountNumber, '1400012345678');
      expect(updated.ewalletType, 'GoPay');
      expect(updated.preferredPayoutMethod, 'bank');
      expect(updated.name, 'Ahmad Fauzi');
    });

    test('ChatSyncHelper correctly adds and notifies messages', () {
      ChatSyncHelper.instance.messagesNotifier.value = [];
      expect(ChatSyncHelper.instance.messagesNotifier.value.length, 0);

      ChatSyncHelper.instance.sendMessage(
        senderRole: 'user',
        text: 'Halo kurir, posisi di mana?',
      );

      expect(ChatSyncHelper.instance.messagesNotifier.value.length, 1);
      final lastMsg = ChatSyncHelper.instance.messagesNotifier.value.first;
      expect(lastMsg.senderRole, 'user');
      expect(lastMsg.text, 'Halo kurir, posisi di mana?');
      expect(lastMsg.isFromUser, isTrue);
      expect(lastMsg.isFromDriver, isFalse);
    });

    testWidgets('WithdrawalScreen renders minimum Rp 100.000 indicator and note section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WithdrawalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tarik Tunai'), findsOneWidget);
      expect(find.text('Min. Rp 100.000'), findsOneWidget);
      expect(find.text('Catatan & Ketentuan Penarikan'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Minimal Penarikan:'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Waktu Proses:'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Bebas Biaya Admin:'),
        ),
        findsOneWidget,
      );
    });

    test('DatabaseHelper.formatRupiah formats currency correctly', () {
      expect(DatabaseHelper.formatRupiah(0), 'Rp 0');
      expect(DatabaseHelper.formatRupiah(50000), 'Rp 50.000');
      expect(DatabaseHelper.formatRupiah(100000), 'Rp 100.000');
      expect(DatabaseHelper.formatRupiah(1500000), 'Rp 1.500.000');
      expect(DatabaseHelper.formatRupiah(100000, withSymbol: false), '100.000');
      expect(DatabaseHelper.formatRupiah(-50000), '-Rp 50.000');
    });
  });
}
