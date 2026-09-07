const List<Map<String, Object>> wasteSeedData = [

  // --- SAMPAH ORGANIK SPESIFIK (6 KATEGORI) ---
  {
    'name': 'Sisa Makanan & Dapur',
    'type': 'Organik',
    'sample_item': 'Sisa nasi, lauk pauk, sisa hidangan basi & mie',
    'rate_per_kg': 4000.0,
    'eco_points': 10,
    'icon_name': 'food',
    'image_url':
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=600',
    'description':
        'Limbah sisa makanan dapur rumah tangga untuk biokonversi maggot atau pupuk kompos cair.',
    'handling_tip':
        'Tiriskan air kuah dan buang plastik pembungkus sebelum disetor.',
  },
  {
    'name': 'Kulit Buah & Sayuran Segar',
    'type': 'Organik',
    'sample_item': 'Kulit pisang, jeruk, potongan wortel, sawi & buah busuk',
    'rate_per_kg': 4500.0,
    'eco_points': 12,
    'icon_name': 'food',
    'image_url':
        'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=600',
    'description':
        'Bahan organik hijau segar berprotein tinggi untuk pembuatan kompos aerobik atau eco-enzyme.',
    'handling_tip': 'Pisahkan dari stiker buah, tali rafia, atau steples.',
  },
  {
    'name': 'Daun, Ranting & Rumput Kebun',
    'type': 'Organik',
    'sample_item': 'Daun kering gugur, rumput tebas, potongan ranting taman',
    'rate_per_kg': 3000.0,
    'eco_points': 8,
    'icon_name': 'leaf',
    'image_url':
        'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&q=80&w=600',
    'description':
        'Bahan organik cokelat kaya karbon padat yang sangat baik sebagai bahan dasar kompos padat.',
    'handling_tip':
        'Kumpulkan dalam keadaan kering atau masukkan karung terikat rapi.',
  },
  {
    'name': 'Minyak Jelantah (Minyak Goreng Bekas)',
    'type': 'Organik',
    'sample_item':
        'Minyak goreng bekas dapur bening saring tanpa endapan hitam',
    'rate_per_kg': 6500.0,
    'eco_points': 18,
    'icon_name': 'oil',
    'image_url':
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=600',
    'description':
        'Minyak jelantah layak suling untuk bahan baku energi terbarukan (biodiesel dan lilin aromaterapi).',
    'handling_tip':
        'Saring ampas sisa gorengan, simpan dalam jerigen/botol plastik tertutup rapat.',
  },
  {
    'name': 'Ampas Kopi & Daun Teh',
    'type': 'Organik',
    'sample_item':
        'Ampas bubuk seduhan kopi murni & teh celup / daun teh basah',
    'rate_per_kg': 5000.0,
    'eco_points': 15,
    'icon_name': 'coffee',
    'image_url':
        'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&q=80&w=600',
    'description':
        'Sumber nitrogen tinggi alami yang sangat efektif menyuburkan tanaman dan mengusir hama tanah.',
    'handling_tip':
        'Keringkan sedikit dari sisa air seduhan agar tidak terlalu basah.',
  },
  {
    'name': 'Cangkang Telur & Limbah Halus',
    'type': 'Organik',
    'sample_item':
        'Cangkang telur ayam/bebek kering tumbuk & serbuk kayu kelapa',
    'rate_per_kg': 3500.0,
    'eco_points': 10,
    'icon_name': 'compost',
    'image_url':
        'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&q=80&w=600',
    'description':
        'Kaya kalsium karbonat tinggi untuk pupuk pemulih pH tanah dan pakan ternak tambahan.',
    'handling_tip':
        'Bilas bersih sisa lendir telur dan remas/tumbuk agar hemat ruang.',
  },

  // ==========================================
  // --- SAMPAH NON-ORGANIK SPESIFIK (9 KATEGORI) ---
  // ==========================================
  {
    'name': 'Plastik PET (Botol Mineral Bening)',
    'type': 'Non-Organik',
    'sample_item':
        'Botol air mineral bening, botol jus transparan & minuman isotonik',
    'rate_per_kg': 10000.0,
    'eco_points': 20,
    'icon_name': 'bottle',
    'image_url':
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=600',
    'description':
        'Plastik Polyethylene Terephthalate bening yang bernilai daur ulang tinggi untuk serat tekstil.',
    'handling_tip':
        'Bilas bersih, lepas tutup botol & label plastik, lalu kempeskan botol.',
  },
  {
    'name': 'Plastik HDPE & PP (Wadah Sabun & Cup)',
    'type': 'Non-Organik',
    'sample_item':
        'Botol shampoo, cup minuman boba, botol deterjen & ember pecah',
    'rate_per_kg': 9000.0,
    'eco_points': 18,
    'icon_name': 'bottle',
    'image_url':
        'https://images.unsplash.com/photo-1591193686104-fddba4d0e4d8?auto=format&fit=crop&q=80&w=600',
    'description':
        'Plastik keras lentur yang siap dicacah menjadi pelet plastik dan produk perabotan baru.',
    'handling_tip':
        'Cuci sisa sabun/cairan manis dan tumpuk rapi agar hemat tempat.',
  },
  {
    'name': 'Kardus Box & Karton Cokelat',
    'type': 'Non-Organik',
    'sample_item':
        'Kardus paket pengiriman, karton tebal cokelat & boks kemasan barang',
    'rate_per_kg': 8000.0,
    'eco_points': 15,
    'icon_name': 'book',
    'image_url':
        'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?auto=format&fit=crop&q=80&w=600',
    'description':
        'Kardus gelombang bebas isolasi untuk diolah kembali menjadi bubur kertas daur ulang.',
    'handling_tip':
        'Bongkar dan lipat pipih, lepaskan lakban/isolasi plastik dan staples.',
  },
  {
    'name': 'Kertas HVS, Dokumen & Majalah',
    'type': 'Non-Organik',
    'sample_item': 'Kertas kantor HVS, dokumen arsip, koran bekas & majalah',
    'rate_per_kg': 6500.0,
    'eco_points': 14,
    'icon_name': 'paper',
    'image_url':
        'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?auto=format&fit=crop&q=80&w=600',
    'description':
        'Kertas putih dan serat murni yang dapat diproses menjadi kertas cetak dan tisu daur ulang.',
    'handling_tip':
        'Ikat rapi menggunakan tali dan pastikan dalam kondisi kering tidak terkena minyak.',
  },
  {
    'name': 'Kaleng Minuman Aluminium',
    'type': 'Non-Organik',
    'sample_item':
        'Kaleng soda aluminium, kaleng kopi/teh, botol aerosol kosong',
    'rate_per_kg': 18000.0,
    'eco_points': 30,
    'icon_name': 'metal',
    'image_url':
        'https://images.unsplash.com/photo-1588698188172-1eb1e428c0b2?auto=format&fit=crop&q=80&w=600',
    'description':
        'Aluminium murni bernilai tinggi yang 100% dapat didaur ulang tanpa mengurangi kualitas.',
    'handling_tip':
        'Pastikan isi cairan kosong dan bilas bersih, pipihkan jika memungkinkan.',
  },
  {
    'name': 'Besi, Logam & Seng Ringan',
    'type': 'Non-Organik',
    'sample_item':
        'Paku, pipa besi bekas, plat seng, kawat & wajan/panci rongsok',
    'rate_per_kg': 14000.0,
    'eco_points': 25,
    'icon_name': 'metal',
    'image_url':
        'https://images.unsplash.com/photo-1533038590840-1cde6e668a91?auto=format&fit=crop&q=80&w=600',
    'description':
        'Limbah ferus dan logam berat yang siap dilebur kembali untuk industri konstruksi.',
    'handling_tip':
        'Kumpulkan dalam wadah aman tanpa ada ujung tajam terbuka yang membahayakan.',
  },
  {
    'name': 'Botol Kaca Bening & Sirup',
    'type': 'Non-Organik',
    'sample_item':
        'Botol kecap kaca, botol sirup bening, toples kaca selai utuh',
    'rate_per_kg': 5000.0,
    'eco_points': 10,
    'icon_name': 'glass',
    'image_url':
        'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&q=80&w=600',
    'description':
        'Wadah kaca utuh bersih yang siap digunakan ulang (reuse) atau dilebur dalam tungku daur ulang.',
    'handling_tip':
        'Cuci bersih sisa isi dan pastikan botol dalam kondisi utuh tidak retak.',
  },
  {
    'name': 'Pecahan Kaca & Kaca Warna',
    'type': 'Non-Organik',
    'sample_item':
        'Pecahan botol hijau/cokelat, kaca jendela bekas & piring beling',
    'rate_per_kg': 3500.0,
    'eco_points': 8,
    'icon_name': 'glass',
    'image_url':
        'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&q=80&w=600',
    'description':
        'Cullet kaca pecah untuk bahan baku industri peleburan kaca dan bahan pengeras aspal.',
    'handling_tip':
        'Bungkus aman dalam kardus tebal bertanda KACA agar kurir terlindungi.',
  },
  {
    'name': 'E-Waste (Elektronik & Kabel)',
    'type': 'Non-Organik',
    'sample_item':
        'Charger rusak, kabel tembaga, papan PCB, baterai HP & remote',
    'rate_per_kg': 25000.0,
    'eco_points': 45,
    'icon_name': 'electronic',
    'image_url':
        'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&q=80&w=600',
    'description':
        'Limbah elektronik berharga yang mengandung tembaga, emas, dan komponen logam mulia.',
    'handling_tip':
        'Jangan dibongkar/dibakar, bungkus baterai secara terpisah dari perangkat lain.',
  },
];
