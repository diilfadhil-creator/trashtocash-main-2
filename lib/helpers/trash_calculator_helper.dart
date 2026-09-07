import 'dart:math';

/// Metode Pengumpulan Sampah
enum CollectionMethod {
  /// Setor Langsung ke Drop Point Bank Sampah (Bonus +20% Eco Point, T-Cash Utuh 100%)
  dropOff,

  /// Jemput Sampah oleh Kurir (Eco Point Normal 1.0, T-Cash dipotong 15% / 0.85 untuk ongkir)
  pickup,
}

extension CollectionMethodExt on CollectionMethod {
  /// Label Bahasa Indonesia
  String get label {
    switch (this) {
      case CollectionMethod.dropOff:
        return 'Drop-off Mandiri';
      case CollectionMethod.pickup:
        return 'Jemput Sampah Kurir';
    }
  }

  /// Bonus Metode untuk Point Eco (1.2 untuk Drop-off, 1.0 untuk Jemput)
  double get bonusMetodeEco {
    switch (this) {
      case CollectionMethod.dropOff:
        return 1.2; // +20%
      case CollectionMethod.pickup:
        return 1.0; // Normal
    }
  }

  /// Konstanta Metode untuk Point T-Cash (1.0 untuk Drop-off, 0.85 untuk Jemput)
  double get konstantaMetodeTCash {
    switch (this) {
      case CollectionMethod.dropOff:
        return 1.0; // 100% Saldo Utuh
      case CollectionMethod.pickup:
        return 0.85; // 85% (Dipotong 15% untuk biaya kurir)
    }
  }
}

/// Tingkatan (Tier) Level Member Resmi TrashToCash
enum MemberTier {
  /// Bronze (0 – 999 Poin): Bonus T-Cash 0%, Bonus Eco Poin 0%
  bronze,

  /// Silver (1.000 – 4.999 Poin): Bonus T-Cash 0%, Bonus Eco Poin +5% (0.05)
  silver,

  /// Gold (5.000+ Poin): Bonus T-Cash +10% (0.10), Bonus Eco Poin +10% (0.10)
  gold,
}

extension MemberTierExt on MemberTier {
  String get nameLabel {
    switch (this) {
      case MemberTier.bronze:
        return 'Bronze';
      case MemberTier.silver:
        return 'Silver';
      case MemberTier.gold:
        return 'Gold';
    }
  }

  String get titleLabel {
    switch (this) {
      case MemberTier.bronze:
        return 'Anggota Bronze';
      case MemberTier.silver:
        return 'Anggota Silver';
      case MemberTier.gold:
        return 'Anggota Gold';
    }
  }

  /// Rentang Poin Minimal
  int get minPoints {
    switch (this) {
      case MemberTier.bronze:
        return 0;
      case MemberTier.silver:
        return 1000;
      case MemberTier.gold:
        return 5000;
    }
  }

  /// Rentang Poin Maksimal (-1 jika tertinggi)
  int get maxPoints {
    switch (this) {
      case MemberTier.bronze:
        return 999;
      case MemberTier.silver:
        return 4999;
      case MemberTier.gold:
        return -1;
    }
  }

  /// Bonus Persentase Eco Point
  double get bonusEco {
    switch (this) {
      case MemberTier.bronze:
        return 0.00; // 0%
      case MemberTier.silver:
        return 0.05; // +5%
      case MemberTier.gold:
        return 0.10; // +10%
    }
  }

  /// Bonus Persentase T-Cash
  double get bonusTCash {
    switch (this) {
      case MemberTier.bronze:
        return 0.00; // 0%
      case MemberTier.silver:
        return 0.00; // 0% (Catatan khusus: Silver T-Cash tetap 0%)
      case MemberTier.gold:
        return 0.10; // +10%
    }
  }

