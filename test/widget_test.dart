import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashtocash/screens/panduan_sampah_screen.dart';

void main() {
  testWidgets('PanduanDaurUlangScreen renders correctly and shows tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PanduanDaurUlangScreen(initialTabIndex: 0),
      ),
    );

    // Verify Title and Tabs
    expect(find.text('Panduan Daur Ulang'), findsOneWidget);
    expect(find.text('Scan Foto AI'), findsOneWidget);
    expect(find.text('Organik'), findsOneWidget);
    expect(find.text('Non-Organik'), findsOneWidget);
    expect(find.text('FAQ & Tips 3R'), findsOneWidget);

    // Verify AI photo scan guide content
    expect(find.text('Deteksi Sampah Otomatis\nHanya dengan Foto 📸'), findsOneWidget);
    expect(find.text('5 Langkah Mudah Menggunakan Fitur Scan Foto'), findsOneWidget);
    expect(find.text('Coba Scan Foto Sekarang'), findsOneWidget);
  });

  testWidgets('PanduanDaurUlangScreen opens with initial tab 1 (Organik)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PanduanDaurUlangScreen(initialTabIndex: 1),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Apa itu Sampah Organik?'), findsOneWidget);
    expect(find.text('Kategori Sampah Organik yang Diterima'), findsOneWidget);
  });
}
