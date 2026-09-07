import 'package:flutter/foundation.dart';
import 'package:trashtocash/helpers/database_helper.dart';

class SyncChatMessage {
  final String id;
  final String senderRole; // 'user' or 'driver' or 'system'
  final String text;
  final DateTime timestamp;
  final String? imagePath;
  final bool isSystem;

  SyncChatMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.imagePath,
    this.isSystem = false,
  });

  bool get isFromUser => senderRole == 'user';
  bool get isFromDriver => senderRole == 'driver';
}

/// Helper sinkronisasi chat dua arah secara real-time antara Aplikasi Pengguna dan Aplikasi Driver terhubung SQLite Database
class ChatSyncHelper {
  static final ChatSyncHelper instance = ChatSyncHelper._internal();
  ChatSyncHelper._internal() {
    loadMessagesFromDatabase();
  }

  final ValueNotifier<List<SyncChatMessage>> messagesNotifier =
      ValueNotifier<List<SyncChatMessage>>([]);

  Future<void> loadMessagesFromDatabase() async {
    try {
      final dbMsgs = await DatabaseHelper.instance.getChatMessages();
      if (dbMsgs.isNotEmpty) {
        final items = dbMsgs.map((m) {
          return SyncChatMessage(
            id: m['msg_id'] as String? ?? 'msg_${m['id']}',
            senderRole: m['sender_role'] as String? ?? 'user',
            text: m['text'] as String? ?? '',
            timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
            imagePath: m['image_path'] as String?,
            isSystem: (m['is_system'] as int? ?? 0) == 1,
          );
        }).toList();
        messagesNotifier.value = items;
      } else {
        _initDefaultMessages();
      }
    } catch (_) {
      _initDefaultMessages();
    }
  }

  void _initDefaultMessages() {
    if (messagesNotifier.value.isEmpty) {
      messagesNotifier.value = [
        SyncChatMessage(
          id: 'sys_1',
          senderRole: 'system',
          text:
              'Penjemputan dimulai. Pengguna terhubung dengan Mitra Kurir resmi TrashToCash.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          isSystem: true,
        ),
        SyncChatMessage(
          id: 'msg_1',
          senderRole: 'driver',
          text:
              'Halo kak! Saya Budi Santoso, mitra kurir TrashToCash. Saya sedang menuju ke lokasi penjemputan ya (estimasi 10-15 menit). Mohon pastikan sampah sudah siap.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ];
    }
  }

  Future<void> sendMessage({
    required String senderRole,
    required String text,
    String? imagePath,
  }) async {
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newMsg = SyncChatMessage(
      id: msgId,
      senderRole: senderRole,
      text: text,
      timestamp: now,
      imagePath: imagePath,
    );

    final currentList = List<SyncChatMessage>.from(messagesNotifier.value);
    currentList.add(newMsg);
    messagesNotifier.value = currentList;

    try {
      await DatabaseHelper.instance.insertChatMessage(
        msgId: msgId,
        senderRole: senderRole,
        text: text,
        imagePath: imagePath,
        timestamp: now,
      );
    } catch (_) {}
  }

  Future<void> clearMessages() async {
    messagesNotifier.value = [];
    try {
      await DatabaseHelper.instance.clearChatMessages();
    } catch (_) {}
    _initDefaultMessages();
  }
}
