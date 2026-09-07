import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper terpusat untuk memutar efek suara koin cuan, transaksi, dan haptic feedback
class SoundHelper {
  static AudioPlayer? _player;

  static AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Memutar efek suara koin berdenting saat saldo masuk (Setoran Sampah / Bonus Reward)
  /// [force] : Jika true, memutar suara mengabaikan preferensi toggle (digunakan untuk tombol tes)
  static Future<void> playCoinSound({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = force || (prefs.getBool('notif_sound_coin') ?? true);
      final hapticEnabled = prefs.getBool('appHapticFeedback') ?? true;

      // Haptic Feedback getaran koin
      if (hapticEnabled) {
        HapticFeedback.heavyImpact();
      }

      if (!soundEnabled) return;

      // Stop previous playback if any
      await player.stop();
      await player.setVolume(1.0);
      
      // Play asset audio
      await player.play(AssetSource('sounds/coin_cuan.wav'));
    } catch (e) {
      debugPrint('Error playing coin sound: $e');
      // Fallback ke system sound & haptic jika asset player bermasalah
      try {
        await SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  /// Memutar efek suara saat penarikan saldo berhasil
  static Future<void> playWithdrawalSuccessSound({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = force || (prefs.getBool('notif_withdrawal_success') ?? true);
      final hapticEnabled = prefs.getBool('appHapticFeedback') ?? true;

      if (hapticEnabled) {
        HapticFeedback.mediumImpact();
      }

      if (!soundEnabled) return;

      await player.stop();
      await player.setVolume(0.9);
      await player.play(AssetSource('sounds/coin_cuan.wav'));
    } catch (e) {
      debugPrint('Error playing withdrawal sound: $e');
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Tes preview suara koin dengan animasi snackbar konfirmasi
  static Future<void> previewCoinSound(BuildContext context) async {
    await playCoinSound(force: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0D6938),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kringgg! 🪙 Efek suara koin cuan berhasil diputar!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
