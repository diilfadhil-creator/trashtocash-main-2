import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/models/waste_item_model.dart';
import 'package:trashtocash/models/waste_pickup_model.dart';

void main() {
  group('Waste Database & Models Test', () {
    test('WasteItemModel correctly serializes and deserializes organic waste with handling tips', () {
      const item = WasteItemModel(
        id: 1,
        name: 'Sisa Makanan & Dapur',
        type: 'Organik',
        sampleItem: 'Sisa nasi, lauk pauk & hidangan basi',
        ratePerKg: 4.0,
        ecoPoints: 10,
        iconName: 'food',
        imageUrl: 'https://example.com/organic.jpg',
        description: 'Limbah sisa makanan dapur organik',
        handlingTip: 'Tiriskan air kuah dan buang plastik pembungkus sebelum disetor.',
      );

      final map = item.toMap();
      expect(map['name'], 'Sisa Makanan & Dapur');
      expect(map['type'], 'Organik');
      expect(map['rate_per_kg'], 4.0);
      expect(map['handling_tip'], 'Tiriskan air kuah dan buang plastik pembungkus sebelum disetor.');

      final fromMap = WasteItemModel.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.name, 'Sisa Makanan & Dapur');
      expect(fromMap.type, 'Organik');
      expect(fromMap.isOrganic, true);
      expect(fromMap.ratePerKg, 4.0);
      expect(fromMap.handlingTip, 'Tiriskan air kuah dan buang plastik pembungkus sebelum disetor.');
    });

    test('WasteItemModel correctly serializes and deserializes non-organic waste with handling tips', () {
      const item = WasteItemModel(
        id: 2,
        name: 'Plastik PET (Botol Mineral Bening)',
        type: 'Non-Organik',
        sampleItem: 'Botol air mineral bening',
        ratePerKg: 10.0,
        ecoPoints: 20,
        iconName: 'bottle',
        imageUrl: 'https://example.com/plastic.jpg',
        description: 'Botol plastik PET',
        handlingTip: 'Bilas bersih, lepas tutup botol & label plastik, lalu kempeskan botol.',
      );

      final map = item.toMap();
      expect(map['name'], 'Plastik PET (Botol Mineral Bening)');
      expect(map['type'], 'Non-Organik');
      expect(map['rate_per_kg'], 10.0);

      final fromMap = WasteItemModel.fromMap(map);
      expect(fromMap.id, 2);
      expect(fromMap.type, 'Non-Organik');
      expect(fromMap.isOrganic, false);
      expect(fromMap.handlingTip, 'Bilas bersih, lepas tutup botol & label plastik, lalu kempeskan botol.');
    });

    test('WastePickupModel correctly serializes and deserializes pickup transaction', () {
      const pickup = WastePickupModel(
        id: 10,
        transactionId: 'TRX-JMP-1234567',
        userId: 1,
        wasteName: 'Minyak Jelantah',
        wasteType: 'Organik',
        weightKg: 3.5,
        ratePerKg: 6.5,
        totalReward: 22.75,
        method: 'Jemput Sampah',
        pickupAddress: 'Jl. Sudirman No. 1, Jakarta',
        pickupDate: 'Besok (18 Agu)',
        pickupTime: '09:00 - 11:00 (Pagi)',
        pickupNotes: 'Di depan pagar',
        status: 'Menunggu Penjemputan',
        createdAt: '2026-08-18T09:00:00.000',
      );

      final map = pickup.toMap();
      expect(map['transaction_id'], 'TRX-JMP-1234567');
      expect(map['waste_name'], 'Minyak Jelantah');
      expect(map['waste_type'], 'Organik');
      expect(map['total_reward'], 22.75);

      final fromMap = WastePickupModel.fromMap(map);
      expect(fromMap.transactionId, 'TRX-JMP-1234567');
      expect(fromMap.wasteType, 'Organik');
      expect(fromMap.weightKg, 3.5);
      expect(fromMap.method, 'Jemput Sampah');
    });
  });
}
