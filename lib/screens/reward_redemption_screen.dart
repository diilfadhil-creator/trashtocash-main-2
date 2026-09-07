import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/sound_helper.dart';
import 'package:trashtocash/models/reward_item_model.dart';
import 'package:trashtocash/models/user_level_model.dart';
import 'package:trashtocash/screens/my_vouchers_screen.dart';
import 'package:trashtocash/widgets/user_level_sheet.dart';

class RewardRedemptionScreen extends StatefulWidget {
  final RewardCategory? initialCategory;

  const RewardRedemptionScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<RewardRedemptionScreen> createState() => _RewardRedemptionScreenState();
}

class _RewardRedemptionScreenState extends State<RewardRedemptionScreen> {
  RewardCategory _selectedCategory = RewardCategory.all;
  String _searchQuery = '';
  bool _filterOnlyAffordable = false;
  String? _quickFilter; // null, 'popular', 'cheap'
  final TextEditingController _searchController = TextEditingController();

  String _userEmail = 'user@email.com';
  String _userPhone = '';
  int _activeVouchersCount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadUserContext();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ??
          prefs.getString('userEmail') ??
          prefs.getString('registeredEmail') ??
          'user@email.com';
      final phone = prefs.getString('phone') ??
          prefs.getString('ewalletNumber') ??
          '';

      _userEmail = email;
      _userPhone = phone;

      // Sync wallet points
      await DatabaseHelper.instance.syncUserWalletFromDb(email);

