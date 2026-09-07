import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/models/reward_item_model.dart';
import 'package:trashtocash/screens/reward_redemption_screen.dart';

class MyVouchersScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyVouchersScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RedeemedVoucher> _allVouchers = [];
  bool _isLoading = true;
  String _userEmail = 'user@email.com';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ??
          prefs.getString('userEmail') ??
          prefs.getString('registeredEmail') ??
          'user@email.com';
      _userEmail = email;

      final list = await DatabaseHelper.instance.getUserRedeemedRewards(email);
      if (mounted) {
        setState(() {
          _allVouchers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<RedeemedVoucher> _filterVouchers(int tabIndex) {
    switch (tabIndex) {
      case 0: // Aktif (Tersedia)
        return _allVouchers.where((v) => v.isActive).toList();
      case 1: // Semua
        return _allVouchers;
      case 2: // Terpakai
        return _allVouchers.where((v) => v.isUsed).toList();
      case 3: // Kedaluwarsa
        return _allVouchers.where((v) => v.isExpired && !v.isUsed).toList();
      default:
        return _allVouchers;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0D6938),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label berhasil disalin ke papan klip!',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAsUsed(RedeemedVoucher voucher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF0D6938)),
              SizedBox(width: 8),
              Text('Gunakan Voucher?', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menandai voucher "${voucher.title}" ini sudah dipakai di kasir / merchant?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya, Sudah Dipakai',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseHelper.instance
          .markRedeemedVoucherAsUsed(voucher.id, _userEmail);
      HapticFeedback.mediumImpact();
      _loadVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0D6938),
            content: Text('Status voucher diperbarui menjadi: Sudah Dipakai'),
          ),
        );
      }
    }
  }

  void _showVoucherDetailModal(RedeemedVoucher voucher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.88,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
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

                        // Header modal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: voucher.statusColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      voucher.statusLabel,
                                      style: TextStyle(
                                        color: voucher.statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    voucher.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Merchant: ${voucher.merchant}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Barcode & QR Code Card (Ticket Style)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF263229)
                                : const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'KODE VOUCHER RESMI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Voucher Code Box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF0D6938)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        voucher.voucherCode,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                          color: Color(0xFF0D6938),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _copyToClipboard(
                                          voucher.voucherCode, 'Kode voucher'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D6938),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.copy_rounded,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Salin',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Simulated Barcode Graphic
                              _buildBarcodeGraphic(voucher.barcode, isDark),
                              const SizedBox(height: 6),
                              Text(
                                voucher.barcode,
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Target Account Info if any (e.g. GoPay / PLN ID)
                              if (voucher.targetAccount != null &&
                                  voucher.targetAccount!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D6938)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 16, color: Color(0xFF0D6938)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Nomor / ID Tujuan: ${voucher.targetAccount}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D6938),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // Expiry Notice
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: voucher.isExpired
                                        ? Colors.red
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    voucher.isExpired
                                        ? 'Telah kedaluwarsa'
                                        : 'Berlaku s/d: ${_formatDate(voucher.expiresAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: voucher.isExpired
                                          ? Colors.red
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Cara Menggunakan Voucher
                        const Text(
                          'Cara Menggunakan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Text(
                            voucher.instructions ??
                                'Tunjukkan barcode atau masukkan kode voucher saat melakukan transaksi di kasir / aplikasi merchant.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Syarat & Ketentuan
                        if (voucher.terms != null && voucher.terms!.isNotEmpty) ...[
                          const Text(
                            'Syarat & Ketentuan',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ),
                            child: Text(
                              voucher.terms!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Action Buttons
                        if (voucher.isActive) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _markAsUsed(voucher);
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 18, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6938),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: const Text(
                                'Tandai Sudah Dipakai',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                voucher.isUsed
                                    ? 'Voucher ini telah digunakan pada: ${_formatDate(voucher.usedAt ?? voucher.redeemedAt)}'
                                    : 'Voucher telah melewati batas masa berlaku.',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBarcodeGraphic(String code, bool isDark) {
    // Generate realistic looking vertical barcode stripes
    final bars = <Widget>[];
    for (int i = 0; i < 48; i++) {
      final isThick = i % 3 == 0 || i % 7 == 0;
      final isSpace = i % 5 == 0 && i % 2 == 0;
      if (!isSpace) {
        bars.add(
          Container(
            width: isThick ? 3.0 : 1.8,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            color: isDark ? Colors.white : Colors.black87,
          ),
        );
      } else {
        bars.add(const SizedBox(width: 3));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: bars,
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Voucher & Hadiah Saya',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D6938),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadVouchers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Tersedia'),
            Tab(text: 'Semua'),
            Tab(text: 'Terpakai'),
            Tab(text: 'Kedaluwarsa'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D6938)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVoucherList(0, isDark),
                _buildVoucherList(1, isDark),
                _buildVoucherList(2, isDark),
                _buildVoucherList(3, isDark),
              ],
            ),
    );
  }

  Widget _buildVoucherList(int tabIndex, bool isDark) {
    final list = _filterVouchers(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: Color(0xFF0D6938),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tabIndex == 0
                    ? 'Belum Ada Voucher Aktif'
                    : 'Tidak Ada Voucher Ditemukan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tabIndex == 0
                    ? 'Tukarkan Eco-Points hasil daur ulang sampah Anda dengan voucher belanja Alfamart, Indomaret, Pulsa & PLN.'
                    : 'Riwayat voucher akan muncul di sini setelah Anda melakukan penukaran poin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RewardRedemptionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.card_giftcard, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6938),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Tukar Poin Sekarang 🎁',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVouchers,
      color: const Color(0xFF0D6938),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final voucher = list[index];
          return _buildVoucherCard(voucher, isDark);
        },
      ),
    );
  }

  Widget _buildVoucherCard(RedeemedVoucher voucher, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: voucher.isActive
              ? const Color(0xFF0D6938).withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showVoucherDetailModal(voucher),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Merchant & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        voucher.merchant,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: voucher.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      voucher.statusLabel,
                      style: TextStyle(
                        color: voucher.statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Value
              Text(
                voucher.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Voucher Code Row with copy button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 16, color: Color(0xFF0D6938)),
                        const SizedBox(width: 6),
                        Text(
                          voucher.voucherCode,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () =>
                          _copyToClipboard(voucher.voucherCode, 'Kode voucher'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Salin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Expiry & Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Berlaku s/d: ${_formatDate(voucher.expiresAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: voucher.isExpired ? Colors.red : Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        voucher.isActive ? 'Lihat Barcode' : 'Detail',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF0D6938),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
