import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper untuk meluncurkan komunikasi & integrasi ke Aplikasi TrashToCash Driver Terpisah
class ExternalDriverLauncher {
  static const String driverAppScheme = 'trashtocash-driver://';
  static const String driverPackageName = 'com.trashtocash.driver';

  /// Membuka aplikasi TrashToCash Driver eksternal dengan membawa ID order penjemputan
  static Future<void> openExternalDriverApp(
    BuildContext context, {
    required String transactionId,
    String? pin,
  }) async {
    final deepLink = '$driverAppScheme/order/$transactionId?pin=${pin ?? "8842"}';
    debugPrint('🚀 [ExternalDriverLauncher] Launching: $deepLink');

    // Menampilkan notifikasi info deep link
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0D6938),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Membuka Aplikasi TrashToCash Driver...\nDeep link: $deepLink',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Membuka obrolan WhatsApp resmi langsung ke nomor kurir driver
  static Future<void> openCourierWhatsApp(
    BuildContext context, {
    required String phoneNumber,
    required String courierName,
    required String transactionId,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : (cleanPhone.startsWith('62') ? cleanPhone : '62$cleanPhone');

    final message = Uri.encodeComponent(
      'Halo kak $courierName (Kurir TrashToCash), saya ingin menanyakan status penjemputan sampah untuk order: $transactionId.',
    );

    final waUrl = 'https://wa.me/$formattedPhone?text=$message';
    debugPrint('📱 [ExternalDriverLauncher] Open WhatsApp: $waUrl');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF25D366),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Membuka WhatsApp Kurir $courierName ($phoneNumber)...',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Membuka telepon langsung ke kurir
  static Future<void> callCourier(
    BuildContext context, {
    required String phoneNumber,
    required String courierName,
  }) async {
    HapticFeedback.lightImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0D6938),
          content: Text('Menghubungi telepon $courierName ($phoneNumber)...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Membuka Google Maps Navigation rute turn-by-turn langsung ke titik koordinat tujuan
  static Future<void> openGoogleMapsNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
    BuildContext? context,
  }) async {
    HapticFeedback.mediumImpact();
    final Uri googleMapsAppUri = Uri.parse(
      'google.navigation:q=$destinationLat,$destinationLng&mode=d',
    );
    final Uri googleMapsWebUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D6938),
            content: Text(
              'Membuka Google Maps ke ${destinationLabel ?? "titik koordinat"} ($destinationLat, $destinationLng)...',
            ),
          ),
        );
      }
    }
  }

  /// Membuka Google Maps pada titik lokasi drop point atau penjemputan
  static Future<void> openGoogleMapsLocation({
    required double lat,
    required double lng,
    String? title,
    BuildContext? context,
  }) async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening Google Maps location: $e');
    }
  }
}