      // Load active vouchers count
      final count = await DatabaseHelper.instance.getActiveVouchersCount(email);
      if (mounted) {
        setState(() {
          _activeVouchersCount = count;
        });
      }
    } catch (_) {}
  }

  List<RewardItem> _getFilteredRewards(int currentPoints) {
    var list = RewardItem.defaultCatalog;

    // 1. Filter by category
    if (_selectedCategory != RewardCategory.all) {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    // 2. Filter by search
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((r) {
        return r.title.toLowerCase().contains(query) ||
            r.merchant.toLowerCase().contains(query) ||
            r.nominalValue.toLowerCase().contains(query) ||
            r.description.toLowerCase().contains(query);
      }).toList();
    }

    // 3. Filter only affordable
    if (_filterOnlyAffordable) {
      list = list.where((r) => currentPoints >= r.pointsCost).toList();
    }

    // 4. Quick filter: Populer / Termurah
    if (_quickFilter == 'popular') {
      list = list.where((r) => r.badge != null && (r.badge!.contains('Terlaris') || r.badge!.contains('Populer') || r.badge!.contains('Instan'))).toList();
    } else if (_quickFilter == 'cheap') {
      list = list.where((r) => r.pointsCost <= 50).toList();
    }

    return list;
  }

  void _showRedeemConfirmationSheet(RewardItem reward, int currentPoints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAffordable = currentPoints >= reward.pointsCost;
    final remainingPoints = currentPoints - reward.pointsCost;
    final targetController = TextEditingController(text: _userPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle Bar
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

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: reward.brandColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  reward.icon,
                                  color: reward.brandColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reward.merchant,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: reward.brandColor,
                                    ),
                                  ),
                                  const Text(
                                    'Konfirmasi Penukaran Poin',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Reward Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward.description,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Points Calculation Row
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('Eco-Points Anda Saat Ini',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ),
                                Text(
                                  '$currentPoints Poin',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('Biaya Penukaran Voucher',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ),
                                Text(
                                  '-${reward.pointsCost} Poin',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('Sisa Eco-Points Setelah Tukar',
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                Text(
                                  isAffordable
                                      ? '$remainingPoints Poin'
                                      : 'Kurang ${reward.pointsCost - currentPoints} Poin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isAffordable
                                        ? const Color(0xFF0D6938)
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Target Input (For E-wallet / Pulsa / PLN)
                      if (reward.requiresTargetInput) ...[
                        Text(
                          reward.targetInputLabel ?? 'Nomor Tujuan',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: targetController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: reward.targetInputHint ?? 'Masukkan nomor tujuan',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            prefixIcon: const Icon(Icons.phone_android,
                                size: 18, color: Color(0xFF0D6938)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Syarat & Ketentuan Preview
                      const Text(
                        'Syarat & Ketentuan Ringkas:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...reward.terms.take(2).map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 11)),
                                  Expanded(
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 18),

                      // CTA Button
                      if (isAffordable) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () async {
                                    final target = targetController.text.trim();
                                    if (reward.requiresTargetInput && target.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.redAccent,
                                          content: Text('Harap isi nomor tujuan / ID pelanggan!'),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(sheetContext);
                                    await _processRedemption(reward, target);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6938),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Tukar Sekarang (${reward.pointsCost} Poin) 🎁',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Poin Anda belum cukup. Kumpulkan ${reward.pointsCost - currentPoints} Eco-Points lagi dengan menyetor sampah daur ulang!',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processRedemption(RewardItem reward, String? targetAccount) async {
    setState(() => _isProcessing = true);
    try {
      final result = await DatabaseHelper.instance.redeemEcoPointsReward(
        userEmail: _userEmail,
        reward: reward,
        targetAccount: targetAccount,
      );

      if (result['success'] == true) {
        final RedeemedVoucher voucher = result['voucher'] as RedeemedVoucher;
        await SoundHelper.playCoinSound();
        _loadUserContext();

        if (mounted) {
          _showSuccessCelebrationDialog(reward, voucher);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
              content: Text(result['message'] as String? ?? 'Gagal menukar poin.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            content: Text('Terjadi kesalahan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessCelebrationDialog(
      RewardItem reward, RedeemedVoucher voucher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Icon Animation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF0D6938),
                  size: 48,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Penukaran Berhasil! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6938),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Voucher "${reward.title}" berhasil diklaim dan siap digunakan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Voucher Code Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KODE VOUCHER ANDA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.voucherCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6938),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVouchersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.confirmation_number_outlined,
                      size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6938),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  label: const Text(
                    'Buka di Voucher Saya',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Lanjut Belanja Voucher',
                  style: TextStyle(
                    color: Color(0xFF0D6938),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tukar Poin & Hadiah',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D6938),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Shortcut to My Vouchers with active count badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.confirmation_number_outlined),
                tooltip: 'Voucher Saya',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyVouchersScreen(),
                    ),
                  ).then((_) => _loadUserContext());
                },
              ),
              if (_activeVouchersCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeVouchersCount',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: DatabaseHelper.userEcoPointsNotifier,
        builder: (context, currentEcoPoints, _) {
          final progression = UserLevelProgression.fromStats(
            points: currentEcoPoints,
            totalKg: 0.0,
          );
          final tier = progression.currentTier;
          final rewards = _getFilteredRewards(currentEcoPoints);

          return Column(
            children: [
              // Hero Points Header Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D6938),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saldo Eco-Points Anda',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: Color(0xFFFFD700), size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  '$currentEcoPoints Poin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // User Level Badge
                        InkWell(
                          onTap: () => UserLevelSheet.show(context, totalKg: 0.0),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tier.icon, color: Colors.white, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  tier.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right,
                                    color: Colors.white70, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Cari voucher belanja, e-wallet, pulsa...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF0D6938), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Bar (Horizontal)
              Container(
                height: 48,
                margin: const EdgeInsets.only(top: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: RewardCategory.values.length,
                  itemBuilder: (context, index) {
                    final cat = RewardCategory.values[index];
                    final isSelected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0D6938),
                            ),
                            const SizedBox(width: 5),
                            Text(cat.shortLabel),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0D6938),
                        backgroundColor: isDark
                            ? const Color(0xFF263229)
                            : const Color(0xFFEAF4EE),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF0D6938)
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Quick Filter Toggle Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Only affordable toggle
                    FilterChip(
                      label: Text(
                        'Poin Cukup (${_calculateAffordableCount(currentEcoPoints)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _filterOnlyAffordable
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _filterOnlyAffordable
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: _filterOnlyAffordable,
                      selectedColor: const Color(0xFF0D6938),
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark
                          ? const Color(0xFF263229)
                          : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        setState(() {
                          _filterOnlyAffordable = val;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Popular
                    FilterChip(
                      label: Text(
                        'Populer 🔥',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _quickFilter == 'popular'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _quickFilter == 'popular'
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: _quickFilter == 'popular',
                      selectedColor: const Color(0xFF0D6938),
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark
                          ? const Color(0xFF263229)
                          : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        setState(() {
                          _quickFilter = val ? 'popular' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Cheap (< 50 points)
                    FilterChip(
                      label: Text(
                        '≤ 50 Poin ⚡',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _quickFilter == 'cheap'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _quickFilter == 'cheap'
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: _quickFilter == 'cheap',
                      selectedColor: const Color(0xFF0D6938),
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark
                          ? const Color(0xFF263229)
                          : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        setState(() {
                          _quickFilter = val ? 'cheap' : null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Reward Cards Grid
              Expanded(
                child: rewards.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak Ada Hadiah yang Cocok',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba sesuaikan kata kunci pencarian atau matikan filter filter aktif.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedCategory = RewardCategory.all;
                                    _filterOnlyAffordable = false;
                                    _quickFilter = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D6938),
                                  side: const BorderSide(
                                      color: Color(0xFF0D6938)),
                                ),
                                child: const Text('Reset Semua Filter'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUserContext,
                        color: const Color(0xFF0D6938),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            final isAffordable =
                                currentEcoPoints >= reward.pointsCost;
                            return _buildRewardCard(
                                reward, isAffordable, currentEcoPoints, isDark);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _calculateAffordableCount(int points) {
    return RewardItem.defaultCatalog
        .where((r) => points >= r.pointsCost)
        .length;
  }

  Widget _buildRewardCard(
    RewardItem reward,
    bool isAffordable,
    int currentPoints,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAffordable
              ? const Color(0xFF0D6938).withValues(alpha: 0.25)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isAffordable ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAffordable
                ? const Color(0xFF0D6938).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRedeemConfirmationSheet(reward, currentPoints),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Brand Icon, Merchant Name, Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reward.brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          reward.icon,
                          color: reward.brandColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.merchant,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: reward.brandColor,
                            ),
                          ),
                          Text(
                            reward.category.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (reward.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        reward.badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB78103),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                reward.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                reward.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Points Cost, Value, and Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Points Cost Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            size: 14, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.pointsCost} Eco-Points',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button / Status Pill
                  ElevatedButton(
                    onPressed: () =>
                        _showRedeemConfirmationSheet(reward, currentPoints),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAffordable
                          ? const Color(0xFF0D6938)
                          : Colors.grey.shade300,
                      foregroundColor:
                          isAffordable ? Colors.white : Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isAffordable
                          ? 'Tukar Hadiah 🎁'
                          : 'Kurang ${reward.pointsCost - currentPoints} Poin',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isAffordable ? Colors.white : Colors.black87,
                      ),
                    ),
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
