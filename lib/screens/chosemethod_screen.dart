import 'package:flutter/material.dart';
import 'package:trashtocash/screens/scan_sampah_screen.dart';

class MenyerahkanSampah extends StatefulWidget {
  final bool isStandalone;

  const MenyerahkanSampah({
    super.key,
    this.isStandalone = false,
  });

  @override
  State<MenyerahkanSampah> createState() => _MenyerahkanSampahState();
}

class _MenyerahkanSampahState extends State<MenyerahkanSampah> {
  int _selectedMethod = 0; // 0 = Jemput Sampah, 1 = Drop-off Mandiri

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = widget.isStandalone || (ModalRoute.of(context)?.canPop ?? false);

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Hero Badge & Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2822), const Color(0xFF17201B)]
                    : [const Color(0xFFEAF4EE), const Color(0xFFF4F9F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0D6938).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6938).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 10,
                                  color: Color(0xFF0D6938),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Smart Waste Deposit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6938),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Setor Sampah Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0D6938),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ubah sampah terpilah menjadi saldo T-Cash dan kumpulkan poin reward.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Section Title
          Text(
            'Pilih Cara Penyerahan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tentukan metode yang paling praktis dan nyaman untuk Anda.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),

          // 3. Option 1: Jemput Sampah ke Lokasi (Kurir)
          _buildMethodCard(
            context: context,
            index: 0,
            title: 'Jemput Sampah ke Rumah',
            subtitle:
                'Mitra kurir TrashToCash akan datang langsung ke alamat Anda untuk menimbang sampah di tempat.',
            icon: Icons.local_shipping_rounded,
            tag1: 'Dijadwalkan',
            tag2: 'Bebas Repot',
            tag3: 'Promo Gratis Ongkir',
            bullets: [
              'Cocok untuk sampah berat, kardus banyak, atau perabotan daur ulang',
              'Penimbangan langsung di tempat & saldo T-Cash cair seketika',
              'Lacak posisi armada kurir di peta real-time via aplikasi',
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // 4. Option 2: Drop-off Mandiri ke Drop Point
          _buildMethodCard(
            context: context,
            index: 1,
            title: 'Drop-off Mandiri ke Drop Point',
            subtitle:
                'Antar langsung sampah pilahan Anda ke Drop Point / Bank Sampah TrashToCash terdekat.',
            icon: Icons.storefront_rounded,
            tag1: 'Proses Cepat',
            tag2: '15+ Titik Drop Point',
            tag3: '+Bonus Poin Eco 🌿',
            bullets: [
              'Bisa datang kapan saja sesuai jam operasional Drop Point',
              'Verifikasi barcode otomatis di lokasi & saldo langsung bertambah',
              'Dapatkan ekstra bonus Eco-Points setiap kali drop-off',
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // 5. Tips Daur Ulang Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF263229)
                  : const Color(0xFFF0F7F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0D6938).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFF0D6938),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tips Daur Ulang Maksimal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6938),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pastikan sampah daur ulang dalam keadaan bersih, tidak basah berlebih, dan sudah terpilah sesuai jenisnya (Plastik, Kertas, Organik) untuk mendapatkan penaksiran harga terbaik.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6938),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF0D6938).withValues(alpha: 0.4),
              ),
              icon: Icon(
                _selectedMethod == 0
                    ? Icons.local_shipping
                    : Icons.location_on,
                size: 20,
              ),
              label: Text(
                _selectedMethod == 0
                    ? 'Lanjutkan Penjemputan Kurir'
                    : 'Lanjutkan Drop-off Mandiri',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanSampahScreen(
                      isPickup: _selectedMethod == 0,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (canPop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D6938),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pilih Metode Setor Sampah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required String tag1,
    required String tag2,
    required String tag3,
    required List<String> bullets,
    required bool isDark,
  }) {
    final isSelected = _selectedMethod == index;
    const activeColor = Color(0xFF0D6938);

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E2A21) : const Color(0xFFF2F9F4))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : (isDark
                            ? const Color(0xFF2A362D)
                            : const Color(0xFFEAF4EE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : activeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Radio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: activeColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tag Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTag(context, Icons.check_circle_outline, tag1, isDark),
                  const SizedBox(width: 6),
                  _buildTag(context, Icons.bolt_rounded, tag2, isDark),
                  const SizedBox(width: 6),
                  _buildTag(context, Icons.verified_outlined, tag3, isDark),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Bullet points
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.fiber_manual_record,
                        size: 6,
                        color: activeColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263229) : const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF0D6938)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF0D6938),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
