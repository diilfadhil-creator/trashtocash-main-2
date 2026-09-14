import 'package:flutter/material.dart';

/// Definisi Tingkat / Level Pengguna di TrashToCash
class UserLevelTier {
  final int level;
  final String name;
  final String title;
  final int minPoints;
  final int maxPoints; // -1 jika tingkat tertinggi
  final double minKg;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData icon;
  final String bonusBadge;
  final List<String> benefits;

  const UserLevelTier({
    required this.level,
    required this.name,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
    required this.minKg,
    required this.primaryColor,
    required this.backgroundColor,
    required this.icon,
    required this.bonusBadge,
    required this.benefits,
  });

  /// Daftar lengkap 5 level tingkatan resmi TrashToCash (Eco Starter, Saver, Warrior, Hero, Legend)
  static const List<UserLevelTier> allTiers = [
    UserLevelTier(
      level: 1,
      name: 'Eco Starter',
      title: 'Member Eco Starter',
      minPoints: 0,
      maxPoints: 49,
      minKg: 0.0,
      primaryColor: Color(0xFFCD7F32),
      backgroundColor: Color(0xFFFBEFE6),
      icon: Icons.workspace_premium_outlined,
      bonusBadge: 'Starter (0%)',
      benefits: [
        'Point Eco Normal (1.0x Jemput / 1.2x Drop-off)',
        'T-Cash Normal (100% Drop-off / 85% Jemput)',
        'Penarikan Saldo ke Rekening Bank & E-Wallet',
      ],
    ),
    UserLevelTier(
      level: 2,
      name: 'Eco Saver',
      title: 'Member Eco Saver',
      minPoints: 50,
      maxPoints: 149,
      minKg: 5.0,
      primaryColor: Color(0xFF757575),
      backgroundColor: Color(0xFFF5F5F5),
      icon: Icons.eco_outlined,
      bonusBadge: 'Bonus Eco +3%',
      benefits: [
        'Semua keuntungan Member Eco Starter',
        'Bonus Tambahan +3% Point Eco',
        'Badge Profil Eco Saver Member',
      ],
    ),
    UserLevelTier(
      level: 3,
      name: 'Eco Warrior',
      title: 'Member Eco Warrior',
      minPoints: 150,
      maxPoints: 349,
      minKg: 15.0,
      primaryColor: Color(0xFF0D6938),
      backgroundColor: Color(0xFFE8F5E9),
      icon: Icons.military_tech_outlined,
      bonusBadge: 'Bonus Eco +5%',
      benefits: [
        'Semua keuntungan Member Eco Saver',
        'Bonus Tambahan +5% Point Eco',
        'Prioritas verifikasi penjemputan',
      ],
    ),
    UserLevelTier(
      level: 4,
      name: 'Eco Hero',
      title: 'Member Eco Hero',
      minPoints: 350,
      maxPoints: 749,
      minKg: 35.0,
      primaryColor: Color(0xFF1976D2),
      backgroundColor: Color(0xFFE3F2FD),
      icon: Icons.shield_outlined,
      bonusBadge: 'Bonus Eco +8%',
      benefits: [
        'Semua keuntungan Member Eco Warrior',
        'Bonus Tambahan +8% Point Eco',
        'Voucher eksklusif bulanan',
      ],
    ),
    UserLevelTier(
      level: 5,
      name: 'Eco Legend',
      title: 'Member Eco Legend',
      minPoints: 750,
      maxPoints: -1,
      minKg: 75.0,
      primaryColor: Color(0xFFFFB300),
      backgroundColor: Color(0xFFFFF8E1),
      icon: Icons.stars_rounded,
      bonusBadge: 'Bonus All +10%',
      benefits: [
        'Semua keuntungan Member Eco Hero',
        'Bonus Tambahan +10% Point T-Cash & Eco',
        'Prioritas penjemputan kurir kilat',
        'Badge Profil Eco Legend Eksklusif',
      ],
    ),
  ];
}

/// Status Progres Level Pengguna
class UserLevelProgression {
  final UserLevelTier currentTier;
  final UserLevelTier? nextTier;
  final int currentPoints;
  final double currentKg;
  final double progressPercent; // 0.0 to 1.0
  final int pointsNeededForNext;
  final bool isMaxLevel;

  const UserLevelProgression({
    required this.currentTier,
    this.nextTier,
    required this.currentPoints,
    required this.currentKg,
    required this.progressPercent,
    required this.pointsNeededForNext,
    required this.isMaxLevel,
  });

  /// Kalkulasi progres level berdasarkan Eco-Points dan total kg nyata dari SQLite
  factory UserLevelProgression.fromStats({
    required int points,
    required double totalKg,
  }) {
    final sanitizedPoints = points < 0 ? 0 : points;
    final tiers = UserLevelTier.allTiers;

    UserLevelTier activeTier = tiers.first;
    UserLevelTier? upcomingTier;

    for (int i = 0; i < tiers.length; i++) {
      final tier = tiers[i];
      if (tier.maxPoints == -1) {
        if (sanitizedPoints >= tier.minPoints) {
          activeTier = tier;
          upcomingTier = null;
        }
      } else {
        if (sanitizedPoints >= tier.minPoints && sanitizedPoints <= tier.maxPoints) {
          activeTier = tier;
          upcomingTier = (i + 1 < tiers.length) ? tiers[i + 1] : null;
          break;
        }
      }
    }

    if (upcomingTier == null) {
      return UserLevelProgression(
        currentTier: activeTier,
        nextTier: null,
        currentPoints: sanitizedPoints,
        currentKg: totalKg,
        progressPercent: 1.0,
        pointsNeededForNext: 0,
        isMaxLevel: true,
      );
    }

    final pointsInCurrentBracket = sanitizedPoints - activeTier.minPoints;
    final bracketSpan = upcomingTier.minPoints - activeTier.minPoints;
    final progress = (bracketSpan > 0)
        ? (pointsInCurrentBracket / bracketSpan).clamp(0.0, 1.0)
        : 1.0;
    final pointsNeeded = (upcomingTier.minPoints - sanitizedPoints).clamp(0, upcomingTier.minPoints);

    return UserLevelProgression(
      currentTier: activeTier,
      nextTier: upcomingTier,
      currentPoints: sanitizedPoints,
      currentKg: totalKg,
      progressPercent: progress,
      pointsNeededForNext: pointsNeeded,
      isMaxLevel: false,
    );
  }
}
