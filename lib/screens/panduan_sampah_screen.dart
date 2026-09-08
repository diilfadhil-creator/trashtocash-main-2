import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/screens/live_camera_scan_screen.dart';
import 'package:trashtocash/screens/scan_sampah_screen.dart';

class PanduanDaurUlangScreen extends StatefulWidget {
  final int initialTabIndex;

  const PanduanDaurUlangScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<PanduanDaurUlangScreen> createState() => _PanduanDaurUlangScreenState();
}

class _PanduanDaurUlangScreenState extends State<PanduanDaurUlangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WasteItemModel> _organicItems = [];
  List<WasteItemModel> _nonOrganicItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _loadWasteCatalog();
  }

  Future<void> _loadWasteCatalog() async {
    try {
      final items = await DatabaseHelper.instance.getAllWasteItems();
      if (items.isNotEmpty && mounted) {
        setState(() {
          _organicItems = items.where((item) => item.isOrganic).toList();
          _nonOrganicItems = items.where((item) => !item.isOrganic).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading waste catalog for guide: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Panduan Daur Ulang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.camera_alt_outlined, size: 20),
              text: 'Scan Foto AI',
            ),
            Tab(
              icon: Icon(Icons.eco, size: 20),
              text: 'Organik',
            ),
            Tab(
              icon: Icon(Icons.recycling, size: 20),
              text: 'Non-Organik',
            ),
            Tab(
              icon: Icon(Icons.help_outline, size: 20),
              text: 'FAQ & Tips 3R',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScanPhotoGuideTab(isDark),
          _buildOrganicGuideTab(isDark),
          _buildNonOrganicGuideTab(isDark),
          _buildFaqAndTipsTab(isDark),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PANDUAN LENGKAP FITUR SCAN FOTO AI
  // ===========================================================================
  Widget _buildScanPhotoGuideTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner Fitur Scan Foto AI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6938), Color(0xFF198754)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                  blurRadius: 12,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: Colors.black87),
                          SizedBox(width: 4),
                          Text(
                            'AI Vision 2.0',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.camera_enhance,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Deteksi Sampah Otomatis\nHanya dengan Foto 📸',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Teknologi kecerdasan buatan TrashToCash mengenali jenis material, menghitung estimasi nilai rupiah, serta memberikan tips daur ulang langsung dari kamera ponsel Anda.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScanSampahScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF0D6938)),
                  label: const Text(
                    'Coba Scan Foto Sekarang',
                    style: TextStyle(
                      color: Color(0xFF0D6938),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Header Cara Penggunaan
          const Text(
            '5 Langkah Mudah Menggunakan Fitur Scan Foto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ikuti alur praktis berikut untuk mendeteksi sampah dan mendapatkan saldo instan.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Step 1
          _buildStepCard(
            stepNumber: '1',
            title: 'Siapkan & Bersihkan Sampah',
            description:
                'Pastikan sampah dalam keadaan kering dan terpisah. Untuk botol plastik, buang sisa cairan, lepas tutup & label. Untuk kardus, lipat hingga pipih.',
            icon: Icons.cleaning_services_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Step 2
          _buildStepCard(
            stepNumber: '2',
            title: 'Buka Menu Scan / Setor Sampah',
            description:
                'Pilih opsi "Setor" pada halaman beranda, atau klik tombol "Scan Sampah". Anda dapat memilih metode Drop-off ke Bank Sampah atau Jemput Kurir.',
            icon: Icons.qr_code_scanner,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Step 3
          _buildStepCard(
            stepNumber: '3',
            title: 'Arahkan Kamera ke Sampah (Viewfinder)',
            description:
                'Posisikan barang sampah tepat di dalam kotak target hijau. Pastikan pencahayaan cukup terang. Nyalakan fitur Flash jika berada di ruangan gelap.',
            icon: Icons.center_focus_strong,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Step 4
          _buildStepCard(
            stepNumber: '4',
            title: 'AI Mendeteksi Kategori & Nilai Otomatis',
            description:
                'Sistem AI TrashToCash akan menganalisis objek foto dalam hitungan detik. Kategori (Organik/Non-Organik), jenis material, tarif Rupiah/kg, dan EcoPoints akan otomatis terpilih.',
            icon: Icons.psychology_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Step 5
          _buildStepCard(
            stepNumber: '5',
            title: 'Atur Berat & Lanjutkan Transaksi',
            description:
                'Sesuaikan estimasi berat sampah (kg) dengan tombol (+/-), periksa ringkasan reward, lalu klik "Lanjut ke Detail Transaksi" untuk menyelesaikan setoran.',
            icon: Icons.check_circle_outline,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Do's and Don'ts Section
          const Text(
            'Panduan Hasil Foto Terbaik (Tips & Trik)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDoDontItem(
                  isDo: true,
                  text: 'Gunakan pencahayaan terang alami atau nyalakan flash bawaan.',
                ),
                const Divider(height: 16),
                _buildDoDontItem(
                  isDo: true,
                  text: 'Foto 1 jenis sampah per sesi deteksi agar akurasi AI maksimal (98%+).',
                ),
                const Divider(height: 16),
                _buildDoDontItem(
                  isDo: true,
                  text: 'Pastikan objek tidak blur dan fokus di dalam bingkai viewfinder.',
                ),
                const Divider(height: 16),
                _buildDoDontItem(
                  isDo: false,
                  text: 'Hindari memfoto sampah bercampur di dalam kantong kresek hitam tertutup.',
                ),
                const Divider(height: 16),
                _buildDoDontItem(
                  isDo: false,
                  text: 'Hindari bayangan gelap pekat atau silau pantulan cahaya berlebih.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Action Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2C21) : const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0D6938).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6938),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punya Sampah Menumpuk?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Foto sekarang juga untuk mengubah limbah rumah Anda menjadi saldo rupiah nyata!',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PANDUAN SAMPAH ORGANIK
  // ===========================================================================
  Widget _buildOrganicGuideTab(bool isDark) {
    final defaultOrganics = [
      {
        'name': 'Sisa Makanan & Dapur',
        'sample': 'Sisa nasi, sayur matang basi, lauk pauk, mie & roti',
        'rate': 4.0,
        'points': 10,
        'icon': Icons.compost,
        'image':
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Diolah jadi biokonversi larva Maggot BSF & pupuk organik cair super.',
        'tips': 'Tiriskan air kuah dan buang plastik pembungkus/steples.',
      },
      {
        'name': 'Kulit Buah & Potongan Sayur Segar',
        'sample': 'Kulit pisang, jeruk, pepaya, sisa wortel, sawi & kangkung',
        'rate': 4.5,
        'points': 12,
        'icon': Icons.eco,
        'image':
            'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Bahan fermentasi Eco-Enzyme serbaguna & pembersih alami.',
        'tips': 'Pisahkan dari stiker buah plastik, tali rafia, atau karet.',
      },
      {
        'name': 'Daun Kering, Ranting & Rumput Kebun',
        'sample': 'Daun gugur cokelat, ranting kering taman, tebasan rumput',
        'rate': 3.0,
        'points': 8,
        'icon': Icons.energy_savings_leaf,
        'image':
            'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Kaya unsur karbon (C) tinggi untuk bahan dasar kompos padat humus.',
        'tips': 'Kumpulkan dalam karung terikat rapi dalam kondisi kering.',
      },
      {
        'name': 'Minyak Jelantah (Bekas Goreng)',
        'sample': 'Minyak goreng bekas dapur warna cokelat/bening tersaring',
        'rate': 6.5,
        'points': 18,
        'icon': Icons.water_drop_outlined,
        'image':
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Bahan baku energi terbarukan biodiesel ramah lingkungan.',
        'tips': 'Saring remahan gorengan, tampung dalam jerigen/botol tertutup rapat.',
      },
      {
        'name': 'Ampas Kopi & Daun Teh',
        'sample': 'Ampas seduhan kopi murni, teh tubruk / kantong teh basah',
        'rate': 5.0,
        'points': 15,
        'icon': Icons.coffee_outlined,
        'image':
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Sumber nitrogen penyubur tanaman pot dan pengusir hama semut.',
        'tips': 'Peras/tiriskan air berlebih agar tidak mudah berjamur tebal.',
      },
      {
        'name': 'Cangkang Telur & Limbah Halus',
        'sample': 'Cangkang telur ayam/bebek kering remuk & serbuk kelapa',
        'rate': 3.5,
        'points': 10,
        'icon': Icons.egg_outlined,
        'image':
            'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Kaya kalsium karbonat penyeimbang pH tanah asam.',
        'tips': 'Bilas lendir sisa putih telur dan remas kasar agar hemat wadah.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Intro Card Organik
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0D6938).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco, color: Color(0xFF0D6938), size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apa itu Sampah Organik?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sampah organik adalah limbah yang berasal dari makhluk hidup dan dapat terurai secara hayati (biodegradable). Memilahnya mencegah bau busuk dan menghasilkan kompos bergizi.',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Kategori Sampah Organik yang Diterima',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D6938)),
            ),
          )
        else if (_organicItems.isNotEmpty)
          ..._organicItems.map((item) {
            return _buildCategoryDetailCard(
              title: item.name,
              sample: item.sampleItem,
              rate: item.ratePerKg.toStringAsFixed(1),
              points: item.ecoPoints.toString(),
              benefit: item.description.isNotEmpty
                  ? item.description
                  : 'Daur ulang dan olah menjadi produk ramah lingkungan berharga.',
              tips: item.handlingTip.isNotEmpty
                  ? item.handlingTip
                  : 'Bersihkan dan tiriskan sebelum disetor.',
              imageUrl: item.imageUrl,
              icon: item.icon,
              badgeColor: const Color(0xFF0D6938),
              badgeText: 'Organik',
              isDark: isDark,
            );
          })
        else
          ...defaultOrganics.map((item) {
            return _buildCategoryDetailCard(
              title: item['name'] as String,
              sample: item['sample'] as String,
              rate: (item['rate'] as double).toStringAsFixed(1),
              points: (item['points'] as int).toString(),
              benefit: item['benefit'] as String,
              tips: item['tips'] as String,
              imageUrl: item['image'] as String,
              icon: item['icon'] as IconData,
              badgeColor: const Color(0xFF0D6938),
              badgeText: 'Organik',
              isDark: isDark,
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: PANDUAN SAMPAH NON-ORGANIK
  // ===========================================================================
  Widget _buildNonOrganicGuideTab(bool isDark) {
    final defaultNonOrganics = [
      {
        'name': 'Plastik PET (Botol Mineral Bening)',
        'sample': 'Botol air mineral bening, botol jus transparan, botol soda',
        'rate': 10.0,
        'points': 20,
        'icon': Icons.local_drink_outlined,
        'image':
            'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Daur ulang jadi serat poliester pakaian, dakron bantal & botol baru.',
        'tips': 'Bilas bersih, lepas tutup & label, kemudian injak/kempeskan botol.',
      },
      {
        'name': 'Plastik HDPE & PP (Wadah Sabun & Cup)',
        'sample': 'Botol shampoo, botol deterjen, cup boba keras, ember pecah',
        'rate': 9.0,
        'points': 18,
        'icon': Icons.category_outlined,
        'image':
            'https://images.unsplash.com/photo-1591193686104-fddba4d0e4d8?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Dicacah menjadi pelet plastik berkualitas tinggi untuk perabot rumah.',
        'tips': 'Cuci sisa sabun atau cairan manis, tumpuk rapi agar hemat tempat.',
      },
      {
        'name': 'Kardus Box & Karton Cokelat',
        'sample': 'Kardus boks paket ekspedisi, karton tebal cokelat gelombang',
        'rate': 8.0,
        'points': 15,
        'icon': Icons.inventory_outlined,
        'image':
            'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Dilebur kembali menjadi bubur kertas (pulp) kemasan ramah lingkungan.',
        'tips': 'Bongkar boks, lepaskan lakban plastik dan staples, lalu ikat bertumpuk.',
      },
      {
        'name': 'Kertas HVS, Arsip & Majalah',
        'sample': 'Kertas kantor HVS putih, buku tulis, dokumen arsip & koran bekas',
        'rate': 6.5,
        'points': 14,
        'icon': Icons.menu_book_outlined,
        'image':
            'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Mengurangi penebangan pohon untuk bahan baku kertas daur ulang.',
        'tips': 'Pastikan kertas kering tidak terkena minyak, satukan dalam map/tali.',
      },
      {
        'name': 'Kaleng Minuman & Logam Aluminium',
        'sample': 'Kaleng minuman soda, kaleng susu kental manis, tutup botol logam',
        'rate': 12.0,
        'points': 25,
        'icon': Icons.inventory_2_outlined,
        'image':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Logam dapat didaur ulang 100% tanpa penurunan kualitas material.',
        'tips': 'Cuci sisa minuman manis dan pipihkan kaleng agar hemat ruang simpan.',
      },
      {
        'name': 'Botol Kaca & Beling Transparan',
        'sample': 'Botol sirup beling, botol kecap/saus, toples selai kaca',
        'rate': 5.0,
        'points': 12,
        'icon': Icons.wine_bar_outlined,
        'image':
            'https://images.unsplash.com/photo-1516981879613-9f5da904015f?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Dicuci ulang steril atau dilebur menjadi produk kaca baru.',
        'tips': 'Bilas bersih dan lapisi wadah kardus agar tidak pecah saat pengiriman.',
      },
      {
        'name': 'Sampah Elektronik (E-Waste)',
        'sample': 'Kabel USB rusak, charger lama, PCB mainan, HP mati, baterai',
        'rate': 15.0,
        'points': 30,
        'icon': Icons.devices_other_outlined,
        'image':
            'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&q=80&w=600',
        'benefit': 'Pemisahan logam mulia tembaga/emas & pengolahan limbah B3 yang aman.',
        'tips': 'Simpan dalam wadah khusus terpisah dari cairan agar tidak korsleting.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Intro Card Non-Organik
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0D6938).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.recycling, color: Color(0xFF0D6938), size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prinsip 3R: Sampah Non-Organik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0D6938),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sampah anorganik membutuhkan ratusan tahun untuk terurai. Dengan memilah plastik, kertas, kaca, dan logam, Anda menyelamatkan ekosistem laut & menghasilkan nilai ekonomi.',
                      style: TextStyle(fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Kategori Sampah Non-Organik yang Diterima',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D6938)),
            ),
          )
        else if (_nonOrganicItems.isNotEmpty)
          ..._nonOrganicItems.map((item) {
            return _buildCategoryDetailCard(
              title: item.name,
              sample: item.sampleItem,
              rate: item.ratePerKg.toStringAsFixed(1),
              points: item.ecoPoints.toString(),
              benefit: item.description.isNotEmpty
                  ? item.description
                  : 'Daur ulang dan olah kembali menjadi produk bernilai ekonomis tinggi.',
              tips: item.handlingTip.isNotEmpty
                  ? item.handlingTip
                  : 'Bersihkan, keringkan, dan kempeskan sebelum disetor.',
              imageUrl: item.imageUrl,
              icon: item.icon,
              badgeColor: const Color(0xFF1565C0),
              badgeText: 'Non-Organik',
              isDark: isDark,
            );
          })
        else
          ...defaultNonOrganics.map((item) {
            return _buildCategoryDetailCard(
              title: item['name'] as String,
              sample: item['sample'] as String,
              rate: (item['rate'] as double).toStringAsFixed(1),
              points: (item['points'] as int).toString(),
              benefit: item['benefit'] as String,
              tips: item['tips'] as String,
              imageUrl: item['image'] as String,
              icon: item['icon'] as IconData,
              badgeColor: const Color(0xFF1565C0),
              badgeText: 'Non-Organik',
              isDark: isDark,
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: FAQ & TIPS PRAKTIS 3R
  // ===========================================================================
  Widget _buildFaqAndTipsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Pertanyaan yang Sering Diajukan (FAQ)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildFaqAccordion(
          title: 'Bagaimana cara kerja penukaran sampah menjadi saldo rupiah?',
          content:
              'Setiap kali Anda menyetor sampah (melalui Drop-off atau Jemput Kurir), tim kami akan memverifikasi jenis & berat sampah. Saldo rupiah dan EcoPoints akan otomatis masuk ke dompet akun Anda dan dapat ditarik ke rekening bank atau e-wallet kapan saja.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildFaqAccordion(
          title: 'Apa perbedaan metode Drop-off dan Jemput Kurir?',
          content:
              '• Drop-off: Anda mengantar sampah sendiri ke Bank Sampah / Drop Point terdekat tanpa biaya layanan tambahan.\n• Jemput Kurir: Mitra kurir TrashToCash akan datang langsung ke rumah Anda untuk menimbang dan mengangkut sampah.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildFaqAccordion(
          title: 'Apakah fitur Scan Foto AI 100% akurat?',
          content:
              'Fitur Scan Foto AI memiliki tingkat akurasi hingga 98% untuk mengenali objek sampah yang jelas dan bersih. Anda tetap dapat mengubah kategori atau mengoreksi berat sampah secara manual sebelum transaksi dikonfirmasi.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildFaqAccordion(
          title: 'Sampah apa saja yang TIDAK diterima oleh TrashToCash?',
          content:
              'Kami tidak menerima limbah medis berbahaya (jarum suntik, infus), sampah B3 beracun tak teridentifikasi, popok sekali pakai bekas, puntung rokok, atau sampah basah bercampur lumpur kotor.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildFaqAccordion(
          title: 'Bagaimana cara menaikkan poin EcoPoints & Reward?',
          content:
              'Kumpulkan sampah bernilai tinggi seperti Plastik PET, Minyak Jelantah, dan Logam Kaleng dalam kondisi bersih & terpilah. Sering melakukan transaksi akan menaikkan level member Anda untuk bonus reward eksklusif!',
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // 3R Infographic Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D6938), Color(0xFF13874B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nature_people, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Gerakan Bersama 3R',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '1. REDUCE: Kurangi penggunaan kemasan sekali pakai.\n2. REUSE: Gunakan kembali wadah yang masih layak pakai.\n3. RECYCLE: Pilah dan setorkan ke TrashToCash untuk diolah kembali.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF0D6938)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoDontItem({required bool isDo, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDo ? Icons.check_circle : Icons.cancel,
          color: isDo ? const Color(0xFF0D6938) : Colors.redAccent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDetailCard({
    required String title,
    required String sample,
    required String rate,
    required String points,
    required String benefit,
    required String tips,
    required String imageUrl,
    required IconData icon,
    required Color badgeColor,
    required String badgeText,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showCategoryDetailModal(
            title: title,
            sample: sample,
            rate: rate,
            points: points,
            benefit: benefit,
            tips: tips,
            imageUrl: imageUrl,
            icon: icon,
            badgeColor: badgeColor,
            badgeText: badgeText,
            isDark: isDark,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Image Thumbnail & Rates
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFEAF4EE),
                        child: Icon(icon, color: const Color(0xFF0D6938), size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tarif: Rp $rate/kg  •  +$points Eco/kg',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sample,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Color(0xFF0D6938),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Benefit & Tips Box
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.recycling, size: 14, color: Color(0xFF0D6938)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Manfaat Olah: $benefit',
                          style: const TextStyle(fontSize: 11, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tips Pilah: $tips',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show rich interactive detail modal when category card is clicked
  void _showCategoryDetailModal({
    required String title,
    required String sample,
    required String rate,
    required String points,
    required String benefit,
    required String tips,
    required String imageUrl,
    required IconData icon,
    required Color badgeColor,
    required String badgeText,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Grab handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Hero Image with Gradient & Badge Overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 190,
                          color: const Color(0xFFEAF4EE),
                          child: Icon(icon, size: 60, color: const Color(0xFF0D6938)),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sample,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Key Statistics Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF0D6938).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tarif Penukaran',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp $rate / kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0D6938),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bonus EcoPoints',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+$points Pts / kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Section 1: Contoh Barang Diterima
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF0D6938)),
                          SizedBox(width: 8),
                          Text(
                            'Contoh Barang yang Diterima',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sample,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Section 2: Manfaat Daur Ulang
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.nature_people_outlined, size: 18, color: Color(0xFF0D6938)),
                          SizedBox(width: 8),
                          Text(
                            'Manfaat Olah & Nilai Lingkungan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Section 3: Tips Penanganan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Tips Penanganan & Pemilahan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tips,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Bottom Action Button: Setor / Scan Sampah Ini Sekarang
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LiveCameraScanScreen(isPickup: false),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        'Setor / Scan $title Sekarang',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqAccordion({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: const Color(0xFF0D6938),
        collapsedIconColor: Colors.grey,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
