import 'package:flutter/material.dart';
import 'package:trashtocash/screens/aut_cehck_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup smooth entrance animation (Fade + Scale)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Auto-navigate to AuthCheckScreen smoothly
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,

        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF0F2417),
                    Color(0xFF141E17),
                    Color(0xFF0C130E),
                  ]
                : const [
                    Color(0xFFCEEBDB),
                    Color(0xFFE8F6EE),
                    Color(0xFFF9FCFA),
                  ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,

            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,

                child: ScaleTransition(
                  scale: _scaleAnimation,

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        const SizedBox(height: 20),

                        // Center Content: New Official Brand Logo & Tagline
                        Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            // 1. App Logo with Glowing Ambient Effect
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Ambient Glow
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D6938)
                                            .withValues(
                                              alpha: isDark ? 0.35 : 0.18,
                                            ),
                                        blurRadius: 60,
                                        spreadRadius: 25,
                                      ),
                                    ],
                                  ),
                                ),

                                // New Logo Image
                                Image.asset(
                                  'assets/images/trashtocash_logo.png',
                                  width: 280,
                                  height: 220,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Subtitle Aplikasi
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Text(
                                'Aplikasi Pengelolaan Sampah Cerdas Berbasis Circular Economy dan Mobile Technology',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 4. Trust & Security Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,

                                vertical: 8,
                              ),

                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E2822)
                                    : Colors.white.withValues(alpha: 0.9),

                                borderRadius: BorderRadius.circular(30),

                                border: Border.all(
                                  color: const Color(
                                    0xFF0D6938,
                                  ).withValues(alpha: isDark ? 0.4 : 0.25),
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),

                                    blurRadius: 10,

                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),

                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  const Icon(
                                    Icons.eco_rounded,

                                    color: Color(0xFF0D6938),

                                    size: 18,
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    'Platform Daur Ulang Digital Terpercaya',

                                    style: TextStyle(
                                      fontSize: 12,

                                      fontWeight: FontWeight.w600,

                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0D6938),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Footer: Loading Indicator & Version
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              SizedBox(
                                width: 28,

                                height: 28,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,

                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0D6938),
                                      ),

                                  backgroundColor: const Color(
                                    0xFF0D6938,
                                  ).withValues(alpha: 0.15),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                'v1.0.0 • Bersama Jaga Kelestarian Lingkungan',

                                style: TextStyle(
                                  fontSize: 11,

                                  fontWeight: FontWeight.w500,

                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
