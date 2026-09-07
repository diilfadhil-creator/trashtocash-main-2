import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/models/user_model.dart';
import 'package:trashtocash/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;

  const RegisterScreen({super.key, this.initialRole = 'customer'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late String _selectedRole; // 'customer' or 'driver'

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  final _passwordController = TextEditingController();

  // Payment Account Controllers (Rekening Bank & Dompet Digital)
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _ewalletNumberController = TextEditingController();
  final _ewalletHolderController = TextEditingController();

  String _preferredPayoutMethod = 'ewallet'; // 'ewallet' or 'bank'
  String _selectedBank = 'Bank Central (BCA)';
  String _selectedEwallet = 'DANA';

  final List<String> _bankOptions = [
    'Bank Central (BCA)',
    'Bank Mandiri',
    'Bank Rakyat Indonesia (BRI)',
    'Bank Negara Indonesia (BNI)',
    'Bank Syariah Indonesia (BSI)',
    'Bank CIMB Niaga',
    'Bank Permata',
    'Bank Jago',
    'SeaBank',
  ];

  final List<Map<String, dynamic>> _ewalletList = [
    {
      'name': 'DANA',
      'tag': 'Populer',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF108EE9),
    },
    {
      'name': 'GoPay',
      'tag': 'Instan',
      'icon': Icons.qr_code_2,
      'color': Color(0xFF00AED6),
    },
    {
      'name': 'OVO',
      'tag': 'Cashback',
      'icon': Icons.monetization_on,
      'color': Color(0xFF4C3494),
    },
    {
      'name': 'ShopeePay',
      'tag': 'Koin',
      'icon': Icons.shopping_bag,
      'color': Color(0xFFEE4D2D),
    },
    {
      'name': 'LinkAja',
      'tag': 'BUMN',
      'icon': Icons.link,
      'color': Color(0xFFE32526),
    },
    {
      'name': 'AstraPay',
      'tag': 'Mitra',
      'icon': Icons.payment,
      'color': Color(0xFF004D99),
    },
    {
      'name': 'i.saku',
      'tag': 'Retail',
      'icon': Icons.storefront,
      'color': Color(0xFF0072CE),
    },
  ];

  DriverVehicleType _selectedVehicleType = DriverVehicleType.motorcycle;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    _passwordController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _ewalletNumberController.dispose();
    _ewalletHolderController.dispose();
    super.dispose();
  }

  bool get _isDriver => _selectedRole == 'driver';

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final plate = _plateController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi nama, email, nomor HP, dan password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isDriver && plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi nomor pelat kendaraan armada Anda.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal harus 6 karakter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bankAccount = _bankAccountNumberController.text.trim();
    final bankHolder = _bankAccountHolderController.text.trim();
    final ewalletNumber = _ewalletNumberController.text.trim();
    final ewalletHolder = _ewalletHolderController.text.trim();

    setState(() => _isLoading = true);

    try {
      final newUser = UserModel(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
        phone: phone,
        vehicleType: _isDriver ? _selectedVehicleType.label : null,
        vehiclePlate: _isDriver ? plate : null,
        address: address.isNotEmpty ? address : null,
        bankName: bankAccount.isNotEmpty ? _selectedBank : null,
        bankAccountNumber: bankAccount.isNotEmpty ? bankAccount : null,
        bankAccountHolder: bankHolder.isNotEmpty ? bankHolder : (name.isNotEmpty ? name : null),
        ewalletType: ewalletNumber.isNotEmpty ? _selectedEwallet : null,
        ewalletNumber: ewalletNumber.isNotEmpty ? ewalletNumber : null,
        ewalletAccountHolder: ewalletHolder.isNotEmpty ? ewalletHolder : (name.isNotEmpty ? name : null),
        preferredPayoutMethod: _preferredPayoutMethod,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.registerUser(newUser);

      // Simpan akun penarikan ke SharedPreferences untuk sesi cepat
      final prefs = await SharedPreferences.getInstance();
      if (bankAccount.isNotEmpty) {
        await prefs.setString('bankName', _selectedBank);
        await prefs.setString('bankAccountNumber', bankAccount);
        await prefs.setString('bankAccountHolder', bankHolder.isNotEmpty ? bankHolder : name);
      }
      if (ewalletNumber.isNotEmpty) {
        await prefs.setString('ewalletType', _selectedEwallet);
        await prefs.setString('ewalletNumber', ewalletNumber);
        await prefs.setString('ewalletAccountHolder', ewalletHolder.isNotEmpty ? ewalletHolder : name);
      }
      await prefs.setString('preferredPayoutMethod', _preferredPayoutMethod);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDriver
                ? 'Pendaftaran Mitra Driver Berhasil! Silakan masuk.'
                : 'Registrasi Akun Warga Berhasil! Silakan masuk.',
          ),
          backgroundColor: const Color(0xFF0D6938),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(initialRole: _selectedRole),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Terjadi kesalahan saat pendaftaran.';
      if (e.toString().contains('Email sudah terdaftar')) {
        errorMessage =
            'Email sudah terdaftar. Silakan gunakan email lain atau langsung login.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDriver
                ? (isDark
                    ? [const Color(0xFF16251C), const Color(0xFF101713)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFF9FBF9)])
                : (isDark
                    ? [const Color(0xFF16221A), const Color(0xFF0F1612)]
                    : [const Color(0xFFD6EFE2), const Color(0xFFF9FBF9)]),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/trashtocash_logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _isDriver
                        ? 'Formulir Pendaftaran Mitra Kurir Driver'
                        : 'Daftar Akun Warga & Tukar Sampah Jadi Cuan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          _isDriver ? FontWeight.bold : FontWeight.normal,
                      color: _isDriver
                          ? const Color(0xFF0D6938)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ROLE SELECTOR TABS
                  _buildRoleSelector(isDark),
                  const SizedBox(height: 16),

                  // Register Form Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2822) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDriver
                              ? 'Daftar Mitra Driver 🛵'
                              : 'Daftar Warga Penyetor 🌿',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDriver
                              ? 'Lengkapi data armada & kontak Anda'
                              : 'Lengkapi data untuk membuat akun',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                        const Divider(height: 20),

                        // Nama Lengkap
                        _buildInputFieldLabel(
                          _isDriver ? 'Nama Lengkap Mitra' : 'Nama Lengkap',
                          isDark,
                        ),
                        _buildTextField(
                          controller: _nameController,
                          hint: _isDriver ? 'Budi Santoso' : 'Nama Anda',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // Nomor HP / WhatsApp
                        _buildInputFieldLabel('Nomor WhatsApp', isDark),
                        _buildTextField(
                          controller: _phoneController,
                          hint: '0812-3456-7890',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // IF DRIVER: Jenis Kendaraan & Nomor Pelat
                        if (_isDriver) ...[
                          _buildInputFieldLabel('Jenis Kendaraan Armada', isDark),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF263229)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DriverVehicleType>(
                                value: _selectedVehicleType,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? const Color(0xFF1E2822)
                                    : Colors.white,
                                items: DriverVehicleType.values.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      children: [
                                        Icon(
                                          v.icon,
                                          color: const Color(0xFF0D6938),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            v.label,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedVehicleType = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInputFieldLabel('Nomor Pelat Kendaraan', isDark),
                          _buildTextField(
                            controller: _plateController,
                            hint: 'B 1234 XYZ',
                            icon: Icons.badge_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          // IF CUSTOMER: Alamat Rumah
                          _buildInputFieldLabel('Alamat Rumah Lengkap', isDark),
                          _buildTextField(
                            controller: _addressController,
                            hint: 'Jl. Melati Blok C2 No. 15',
                            icon: Icons.home_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ==========================================
                        // REKENING BANK & DOMPET DIGITAL (WITHDRAWAL)
                        // ==========================================
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF263229)
                                : const Color(0xFFF4F8F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF0D6938).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6938).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF0D6938),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Opsi Penarikan Saldo T-Cash',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: isDark ? Colors.white : const Color(0xFF0D6938),
                                          ),
                                        ),
                                        Text(
                                          'Daftarkan E-Wallet atau Rekening untuk mencairkan saldo hasil setor sampah',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Pilihan Metode Penarikan Utama
                              Text(
                                'Pilih Metode Penarikan Utama:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _preferredPayoutMethod = 'ewallet');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: _preferredPayoutMethod == 'ewallet'
                                              ? const Color(0xFF0D6938)
                                              : (isDark ? const Color(0xFF1E2822) : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _preferredPayoutMethod == 'ewallet'
                                                ? const Color(0xFF0D6938)
                                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.phone_android,
                                                size: 14,
                                                color: _preferredPayoutMethod == 'ewallet'
                                                    ? Colors.white
                                                    : const Color(0xFF0D6938),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'E-Wallet',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _preferredPayoutMethod == 'ewallet'
                                                      ? Colors.white
                                                      : (isDark ? Colors.white : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _preferredPayoutMethod = 'bank');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: _preferredPayoutMethod == 'bank'
                                              ? const Color(0xFF0D6938)
                                              : (isDark ? const Color(0xFF1E2822) : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _preferredPayoutMethod == 'bank'
                                                ? const Color(0xFF0D6938)
                                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.account_balance,
                                                size: 14,
                                                color: _preferredPayoutMethod == 'bank'
                                                    ? Colors.white
                                                    : const Color(0xFF0D6938),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Rekening Bank',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _preferredPayoutMethod == 'bank'
                                                      ? Colors.white
                                                      : (isDark ? Colors.white : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _preferredPayoutMethod = 'both');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: _preferredPayoutMethod == 'both'
                                              ? const Color(0xFF0D6938)
                                              : (isDark ? const Color(0xFF1E2822) : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _preferredPayoutMethod == 'both'
                                                ? const Color(0xFF0D6938)
                                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.all_inclusive,
                                                size: 14,
                                                color: _preferredPayoutMethod == 'both'
                                                    ? Colors.white
                                                    : const Color(0xFF0D6938),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Keduanya',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _preferredPayoutMethod == 'both'
                                                      ? Colors.white
                                                      : (isDark ? Colors.white : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ==========================================
                              // 1. SECTION: PENDAFTARAN E-WALLET
                              // ==========================================
                              if (_preferredPayoutMethod == 'ewallet' || _preferredPayoutMethod == 'both') ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_android, size: 15, color: Color(0xFF0D6938)),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Pilih Provider E-Wallet',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D6938).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Instan & Bebas Biaya',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D6938),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Pilihan Provider E-Wallet Chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _ewalletList.map((ewallet) {
                                    final isSelected = _selectedEwallet == ewallet['name'];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedEwallet = ewallet['name'] as String);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (ewallet['color'] as Color).withValues(alpha: 0.15)
                                              : (isDark ? const Color(0xFF1E2822) : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? (ewallet['color'] as Color)
                                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                                            width: isSelected ? 1.8 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              ewallet['icon'] as IconData,
                                              size: 14,
                                              color: ewallet['color'] as Color,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              ewallet['name'] as String,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),

                                // Input No. HP E-Wallet
                                _buildTextField(
                                  controller: _ewalletNumberController,
                                  hint: 'Nomor HP $_selectedEwallet (Contoh: 081234567890)',
                                  icon: Icons.account_balance_wallet_outlined,
                                  keyboardType: TextInputType.phone,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 4),

                                // Action tombol untuk salin No. WhatsApp
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Nomor terdaftar di $_selectedEwallet',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () {
                                        if (_phoneController.text.isNotEmpty) {
                                          setState(() {
                                            _ewalletNumberController.text = _phoneController.text.trim();
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.copy, size: 12, color: Color(0xFF0D6938)),
                                      label: const Text(
                                        'Gunakan No. WhatsApp',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF0D6938),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Input Nama Akun E-Wallet
                                _buildTextField(
                                  controller: _ewalletHolderController,
                                  hint: 'Nama Terdaftar di $_selectedEwallet (A/N Akun)',
                                  icon: Icons.person_pin_outlined,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      if (_nameController.text.isNotEmpty) {
                                        setState(() {
                                          _ewalletHolderController.text = _nameController.text.trim();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.person_add_alt, size: 12, color: Color(0xFF0D6938)),
                                    label: const Text(
                                      'Samakan dengan Nama Lengkap',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF0D6938),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // ==========================================
                              // 2. SECTION: PENDAFTARAN REKENING BANK
                              // ==========================================
                              if (_preferredPayoutMethod == 'bank' || _preferredPayoutMethod == 'both') ...[
                                if (_preferredPayoutMethod == 'both')
                                  const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance, size: 14, color: Color(0xFF0D6938)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Rekening Bank Transfer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2822) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBank,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E2822) : Colors.white,
                                      items: _bankOptions.map((bank) {
                                        return DropdownMenuItem(
                                          value: bank,
                                          child: Text(
                                            bank,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedBank = val);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _bankAccountNumberController,
                                  hint: 'Nomor Rekening Bank (Contoh: 1234567890)',
                                  icon: Icons.credit_card_outlined,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _bankAccountHolderController,
                                  hint: 'Nama Pemilik Rekening (A/N Sesuai Buku Tabungan)',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Email
                        _buildInputFieldLabel('Email Address', isDark),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'name@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // Password
                        _buildInputFieldLabel('Password (Minimal 6 Karakter)', isDark),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF263229)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D6938),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6938),
                              disabledBackgroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isDriver
                                        ? 'Daftar Mitra Driver 🛵'
                                        : 'Daftar Akun Warga 🌿',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Redirection Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                initialRole: _selectedRole,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Masuk di Sini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0D6938).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Customer Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'customer'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isDriver
                      ? const Color(0xFF0D6938)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: !_isDriver
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Daftar Warga',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: !_isDriver
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Driver Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'driver'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isDriver
                      ? const Color(0xFF0D6938)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.electric_moped,
                      size: 16,
                      color: _isDriver
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Daftar Driver',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _isDriver
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF263229) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D6938), width: 1.5),
        ),
      ),
    );
  }
}
