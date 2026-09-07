import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/notification_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  static const double minWithdrawalAmount = 100000.0;
  int _selectedTarget = 0;
  final TextEditingController _amountController =
      TextEditingController(text: '100000');

  List<Map<String, dynamic>> _targets = [
    {
      'title': 'Bank Central (BCA)',
      'account': '**** 1234 (A/N Faty)',
      'icon': Icons.account_balance_outlined,
    },
    {
      'title': 'GoPay E-Wallet',
      'account': '0812-****-7890 (A/N Faty)',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'title': 'DANA Digital Wallet',
      'account': '0812-****-7890 (A/N Faty)',
      'icon': Icons.account_balance_wallet_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentAccounts();
  }

  Future<void> _loadPaymentAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ??
          prefs.getString('userEmail') ??
          'user@email.com';
      final accounts = await DatabaseHelper.instance.getUserPaymentAccounts(email);

      final bankName = accounts['bank_name'] ?? prefs.getString('bankName') ?? 'Bank Central (BCA)';
      final bankNumber = accounts['bank_account_number'] ?? prefs.getString('bankAccountNumber');
      final bankHolder = accounts['bank_account_holder'] ?? prefs.getString('bankAccountHolder') ?? prefs.getString('userName') ?? 'Member';

      final ewalletType = accounts['ewallet_type'] ?? prefs.getString('ewalletType') ?? 'DANA';
      final ewalletNumber = accounts['ewallet_number'] ?? prefs.getString('ewalletNumber') ?? prefs.getString('phone') ?? '0812-****-7890';
      final ewalletHolder = accounts['ewallet_account_holder'] ?? prefs.getString('ewalletAccountHolder') ?? bankHolder;
      final preferred = accounts['preferred_payout_method'] ?? prefs.getString('preferredPayoutMethod') ?? 'ewallet';

      final List<Map<String, dynamic>> dynamicTargets = [];

      final ewalletItem = {
        'title': '$ewalletType Digital Wallet',
        'account': '$ewalletNumber (A/N $ewalletHolder)',
        'icon': Icons.phone_android,
        'badge': 'E-Wallet Terdaftar',
      };

      final bankItem = {
        'title': bankName,
        'account': (bankNumber != null && bankNumber.isNotEmpty)
            ? '$bankNumber (A/N $bankHolder)'
            : '**** 1234 (A/N $bankHolder)',
        'icon': Icons.account_balance_outlined,
        'badge': (bankNumber != null && bankNumber.isNotEmpty) ? 'Rekening Terdaftar' : null,
      };

      if (preferred == 'bank') {
        dynamicTargets.add(bankItem);
        dynamicTargets.add(ewalletItem);
      } else {
        dynamicTargets.add(ewalletItem);
        dynamicTargets.add(bankItem);
      }

      // Alternative E-Wallets
      final altEwallet = ewalletType.toLowerCase() == 'dana' ? 'GoPay' : 'DANA';
      dynamicTargets.add({
        'title': '$altEwallet E-Wallet',
        'account': '$ewalletNumber (A/N $ewalletHolder)',
        'icon': Icons.account_balance_wallet_outlined,
      });

      final thirdEwallet = (ewalletType.toLowerCase() == 'ovo' || altEwallet == 'OVO') ? 'ShopeePay' : 'OVO';
      dynamicTargets.add({
        'title': '$thirdEwallet Digital Wallet',
        'account': '$ewalletNumber (A/N $ewalletHolder)',
        'icon': Icons.account_balance_wallet_outlined,
      });

      if (mounted) {
        setState(() {
          _targets = dynamicTargets;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildNoteItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xFF0D6938),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: description,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        title: const Text('Tarik Tunai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6938),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Saldo Tersedia',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<double>(
                    valueListenable: DatabaseHelper.userBalanceNotifier,
                    builder: (context, balance, _) {
                      return Text(
                        DatabaseHelper.formatRupiah(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Jumlah Penarikan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah Penarikan (Rp)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Min. Rp 100.000',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6938),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6938)),
                hintText: '100.000',
                filled: true,
                fillColor: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                helperText: '* Minimal nominal penarikan adalah Rp 100.000',
                helperStyle: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Amount Selector Chips
            ValueListenableBuilder<double>(
              valueListenable: DatabaseHelper.userBalanceNotifier,
              builder: (context, currentBal, _) {
                final quickAmounts = [100000.0, 200000.0, 500000.0];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...quickAmounts.map((qAmount) {
                      final label = 'Rp ${(qAmount / 1000).toInt()}rb';
                      return ActionChip(
                        label: Text(label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF0D6938),
                        ),
                        backgroundColor: isDark ? const Color(0xFF263229) : const Color(0xFFEAF4EE),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFCFE8D7),
                        ),
                        onPressed: () {
                          _amountController.text = qAmount.toStringAsFixed(0);
                        },
                      );
                    }),
                    ActionChip(
                      label: const Text('Tarik Semua'),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      backgroundColor: const Color(0xFF0D6938),
                      side: BorderSide.none,
                      onPressed: () {
                        if (currentBal > 0) {
                          _amountController.text = currentBal.toStringAsFixed(0);
                        } else {
                          _amountController.text = '100000';
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Transfer Ke
            Text(
              'Pilih Rekening / E-Wallet Tujuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Selectable Targets
            ...List.generate(_targets.length, (index) {
              final isSelected = _selectedTarget == index;
              final target = _targets[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedTarget = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE))
                        : Theme.of(context).cardColor,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D6938)
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF0D6938).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0D6938)
                              : (isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          target['icon'] as IconData,
                          color: isSelected ? Colors.white : const Color(0xFF0D6938),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    target['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (target['badge'] != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      target['badge'] as String,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D6938),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              target['account'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFF0D6938) : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  final targetName = _targets[_selectedTarget]['title'] as String;
                  final rawAmountText = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
                  final amount = double.tryParse(rawAmountText) ?? 0.0;
                  final currentBalance = DatabaseHelper.userBalanceNotifier.value;

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Masukkan nominal penarikan yang valid.'),
                      ),
                    );
                    return;
                  }

                  if (amount < minWithdrawalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Minimal penarikan saldo adalah Rp 100.000.'),
                      ),
                    );
                    return;
                  }

                  if (amount > currentBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          'Saldo tidak mencukupi. Saldo Anda: Rp ${currentBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        ),
                      ),
                    );
                    return;
                  }

                  final success = await DatabaseHelper.instance.debitUserBalance(
                    amount: amount,
                    title: 'Penarikan Saldo ke $targetName',
                    description: 'Rekening/No: ${_targets[_selectedTarget]['account']}',
                    channel: targetName,
                  );

                  if (!context.mounted) return;

                  if (success) {
                    final formattedAmount = 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
                    NotificationHelper.triggerNotification(
                      context: context,
                      type: NotificationType.withdrawalSuccess,
                      title: 'Penarikan Saldo Berhasil Diajukan 💸',
                      message: 'Permintaan penarikan $formattedAmount ke $targetName telah berhasil diproses.',
                      actionLabel: 'Mutasi',
                      showInAppBanner: false,
                    );
                    SoundHelper.playWithdrawalSuccessSound();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0D6938),
                        content: Text('Penarikan $formattedAmount ke $targetName berhasil!'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Konfirmasi Penarikan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Note Card Under Withdrawal Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF2F8F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2D4033) : const Color(0xFFD4EADB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0D6938),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Catatan & Ketentuan Penarikan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0D6938),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildNoteItem(
                    icon: Icons.payments_outlined,
                    title: 'Minimal Penarikan',
                    description: 'Penarikan saldo dapat dilakukan dengan batas minimal Rp 100.000 per transaksi.',
                    isDark: isDark,
                  ),
                  _buildNoteItem(
                    icon: Icons.schedule_outlined,
                    title: 'Waktu Proses',
                    description: 'Dana akan diproses secara instan atau maksimal 1x24 jam kerja ke rekening / e-wallet.',
                    isDark: isDark,
                  ),
                  _buildNoteItem(
                    icon: Icons.verified_outlined,
                    title: 'Bebas Biaya Admin',
                    description: 'Penarikan saldo 100% gratis tanpa potongan biaya administrasi.',
                    isDark: isDark,
                  ),
                  _buildNoteItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Validasi Rekening',
                    description: 'Pastikan nama pemilik rekening / e-wallet sesuai dengan identitas akun Anda.',
                    isDark: isDark,
                  ),
                  _buildNoteItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Pusat Bantuan',
                    description: 'Jika saldo belum masuk lebih dari 24 jam, hubungi layanan bantuan kami.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner Tukar Poin Alternative
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RewardRedemptionScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Punya Eco-Points? Tukar Voucher! 🎁',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tukar poin jadi voucher Alfamart, Indomaret, PLN & Pulsa',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
