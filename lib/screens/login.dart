import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/helpers/database_helper.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/screens/driver/driver_home_screen.dart';
import 'package:trashtocash/screens/home.dart';
import 'package:trashtocash/screens/register.dart';
import 'package:trashtocash/screens/login_firebase_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;

  const LoginScreen({super.key, this.initialRole = 'customer'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _selectedRole; // 'customer' or 'driver'
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isDriver => _selectedRole == 'driver';

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan email dan password Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authErr) {
        debugPrint('Firebase Auth sign in notice: $authErr');
      }

      // 1. Coba login dengan role yang dipilih dari Firestore
      var user = await DatabaseHelper.instance.loginUserWithRole(
        email,
        password,
        _selectedRole,
      );

      // Fallback: Jika belum ada user role terdaftar (migrasi lama), coba login umum
      if (user == null) {
        final generalUser =
            await DatabaseHelper.instance.loginUser(email, password);
        if (generalUser != null) {
          user = generalUser;
        }
      }

      if (!mounted) return;

      if (user == null) {
        final isRegistered =
            await DatabaseHelper.instance.isEmailRegistered(email);
        if (!mounted) return;

        final errorMessage = isRegistered
            ? 'Password salah atau akun tidak terdaftar sebagai ${_isDriver ? "Mitra Driver" : "Customer"}.'
            : 'Email belum terdaftar. Silakan registrasi terlebih dahulu.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Simpan Sesi Login di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', user.email);
      await prefs.setString('userName', user.name);
      await prefs.setString('userRole', _selectedRole);

      if (user.bankName != null) await prefs.setString('bankName', user.bankName!);
      if (user.bankAccountNumber != null) await prefs.setString('bankAccountNumber', user.bankAccountNumber!);
      if (user.bankAccountHolder != null) await prefs.setString('bankAccountHolder', user.bankAccountHolder!);
      if (user.ewalletType != null) await prefs.setString('ewalletType', user.ewalletType!);
      if (user.ewalletNumber != null) await prefs.setString('ewalletNumber', user.ewalletNumber!);
      if (user.ewalletAccountHolder != null) await prefs.setString('ewalletAccountHolder', user.ewalletAccountHolder!);
      if (user.preferredPayoutMethod != null) await prefs.setString('preferredPayoutMethod', user.preferredPayoutMethod!);

      if (_isDriver) {
        await prefs.setString('driverName', user.name);
        await prefs.setString('driverEmail', user.email);
        if (user.vehiclePlate != null) {
          await prefs.setString('driverPlate', user.vehiclePlate!);
        }
        await DriverHelper.instance.loadDriverProfile();
        DriverHelper.instance.isDriverModeActive.value = true;
      } else {
        DriverHelper.instance.isDriverModeActive.value = false;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDriver
                ? 'Selamat bertugas, Mitra ${user.name}! 🛵'
                : 'Selamat datang kembali, ${user.name}! 🌿',
          ),
          backgroundColor: const Color(0xFF0D6938),
        ),
      );

      // 3. Navigasi ke halaman sesuai peran
      if (_isDriver) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeTrashToCash()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
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
                  // Logo TrashToCash
                  Image.asset(
                    'assets/images/trashtocash_logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    _isDriver
                        ? 'Portal Masuk Mitra Kurir Driver'
                        : 'Turn your waste into digital balance\nwith a single tap.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          _isDriver ? FontWeight.bold : FontWeight.normal,
                      color: _isDriver
                          ? const Color(0xFF0D6938)
                          : (isDark ? Colors.white70 : Colors.black54),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ROLE SWITCHER SELECTOR (Customer vs Mitra Driver)
                  _buildRoleSelector(isDark),
                  const SizedBox(height: 16),

                  // Form Container Card
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
                        // Role Title Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDriver
                                    ? Colors.amber.shade100
                                    : const Color(0xFFEAF4EE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isDriver
                                    ? Icons.electric_moped
                                    : Icons.person_outline,
                                color: _isDriver
                                    ? Colors.amber.shade900
                                    : const Color(0xFF0D6938),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isDriver
                                        ? 'Masuk Mitra Driver'
                                        : 'Masuk Akun Warga',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _isDriver
                                        ? 'Siap menerima order & komisi'
                                        : 'Setor sampah & kumpulkan T-Cash',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Email Field
                        Text(
                          _isDriver ? 'Email Akun Driver' : 'Email Address',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _isDriver
                                ? 'driver@trashtocash.id'
                                : 'name@email.com',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              size: 20,
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
                        const SizedBox(height: 16),

                        // Password Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Silakan hubungi admin / reset via email.',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D6938),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginUser,
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
                                        ? 'Masuk Portal Driver 🛵'
                                        : 'Masuk Akun Warga 🌿',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'atau',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginFirebaseScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_fire_department, color: Colors.orange),
                          label: const Text(
                            'Masuk via Firebase (Contoh Slide)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D6938),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF0D6938)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Redirection Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isDriver
                            ? 'Belum terdaftar sebagai Driver? '
                            : 'Belum punya akun Customer? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(
                                initialRole: _selectedRole,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          _isDriver ? 'Daftar Mitra Driver' : 'Daftar Sekarang',
                          style: const TextStyle(
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
                      'Warga / Customer',
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
                      'Mitra Driver',
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
}
