import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/models/driver_model.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String _selectedMethod = 'BCA';
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    DriverHelper.instance.loadDriverTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _showWithdrawModal(BuildContext context, double currentBalance) {
    _amountController.text = currentBalance >= 100000
        ? '100000'
        : (currentBalance > 0 ? currentBalance.toStringAsFixed(0) : '100000');
    _accountController.text = '8821-4455-091';
    _errorMsg = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF0D6938),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tarik Komisi Mitra',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Metode Penarikan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['BCA', 'Mandiri', 'BRI', 'GoPay', 'OVO', 'DANA'].map((method) {
                    final isSel = _selectedMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSel,
                      selectedColor: const Color(0xFF0D6938),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() {
                            _selectedMethod = method;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nomor Rekening / No. HP E-Wallet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 88214455091 / 081234567890',
                    prefixIcon: const Icon(Icons.credit_card, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF263229) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nominal Penarikan (Rp)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Min. Rp 100.000',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    hintText: '100.000',
                    helperText: '* Minimal nominal penarikan adalah Rp 100.000',
                    helperStyle: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF263229) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final val = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                      if (val <= 0) {
                        setModalState(() {
                          _errorMsg = 'Masukkan nominal penarikan yang valid.';
                        });
                        return;
                      }
                      if (val < 100000) {
                        setModalState(() {
                          _errorMsg = 'Minimal penarikan saldo adalah Rp 100.000.';
                        });
                        return;
                      }
                      if (val > currentBalance) {
                        setModalState(() {
                          _errorMsg = 'Saldo tidak mencukupi (Maks Rp ${currentBalance.toStringAsFixed(0)}).';
                        });
                        return;
                      }

                      final success = await DriverHelper.instance.withdrawEarnings(
                        amount: val,
                        bankOrWalletName: _selectedMethod,
                        accountNumber: _accountController.text.trim(),
                        context: context,
                      );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0D6938),
                              behavior: SnackBarBehavior.floating,
                              content: Text('Penarikan Rp ${val.toStringAsFixed(0)} berhasil diproses! 💸'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Konfirmasi & Tarik Dana',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Note inside modal
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF263229) : const Color(0xFFF2F8F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D4033) : const Color(0xFFD4EADB),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF0D6938)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan: Minimal penarikan saldo adalah Rp 100.000. Proses pencairan dana maksimal 1x24 jam kerja bebas biaya admin.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<DriverProfileModel>(
      valueListenable: DriverHelper.instance.profileNotifier,
      builder: (context, profile, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF101713) : const Color(0xFFF9FBF9),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF101713) : const Color(0xFFF9FBF9),
            elevation: 0,
            title: Text(
              'Dompet & Komisi Driver',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6938), Color(0xFF1F7A47)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saldo Aktif Siap Tarik',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Bebas Biaya Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${profile.walletBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D6938),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send_to_mobile, size: 18),
                          label: const Text(
                            'Tarik Saldo ke Rekening / E-Wallet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => _showWithdrawModal(context, profile.walletBalance),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Performance Summary Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Jemput Hari Ini',
                        '${profile.completedPickupsToday}x',
                        Icons.done_all,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Terkumpul',
                        '${profile.totalKgToday.toStringAsFixed(1)} kg',
                        Icons.scale,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SQLite Real Wallet Transactions History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Transaksi Dompet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Muat Ulang Database',
                      onPressed: () => DriverHelper.instance.loadDriverTransactions(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: DriverHelper.instance.driverTransactionsNotifier,
                  builder: (context, transactions, _) {
                    if (transactions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A241E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada transaksi penarikan/komisi di database.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final tx = transactions[idx];
                        final isWithdrawal = tx['type'] == 'withdrawal';
                        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                        final title = tx['title'] ?? (isWithdrawal ? 'Penarikan Dana' : 'Komisi Penjemputan');
                        final desc = tx['description'] ?? tx['channel'] ?? '';
                        final date = tx['created_at']?.toString().split('T').first ?? 'Hari Ini';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A241E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isWithdrawal
                                      ? Colors.orange.shade50
                                      : const Color(0xFFEAF4EE),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isWithdrawal ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isWithdrawal ? Colors.orange : const Color(0xFF0D6938),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isWithdrawal ? "-" : "+"}Rp ${amount.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isWithdrawal ? Colors.orange.shade800 : const Color(0xFF0D6938),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4EE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0D6938), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
