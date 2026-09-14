import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashtocash/models/user_model_firebase.dart';
import 'package:trashtocash/screens/login_firebase_screen.dart';
import 'package:trashtocash/services/firebase_auth_service.dart';

class ProfileFirebaseScreen extends StatefulWidget {
  const ProfileFirebaseScreen({super.key});

  @override
  State<ProfileFirebaseScreen> createState() => _ProfileFirebaseScreenState();
}

class _ProfileFirebaseScreenState extends State<ProfileFirebaseScreen> {
  final _authService = FirebaseAuthService();
  String _currentUid = '';
  Future<UserModelFirebase?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _currentUid = _authService.currentUserId ?? '';
    if (_currentUid.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginFirebaseScreen()),
          (route) => false,
        );
      });
      return;
    }

    _userFuture = _authService.getUserDetails(_currentUid);
  }

  Future<void> _logout() async {
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('firebaseUid');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginFirebaseScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D6938);
    const borderColor = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Firebase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Step 10: Profile Header Card with FutureBuilder
            FutureBuilder<UserModelFirebase?>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    color: primaryColor.withValues(alpha: 0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final user = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    border: const Border(
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor,
                        child: Text(
                          (user?.name.isNotEmpty ?? false)
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Nama User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'email@firebase.com',
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Akun Firebase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined,
                            color: primaryColor),
                        title: const Text('UID Akun'),
                        subtitle: Text(_currentUid),
                      ),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.cloud_done_outlined,
                            color: primaryColor),
                        title: Text('Database Provider'),
                        subtitle: Text('Cloud Firestore (users collection)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
