import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/screens/chosemethod_screen.dart';
import 'package:trashtocash/screens/drop_location.dart';
import 'package:trashtocash/screens/home.dart';
import 'package:trashtocash/screens/my_vouchers_screen.dart';
import 'package:trashtocash/screens/pickup_status.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';

enum HistoryFilter { all, deposit, withdrawal, reward, scan }

enum HistoryType { deposit, withdrawal, rewardRedemption, aiScan }

class HistoryItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final double numericAmount;
  final bool isDeposit;
  final HistoryType type;
  final String status;
  final String dateTime;
  final IconData icon;
  final String methodOrDest;
  final String? weight;
  final String? ratePerKg;
  final String? locationOrAccount;
  final String? voucherCode;
  final String? merchant;
  final int? ecoPoints;
  final double? confidence;

  const HistoryItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.numericAmount,
    required this.isDeposit,
    required this.type,
    required this.status,
    required this.dateTime,
    required this.icon,
    required this.methodOrDest,
    this.weight,
    this.ratePerKg,
    this.locationOrAccount,
    this.voucherCode,
    this.merchant,
    this.ecoPoints,
    this.confidence,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<HistoryItemModel> _dbTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.historyUpdateNotifier.addListener(_onHistoryChanged);
    _loadDatabaseTransactions();
  }

  void _onHistoryChanged() {
    if (mounted) {
      _loadDatabaseTransactions(silent: true);
    }
  }

  @override
  void dispose() {
    DatabaseHelper.historyUpdateNotifier.removeListener(_onHistoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabaseTransactions({bool silent = false}) async {
    if (!silent && _dbTransactions.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ??
          prefs.getString('userEmail') ??
          prefs.getString('registeredEmail') ??
          'user@email.com';

      // 1. Ambil transaksi setoran & penjemputan sampah
      final pickups =
          await DatabaseHelper.instance.getWastePickupsByUser(email);

      // 2. Ambil mutasi dompet saldo & penukaran poin
      final walletTrx =
          await DatabaseHelper.instance.getUserWalletTransactions(email);

      // 3. Ambil riwayat voucher yang telah ditukar
      final redeemedVouchers =
          await DatabaseHelper.instance.getUserRedeemedRewards(email);

      // 4. Ambil riwayat deteksi scan kamera AI
      final aiScans =
          await DatabaseHelper.instance.getAiScanHistory(email);

      final List<HistoryItemModel> converted = [];
      final Set<String> processedTrxIds = {};

      // 1. Map Waste Pickups / Deposits
      for (final p in pickups) {
        final isOrganic = p.wasteType.toLowerCase() == 'organik';
        final formattedDate = p.createdAt.contains('T')
            ? p.createdAt.split('T').first
            : p.createdAt;
        processedTrxIds.add(p.transactionId);
        converted.add(
          HistoryItemModel(
            id: p.transactionId,
            title: 'Deposit ${p.wasteName}',
            subtitle:
                '$formattedDate • ${p.weightKg.toStringAsFixed(1)} kg • ${p.method}',
            amount: '+${DatabaseHelper.formatRupiah(p.totalReward)}',
            numericAmount: p.totalReward,
            isDeposit: true,
            type: HistoryType.deposit,
            status: p.status,
            dateTime: p.createdAt,
            icon: isOrganic ? Icons.energy_savings_leaf : Icons.recycling,
            methodOrDest: p.method,
            weight: '${p.weightKg.toStringAsFixed(1)} kg',
            ratePerKg: '${DatabaseHelper.formatRupiah(p.ratePerKg)} / kg',
            locationOrAccount: p.method == 'Jemput Sampah'
                ? (p.pickupAddress ?? 'Penjemputan Kurir')
                : (p.dropPointName ?? 'Drop Point'),
            ecoPoints: (p.weightKg * 10).toInt(),
          ),
        );
      }

      // 2. Map Wallet Mutations (Deposit, Withdrawal, Reward Redemption)
      for (final wt in walletTrx) {
        final trxId = (wt['transaction_id'] as String?) ?? 'TRX-W-${wt['id']}';
        if (processedTrxIds.contains(trxId)) continue;
        processedTrxIds.add(trxId);

        final wtType = (wt['type'] as String?) ?? 'deposit';
        final amount = (wt['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt =
            (wt['created_at'] as String?) ?? DateTime.now().toIso8601String();
        final formattedDate =
            createdAt.contains('T') ? createdAt.split('T').first : createdAt;

        if (wtType == 'reward_redemption') {
          converted.add(
            HistoryItemModel(
              id: trxId,
              title: (wt['title'] as String?) ?? 'Tukar Eco-Points',
              subtitle:
                  '$formattedDate • ${(wt['description'] as String?) ?? (wt['channel'] ?? 'Penukaran Voucher')}',
              amount: wt['description'] != null &&
                      (wt['description'] as String).contains('Eco-Points')
                  ? '-${(wt['description'] as String).split('Eco-Points').first.replaceAll(RegExp(r'[^0-9]'), '')} Poin'
                  : '-Poin Eco',
              numericAmount: 0.0,
              isDeposit: false,
              type: HistoryType.rewardRedemption,
              status: (wt['status'] as String?) ?? 'Berhasil',
              dateTime: createdAt,
              icon: Icons.card_giftcard_rounded,
              methodOrDest: (wt['channel'] as String?) ?? 'Voucher Belanja',
              locationOrAccount: wt['description'] as String?,
            ),
          );
        } else if (wtType == 'withdrawal') {
          converted.add(
            HistoryItemModel(
              id: trxId,
              title: (wt['title'] as String?) ?? 'Penarikan Tunai',
              subtitle:
                  '$formattedDate • ${(wt['description'] as String?) ?? (wt['channel'] ?? 'Transfer Bank / E-Wallet')}',
              amount: '-${DatabaseHelper.formatRupiah(amount.abs())}',
              numericAmount: amount.abs(),
              isDeposit: false,
              type: HistoryType.withdrawal,
              status: (wt['status'] as String?) ?? 'Selesai',
              dateTime: createdAt,
              icon: Icons.account_balance_wallet_outlined,
              methodOrDest:
                  (wt['channel'] as String?) ?? 'Penarikan Saldo Dompet',
              locationOrAccount: (wt['description'] as String?) ??
                  (wt['channel'] as String?),
            ),
          );
        } else {
          converted.add(
            HistoryItemModel(
              id: trxId,
              title: (wt['title'] as String?) ?? 'Deposit Saldo',
              subtitle:
                  '$formattedDate • ${(wt['description'] as String?) ?? (wt['channel'] ?? 'Dompet')}',
              amount:
                  '+${DatabaseHelper.formatRupiah(amount.abs())}',
              numericAmount: amount.abs(),
              isDeposit: true,
              type: HistoryType.deposit,
              status: (wt['status'] as String?) ?? 'Selesai',
              dateTime: createdAt,
              icon: Icons.account_balance_wallet_outlined,
              methodOrDest: (wt['channel'] as String?) ?? 'Deposit Saldo',
              locationOrAccount: (wt['description'] as String?) ??
                  (wt['channel'] as String?),
            ),
          );
        }
      }

      // 3. Map Redeemed Vouchers (if not already mapped in wallet transactions)
      for (final v in redeemedVouchers) {
        if (processedTrxIds.contains(v.voucherCode)) continue;
        processedTrxIds.add(v.voucherCode);

        final formattedDate = v.redeemedAt.contains('T')
            ? v.redeemedAt.split('T').first
            : v.redeemedAt;

        converted.add(
          HistoryItemModel(
            id: v.voucherCode,
            title: v.title,
            subtitle:
                '$formattedDate • Merchant: ${v.merchant} • ${v.pointsUsed} Poin',
            amount: '-${v.pointsUsed} Poin',
            numericAmount: v.pointsUsed.toDouble(),
            isDeposit: false,
            type: HistoryType.rewardRedemption,
            status: v.statusLabel,
            dateTime: v.redeemedAt,
            icon: Icons.card_giftcard_rounded,
            methodOrDest: 'Voucher ${v.merchant}',
            voucherCode: v.voucherCode,
            merchant: v.merchant,
            locationOrAccount: v.targetAccount ?? 'Voucher Belanja Digital',
            ecoPoints: v.pointsUsed,
          ),
        );
      }

      // 4. Map AI Vision Scans
      for (final s in aiScans) {
        final scanId = 'SCAN-${s['id']}';
        if (processedTrxIds.contains(scanId)) continue;
        processedTrxIds.add(scanId);

        final scannedAt = (s['scanned_at'] as String?) ??
            DateTime.now().toIso8601String();
        final formattedDate =
            scannedAt.contains('T') ? scannedAt.split('T').first : scannedAt;
        final rewardVal = (s['reward'] as num?)?.toDouble() ?? 0.0;
        final confVal = (s['confidence'] as num?)?.toDouble() ?? 0.85;
        final weightVal = (s['weight_kg'] as num?)?.toDouble() ?? 1.0;

        converted.add(
          HistoryItemModel(
            id: scanId,
            title: 'Scan AI: ${s['item_name']}',
            subtitle:
                '$formattedDate • ${s['category']} • Akurasi ${(confVal * 100).toInt()}%',
            amount: '+${DatabaseHelper.formatRupiah(rewardVal)}',
            numericAmount: rewardVal,
            isDeposit: true,
            type: HistoryType.aiScan,
            status: 'Terscan AI',
            dateTime: scannedAt,
            icon: Icons.camera_alt_outlined,
            methodOrDest: 'Deteksi Kamera AI',
            weight: '${weightVal.toStringAsFixed(1)} kg',
            confidence: confVal,
            ecoPoints: (s['eco_points'] as num?)?.toInt() ?? 10,
          ),
        );
      }

      // Urutkan riwayat dari yang paling baru ke terlama
      converted.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (mounted) {
        setState(() {
          _dbTransactions = converted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions in HistoryScreen: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteTransaction(HistoryItemModel item) async {
    final bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hapus Riwayat?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data riwayat "${item.title}" (${item.id})? Data yang dihapus tidak dapat dipulihkan.',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (isConfirmed == true) {
      // 1. Delete from SQLite database
      if (item.type == HistoryType.deposit) {
        await DatabaseHelper.instance
            .deleteWastePickupByTransactionId(item.id);
      }

      // 2. Remove from local memory state
      setState(() {
        _dbTransactions.removeWhere((t) => t.id == item.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Riwayat ${item.id} berhasil dihapus.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateTransactionStatusToSelesai(HistoryItemModel item) async {
    try {
      await DatabaseHelper.instance.updatePickupStatusByTransactionId(
        item.id,
        'Selesai',
      );

      // Tambah saldo pengguna saat status setoran sampah berhasil diselesaikan
      double weightVal = 0.0;
      if (item.weight != null) {
        weightVal = double.tryParse(
                item.weight!.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
      }
      await DatabaseHelper.instance.creditUserBalance(
        amount: item.numericAmount,
        title: item.title,
        description: item.subtitle,
        transactionId: item.id,
        ecoPoints: (weightVal * 10).toInt(),
        weightKg: weightVal,
        channel: item.methodOrDest,
      );

      setState(() {
        _dbTransactions = _dbTransactions.map((t) {
          if (t.id == item.id) {
            return HistoryItemModel(
              id: t.id,
              title: t.title,
              subtitle: t.subtitle,
              amount: t.amount,
              numericAmount: t.numericAmount,
              isDeposit: t.isDeposit,
              type: t.type,
              status: 'Selesai',
              dateTime: t.dateTime,
              icon: t.icon,
              methodOrDest: t.methodOrDest,
              weight: t.weight,
              ratePerKg: t.ratePerKg,
              locationOrAccount: t.locationOrAccount,
            );
          }
          return t;
        }).toList();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Status deposit ${item.id} berhasil diperbarui menjadi Selesai & Saldo +${item.amount} ditambahkan!'),
          backgroundColor: const Color(0xFF0D6938),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  List<HistoryItemModel> get _allCombinedTransactions => _dbTransactions;

  List<HistoryItemModel> get _filteredTransactions {
    return _allCombinedTransactions.where((item) {
      // Type filtering
      if (_currentFilter == HistoryFilter.deposit &&
          item.type != HistoryType.deposit) {
        return false;
      }
      if (_currentFilter == HistoryFilter.withdrawal &&
          item.type != HistoryType.withdrawal) {
        return false;
      }
      if (_currentFilter == HistoryFilter.reward &&
          item.type != HistoryType.rewardRedemption) {
        return false;
      }
      if (_currentFilter == HistoryFilter.scan &&
          item.type != HistoryType.aiScan) {
        return false;
      }

      // Search filtering
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSubtitle = item.subtitle.toLowerCase().contains(query);
        final matchMethod = item.methodOrDest.toLowerCase().contains(query);
        final matchId = item.id.toLowerCase().contains(query);
        return matchTitle || matchSubtitle || matchMethod || matchId;
      }

      return true;
    }).toList();
  }

  double get _totalDepositReward {
    return _allCombinedTransactions
        .where((t) => t.type == HistoryType.deposit)
        .fold(0.0, (sum, t) => sum + t.numericAmount);
  }

  double get _totalWithdrawalAmount {
    return _allCombinedTransactions
        .where((t) => t.type == HistoryType.withdrawal)
        .fold(0.0, (sum, t) => sum + t.numericAmount);
  }

  int get _depositCount =>
      _allCombinedTransactions.where((t) => t.type == HistoryType.deposit).length;
  int get _withdrawalCount =>
      _allCombinedTransactions.where((t) => t.type == HistoryType.withdrawal).length;
  int get _rewardCount => _allCombinedTransactions
      .where((t) => t.type == HistoryType.rewardRedemption)
      .length;
  int get _scanCount =>
      _allCombinedTransactions.where((t) => t.type == HistoryType.aiScan).length;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0D6938),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text('$label berhasil disalin ke papan klip!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = _filteredTransactions;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Title & Summary Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat & Aktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semua setoran sampah, penarikan, voucher & scan AI tercatat otomatis',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_allCombinedTransactions.length} Total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6938),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Summary Mini Cards (Deposit vs Penarikan)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Deposit',
                  amount:
                      '+${DatabaseHelper.formatRupiah(_totalDepositReward, withSymbol: false)}',
                  unit: 'Rupiah',
                  count: '$_depositCount setoran',
                  icon: Icons.recycling,
                  color: const Color(0xFF0D6938),
                  bgColor: isDark
                      ? const Color(0xFF1E2822)
                      : const Color(0xFFEAF4EE),
                  isDark: isDark,
                  isSelected: _currentFilter == HistoryFilter.deposit,
                  onTap: () {
                    setState(() {
                      _currentFilter =
                          _currentFilter == HistoryFilter.deposit
                              ? HistoryFilter.all
                              : HistoryFilter.deposit;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Penarikan',
                  amount:
                      '-${DatabaseHelper.formatRupiah(_totalWithdrawalAmount, withSymbol: false)}',
                  unit: 'Rupiah',
                  count: '$_withdrawalCount penarikan',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF1565C0),
                  bgColor: isDark
                      ? const Color(0xFF1A2634)
                      : const Color(0xFFE3F2FD),
                  isDark: isDark,
                  isSelected: _currentFilter == HistoryFilter.withdrawal,
                  onTap: () {
                    setState(() {
                      _currentFilter =
                          _currentFilter == HistoryFilter.withdrawal
                              ? HistoryFilter.all
                              : HistoryFilter.withdrawal;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Cari aktivitas (setoran, voucher, bank, ID)...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Filter Tab Pills (Semua, Deposit, Penarikan, Tukar Poin, Scan AI)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua (${_allCombinedTransactions.length})',
                  icon: Icons.receipt_long_outlined,
                  filter: HistoryFilter.all,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Setor Sampah ($_depositCount)',
                  icon: Icons.recycling,
                  filter: HistoryFilter.deposit,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Penarikan Saldo ($_withdrawalCount)',
                  icon: Icons.account_balance_wallet_outlined,
                  filter: HistoryFilter.withdrawal,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Tukar Poin ($_rewardCount)',
                  icon: Icons.card_giftcard_rounded,
                  filter: HistoryFilter.reward,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Scan AI ($_scanCount)',
                  icon: Icons.camera_alt_outlined,
                  filter: HistoryFilter.scan,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Transaction List with RefreshIndicator
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0D6938),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF0D6938),
                    onRefresh: _loadDatabaseTransactions,
                    child: filteredList.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final item = filteredList[index];
                              return _buildHistoryCard(context, item, isDark);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required HistoryFilter filter,
    required bool isDark,
  }) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6938)
              : (isDark ? const Color(0xFF263229) : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D6938)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.grey.shade700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String amount,
    required String unit,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF263229) : bgColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white12 : color.withValues(alpha: 0.25)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white70 : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItemModel item,
    bool isDark,
  ) {
    Color cardAccentColor;
    String tagLabel;
    Color tagBgColor;

    switch (item.type) {
      case HistoryType.deposit:
        cardAccentColor = const Color(0xFF0D6938);
        tagLabel = 'Setor Sampah';
        tagBgColor = const Color(0xFF0D6938).withValues(alpha: 0.1);
        break;
      case HistoryType.withdrawal:
        cardAccentColor = const Color(0xFF1565C0);
        tagLabel = 'Penarikan Saldo';
        tagBgColor = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case HistoryType.rewardRedemption:
        cardAccentColor = const Color(0xFFE65100);
        tagLabel = 'Tukar Poin 🎁';
        tagBgColor = const Color(0xFFE65100).withValues(alpha: 0.12);
        break;
      case HistoryType.aiScan:
        cardAccentColor = const Color(0xFF6A1B9A);
        tagLabel = 'Scan Kamera AI';
        tagBgColor = const Color(0xFF6A1B9A).withValues(alpha: 0.12);
        break;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetail(context, item, isDark),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? cardAccentColor.withValues(alpha: 0.2)
                    : cardAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: cardAccentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Title, Subtitle, Method Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tagLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: cardAccentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.dateTime.split('T').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Amount, Status & Delete Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.amount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cardAccentColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final isPending =
                            item.status == 'Menunggu Penjemputan' ||
                                item.status == 'Diproses';
                        final statusColor = isPending
                            ? Colors.amber.shade900
                            : cardAccentColor;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                // Tombol Delete Riwayat
                InkWell(
                  onTap: () => _confirmDeleteTransaction(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String emptyTitle = 'Belum Ada Riwayat Aktivitas';
    String emptySubtitle =
        'Setiap penyetoran sampah, penarikan saldo, voucher belanja, dan scan AI akan otomatis tercatat rapi di sini.';
    IconData emptyIcon = Icons.receipt_long_outlined;

    switch (_currentFilter) {
      case HistoryFilter.deposit:
        emptyTitle = 'Belum Ada Riwayat Setor Sampah';
        emptySubtitle =
            'Mulai pilah sampah rumah tangga dan setorkan ke Drop Point atau panggil kurir penjemputan untuk raih saldo cuan!';
        emptyIcon = Icons.recycling;
        break;
      case HistoryFilter.withdrawal:
        emptyTitle = 'Belum Ada Riwayat Penarikan';
        emptySubtitle =
            'Penarikan saldo tunai ke rekening bank atau e-wallet (DANA, GoPay, OVO) akan muncul di sini.';
        emptyIcon = Icons.account_balance_wallet_outlined;
        break;
      case HistoryFilter.reward:
        emptyTitle = 'Belum Ada Penukaran Poin';
        emptySubtitle =
            'Tukarkan Eco-Points Anda dengan berbagai voucher belanja Alfamart, Indomaret, Pulsa, dan Token PLN!';
        emptyIcon = Icons.card_giftcard_rounded;
        break;
      case HistoryFilter.scan:
        emptyTitle = 'Belum Ada Riwayat Scan AI';
        emptySubtitle =
            'Gunakan fitur Kamera AI Deteksi Sampah untuk memindai sampah otomatis dan mengetahui estimasi nilainya.';
        emptyIcon = Icons.camera_alt_outlined;
        break;
      default:
        break;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263229)
                      : const Color(0xFFF4F8F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emptyIcon,
                  size: 44,
                  color: const Color(0xFF0D6938),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Tidak ada hasil yang sesuai dengan "$_searchQuery"'
                    : emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 20),
                if (_currentFilter == HistoryFilter.reward) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.card_giftcard, size: 18),
                    label: const Text(
                      'Tukar Poin Sekarang 🎁',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RewardRedemptionScreen(),
                        ),
                      ).then((_) => _loadDatabaseTransactions());
                    },
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6938),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Setor Sampah Sekarang',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      HomeTrashToCash.switchToTab(1);
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(
    BuildContext context,
    HistoryItemModel item,
    bool isDark,
  ) {
    final isPending = item.status == 'Menunggu Penjemputan' ||
        item.status == 'Diproses';

    Color detailColor;
    switch (item.type) {
      case HistoryType.deposit:
        detailColor = const Color(0xFF0D6938);
        break;
      case HistoryType.withdrawal:
        detailColor = const Color(0xFF1565C0);
        break;
      case HistoryType.rewardRedemption:
        detailColor = const Color(0xFFE65100);
        break;
      case HistoryType.aiScan:
        detailColor = const Color(0xFF6A1B9A);
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Icon & Status
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.amber.withValues(alpha: 0.15)
                            : detailColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending
                            ? Icons.hourglass_bottom_rounded
                            : item.icon,
                        color: isPending ? Colors.amber.shade900 : detailColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.amount,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.amber.shade900 : detailColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Details Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263229)
                      : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'ID Transaksi',
                      item.id,
                      isDark,
                      isHighlight: true,
                      onTapValue: () =>
                          _copyToClipboard(item.id, 'ID Transaksi'),
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Tanggal & Waktu',
                      item.dateTime.replaceAll('T', ' ').split('.').first,
                      isDark,
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Kategori Aktivitas',
                      _getTypeLabel(item.type),
                      isDark,
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      item.type == HistoryType.deposit
                          ? 'Metode Penyerahan'
                          : 'Metode / Channel',
                      item.methodOrDest,
                      isDark,
                    ),
                    if (item.weight != null) ...[
                      const Divider(height: 16),
                      _buildDetailRow('Berat Sampah', item.weight!, isDark),
                    ],
                    if (item.ratePerKg != null) ...[
                      const Divider(height: 16),
                      _buildDetailRow('Tarif Satuan', item.ratePerKg!, isDark),
                    ],
                    if (item.ecoPoints != null && item.ecoPoints! > 0) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Poin Eco Hero',
                        item.type == HistoryType.rewardRedemption
                            ? '-${item.ecoPoints} Poin'
                            : '+${item.ecoPoints} Poin Eco 🌿',
                        isDark,
                        isHighlight: true,
                      ),
                    ],
                    if (item.type == HistoryType.deposit) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Biaya Layanan / Ongkir',
                        'GRATIS (Promo Bebas Biaya)',
                        isDark,
                        isSuccess: true,
                      ),
                    ],
                    if (item.voucherCode != null) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Kode Voucher',
                        item.voucherCode!,
                        isDark,
                        isHighlight: true,
                        onTapValue: () => _copyToClipboard(
                            item.voucherCode!, 'Kode Voucher'),
                      ),
                    ],
                    if (item.locationOrAccount != null) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        item.type == HistoryType.deposit
                            ? (item.methodOrDest.toLowerCase().contains('jemput')
                                ? 'Alamat Penjemputan'
                                : 'Lokasi Drop Point')
                            : (item.type == HistoryType.withdrawal
                                ? 'Tujuan Rekening'
                                : 'Keterangan'),
                        item.locationOrAccount!,
                        isDark,
                      ),
                    ],
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Status',
                      item.status,
                      isDark,
                      isSuccess: !isPending,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (item.type == HistoryType.deposit) ...[
                // Deposit Special Action Buttons
                if (isPending &&
                    item.methodOrDest.toLowerCase().contains('jemput')) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: const Text(
                        'Pantau Kurir Penjemputan 🛵',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickupStatusScreen(
                              categoryName: item.title.replaceAll('Deposit ', ''),
                              weightKg: item.weight != null
                                  ? (double.tryParse(item.weight!
                                          .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                      2.5)
                                  : 2.5,
                              estimatedReward: item.numericAmount,
                              ecoPoints: item.ecoPoints,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else if (item.methodOrDest.toLowerCase().contains('drop')) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text(
                        'Lihat Lokasi Drop Point 📍',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DropPointLocationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.recycling, size: 18),
                      label: const Text(
                        'Setor Sampah Lagi ♻️',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        HomeTrashToCash.switchToTab(1);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D6938),
                          side: const BorderSide(color: Color(0xFF0D6938)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text(
                          'Salin Bukti',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          final text = '''
🧾 BUKTI TRANSAKSI SETOR SAMPAH - TRASHTOCASH
--------------------------------------------
ID Transaksi : ${item.id}
Tanggal      : ${item.dateTime.replaceAll('T', ' ').split('.').first}
Jenis Sampah : ${item.title}
Metode       : ${item.methodOrDest}
Lokasi       : ${item.locationOrAccount ?? '-'}
Berat        : ${item.weight ?? '-'}
Tarif        : ${item.ratePerKg ?? '-'}
Total Reward : ${item.amount}
Poin Eco     : +${item.ecoPoints ?? 0} Poin
Status       : ${item.status}
--------------------------------------------
Terima kasih telah berkontribusi menjaga bumi bersama TrashToCash! 🌱
''';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Bukti transaksi disalin ke clipboard! 📋'),
                              backgroundColor: Color(0xFF0D6938),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteTransaction(item);
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (item.type == HistoryType.rewardRedemption) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D6938),
                          side: const BorderSide(color: Color(0xFF0D6938)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Kode'),
                        onPressed: () {
                          if (item.voucherCode != null) {
                            _copyToClipboard(item.voucherCode!, 'Kode Voucher');
                          } else {
                            _copyToClipboard(item.id, 'ID Transaksi');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6938),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.confirmation_number_outlined,
                            color: Colors.white, size: 16),
                        label: const Text(
                          'Buka Voucher',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyVouchersScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteTransaction(item);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPending) ...[
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6938),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Update Selesai',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateTransactionStatusToSelesai(item);
                          },
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6938),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(HistoryType type) {
    switch (type) {
      case HistoryType.deposit:
        return 'Setoran / Penjualan Sampah';
      case HistoryType.withdrawal:
        return 'Penarikan Saldo Tunai';
      case HistoryType.rewardRedemption:
        return 'Penukaran Eco-Points (Voucher Belanja)';
      case HistoryType.aiScan:
        return 'Deteksi AI Kamera';
    }
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
    bool isSuccess = false,
    VoidCallback? onTapValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onTapValue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isHighlight || isSuccess
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSuccess
                          ? const Color(0xFF0D6938)
                          : (isHighlight
                              ? const Color(0xFF0D6938)
                              : (isDark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
                if (onTapValue != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy_rounded,
                    size: 12,
                    color: Color(0xFF0D6938),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
