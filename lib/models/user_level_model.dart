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

  /// Daftar lengkap 3 level tingkatan resmi TrashToCash (Bronze, Silver, Gold)
  static const List<UserLevelTier> allTiers = [
    UserLevelTier(
      level: 1,
      name: 'Bronze',
      title: 'Member Bronze',
      minPoints: 0,
      maxPoints: 999,
      minKg: 0.0,
      primaryColor: Color(0xFFCD7F32),
      backgroundColor: Color(0xFFFBEFE6),
      icon: Icons.workspace_premium_outlined,
      bonusBadge: 'Bronze (0%)',
      benefits: [
        'Point Eco Normal (1.0x Jemput / 1.2x Drop-off)',
        'T-Cash Normal (100% Drop-off / 85% Jemput)',
        'Penarikan Saldo ke Rekening Bank & E-Wallet',
      ],
    ),
    UserLevelTier(
      level: 2,
      name: 'Silver',
      title: 'Member Silver',
      minPoints: 1000,
      maxPoints: 4999,
      minKg: 10.0,
      primaryColor: Color(0xFF757575),
      backgroundColor: Color(0xFFF5F5F5),
      icon: Icons.military_tech_outlined,
      bonusBadge: 'Bonus Eco +5%',
      benefits: [
        'Semua keuntungan Member Bronze',
        'Bonus Tambahan +5% Point Eco',
        'T-Cash Tetap Normal (0% Bonus T-Cash)',
        'Badge Profil Silver Member',
      ],
    ),
    UserLevelTier(
      level: 3,
      name: 'Gold',
      title: 'Member Gold',
      minPoints: 5000,
      maxPoints: -1,
      minKg: 50.0,
      primaryColor: Color(0xFFFFB300),
      backgroundColor: Color(0xFFFFF8E1),
      icon: Icons.stars_rounded,
      bonusBadge: 'Bonus All +10%',
      benefits: [
        'Semua keuntungan Member Silver',
        'Bonus Tambahan +10% Point T-Cash',
        'Bonus Tambahan +10% Point Eco',
        'Prioritas penjemputan kurir cepat',
        'Badge Profil Gold Member Eksklusif',
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