  /// Mendapatkan Tier berdasarkan jumlah total Eco-Points
  static MemberTier fromPoints(int points) {
    if (points >= 5000) {
      return MemberTier.gold;
    } else if (points >= 1000) {
      return MemberTier.silver;
    } else {
      return MemberTier.bronze;
    }
  }
}

/// Objek Hasil Kalkulasi Imbalan & Eco-Points TrashToCash
class CalculationResult {
  final double weightKg;
  final double ratePerKg;
  final double ecoWeightPerKg;
  final CollectionMethod method;
  final MemberTier tier;

  final int baseEcoPoints;
  final int finalEcoPoints;

  final double baseTCashReward;
  final double finalTCashReward;

  const CalculationResult({
    required this.weightKg,
    required this.ratePerKg,
    required this.ecoWeightPerKg,
    required this.method,
    required this.tier,
    required this.baseEcoPoints,
    required this.finalEcoPoints,
    required this.baseTCashReward,
    required this.finalTCashReward,
  });

  /// Bonus Eco Point murni dari level member
  int get ecoBonusFromLevel => finalEcoPoints - baseEcoPoints;

  /// Bonus T-Cash murni dari level member (Rupiah)
  double get tCashBonusFromLevel => finalTCashReward - baseTCashReward;
}

/// Engine Kalkulator Resmi TrashToCash
class TrashToCashCalculator {
  TrashToCashCalculator._();

  /// Perhitungan Point Eco Resmi:
  /// Point Eco = (Berat * Bobot Eco * Bonus Metode) * (1 + Bonus Level Member)
  static int calculateEcoPoints({
    required double weightKg,
    double ecoWeightPerKg = 10.0,
    required CollectionMethod method,
    required int currentMemberPoints,
  }) {
    final tier = MemberTierExt.fromPoints(currentMemberPoints);
    final double rawMetodePoints = weightKg * ecoWeightPerKg * method.bonusMetodeEco;
    final double totalEcoPoints = rawMetodePoints * (1.0 + tier.bonusEco);
    return max(0, totalEcoPoints.round());
  }

  /// Perhitungan Point T-Cash Resmi:
  /// Point T-Cash = (Berat * Tarif Sampah) * Konstanta Metode * (1 + Bonus Level Member)
  static double calculateTCashReward({
    required double weightKg,
    required double ratePerKg,
    required CollectionMethod method,
    required int currentMemberPoints,
  }) {
    final tier = MemberTierExt.fromPoints(currentMemberPoints);
    final double baseReward = weightKg * ratePerKg;
    final double afterMethodReward = baseReward * method.konstantaMetodeTCash;
    final double totalTCash = afterMethodReward * (1.0 + tier.bonusTCash);
    return max(0.0, totalTCash);
  }

  /// Mendapatkan Rincian Hasil Perhitungan Lengkap
  static CalculationResult calculateResult({
    required double weightKg,
    required double ratePerKg,
    double ecoWeightPerKg = 10.0,
    required CollectionMethod method,
    required int currentMemberPoints,
  }) {
    final tier = MemberTierExt.fromPoints(currentMemberPoints);

    // 1. Calculations for Eco Points
    final double rawMetodeEco = weightKg * ecoWeightPerKg * method.bonusMetodeEco;
    final int baseEco = rawMetodeEco.round();
    final int finalEco = (rawMetodeEco * (1.0 + tier.bonusEco)).round();

    // 2. Calculations for T-Cash
    final double baseTCash = weightKg * ratePerKg * method.konstantaMetodeTCash;
    final double finalTCash = baseTCash * (1.0 + tier.bonusTCash);

    return CalculationResult(
      weightKg: weightKg,
      ratePerKg: ratePerKg,
      ecoWeightPerKg: ecoWeightPerKg,
      method: method,
      tier: tier,
      baseEcoPoints: baseEco,
      finalEcoPoints: max(0, finalEco),
      baseTCashReward: baseTCash,
      finalTCashReward: max(0.0, finalTCash),
    );
  }
}
