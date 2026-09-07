import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/models/user_level_model.dart';

void main() {
  group('User Level & Tier Progression Model Tests', () {
    test('Eco Starter (Level 1) calculated for 0 - 49 Eco-Points', () {
      final p1 = UserLevelProgression.fromStats(points: 0, totalKg: 0.0);
      expect(p1.currentTier.level, 1);
      expect(p1.currentTier.name, 'Eco Starter');
      expect(p1.isMaxLevel, isFalse);
      expect(p1.progressPercent, 0.0);
      expect(p1.pointsNeededForNext, 50);

      final p2 = UserLevelProgression.fromStats(points: 25, totalKg: 2.5);
      expect(p2.currentTier.level, 1);
      expect(p2.progressPercent, 0.5);
      expect(p2.pointsNeededForNext, 25);
    });

    test('Eco Saver (Level 2) calculated for 50 - 149 Eco-Points', () {
      final p = UserLevelProgression.fromStats(points: 50, totalKg: 5.0);
      expect(p.currentTier.level, 2);
      expect(p.currentTier.name, 'Eco Saver');
      expect(p.nextTier?.name, 'Eco Warrior');
      expect(p.pointsNeededForNext, 100);
    });

    test('Eco Warrior (Level 3) calculated for 150 - 349 Eco-Points', () {
      final p = UserLevelProgression.fromStats(points: 200, totalKg: 20.0);
      expect(p.currentTier.level, 3);
      expect(p.currentTier.name, 'Eco Warrior');
      expect(p.nextTier?.name, 'Eco Hero');
      expect(p.pointsNeededForNext, 150);
    });

    test('Eco Hero (Level 4) calculated for 350 - 749 Eco-Points', () {
      final p = UserLevelProgression.fromStats(points: 550, totalKg: 55.0);
      expect(p.currentTier.level, 4);
      expect(p.currentTier.name, 'Eco Hero');
      expect(p.nextTier?.name, 'Eco Legend');
      expect(p.pointsNeededForNext, 200);
    });

    test('Eco Legend (Level 5) max tier calculated for 750+ Eco-Points', () {
      final p = UserLevelProgression.fromStats(points: 800, totalKg: 80.0);
      expect(p.currentTier.level, 5);
      expect(p.currentTier.name, 'Eco Legend');
      expect(p.isMaxLevel, isTrue);
      expect(p.nextTier, isNull);
      expect(p.progressPercent, 1.0);
      expect(p.pointsNeededForNext, 0);
    });
  });
}
