import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashtocash/helpers/chat_sync_helper.dart';
import 'package:trashtocash/helpers/database_helper.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isSender;
  final DateTime timestamp;
  final String? imagePath;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isSender,
    required this.timestamp,
    this.imagePath,
    this.isSystem = false,
  });
}

class CourierChatScreen extends StatefulWidget {
  final String courierName;
  final String courierId;
  final double courierRating;
  final String categoryName;
  final double weightKg;
  final double estimatedReward;
  final String pickupPin;

  const CourierChatScreen({
    super.key,
    this.courierName = 'Budi Santoso',
    this.courierId = 'T2C-8842',
    this.courierRating = 4.9,
    this.categoryName = 'Plastik (PET)',
    this.weightKg = 2.5,
    this.estimatedReward = 25.0,
    this.pickupPin = '8842',
  });

  @override
  State<CourierChatScreen> createState() => _CourierChatScreenState();
}

class _CourierChatScreenState extends State<CourierChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isCourierTyping = false;
  bool _isSummaryExpanded = true;
  final List<ChatMessage> _messages = [];

  final List<String> _quickReplies = [
    '👋 Saya sudah siap di depan rumah',
    '📦 Sampah sudah ditaruh di dekat pagar',
    '📍 Posisi kurir sudah sampai mana ya?',
    '⏳ Mohon tunggu sebentar ya',
    '🔔 Tolong telepon jika sudah tiba',
  ];

  @override
  void initState() {
    super.initState();
    _initDefaultMessages();
    ChatSyncHelper.instance.messagesNotifier.addListener(_syncFromBus);
  }

  void _syncFromBus() {
    final busMessages = ChatSyncHelper.instance.messagesNotifier.value;
    if (busMessages.isNotEmpty && mounted) {
      final lastMsg = busMessages.last;
      // If last message is from driver and not in local list
      final alreadyExists = _messages.any((m) => m.id == lastMsg.id);
      if (!alreadyExists) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: lastMsg.id,
              text: lastMsg.text,
              isSender: lastMsg.isFromUser,
              timestamp: lastMsg.timestamp,
              imagePath: lastMsg.imagePath,
              isSystem: lastMsg.isSystem,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _initDefaultMessages() {
    _messages.addAll([
      ChatMessage(
        id: 'sys_1',
        text: 'Penjemputan dimulai. Anda terhubung dengan kurir resmi mitra TrashToCash.',
        isSender: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        isSystem: true,
      ),
      ChatMessage(
        id: 'msg_1',
        text: 'Halo kak! Saya ${widget.courierName}, kurir mitra TrashToCash. Saya sedang menuju ke lokasi penjemputan ya (estimasi 10-15 menit). Mohon pastikan sampah sudah siap.',
        isSender: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);
  }

  @override
  void dispose() {
    ChatSyncHelper.instance.messagesNotifier.removeListener(_syncFromBus);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, {String? imagePath}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty && imagePath == null) return;

    HapticFeedback.lightImpact();

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMessage = ChatMessage(
      id: msgId,
      text: cleanText,
      isSender: true,
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );

    setState(() {
      _messages.add(newMessage);
      _textController.clear();
    });

    // Send to ChatSyncHelper so Driver app receives it in real time
    ChatSyncHelper.instance.sendMessage(
      senderRole: 'user',
      text: cleanText,
      imagePath: imagePath,
    );

    _scrollToBottom();
    _simulateCourierReply(cleanText);
  }

  void _simulateCourierReply(String userMessage) {
    // Show typing state after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isCourierTyping = true);
      _scrollToBottom();

      // Reply after 1.8 seconds
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;

        String replyText;
        final lower = userMessage.toLowerCase();

        if (lower.contains('posisi') || lower.contains('mana') || lower.contains('dimana')) {
          replyText = 'Siap kak! Saya sudah lewat Jl. Sudirman dekat minimarket, sekitar 3-5 menit lagi sampai ya!';
        } else if (lower.contains('pagar') || lower.contains('teras') || lower.contains('depan')) {
          replyText = 'Baik kak, terima kasih! Begitu tiba langsung saya ambil dan timbang di depan ya 👍';
        } else if (lower.contains('tunggu') || lower.contains('sebentar')) {
          replyText = 'Siap kak, santai saja. Nanti kabari kalau sudah siap ya.';
        } else if (lower.contains('telepon') || lower.contains('hubungi')) {
          replyText = 'Siap kak, begitu sampai di depan rumah akan langsung saya telepon.';
        } else if (lower.contains('pin') || lower.contains('kode')) {
          replyText = 'Baik kak, nanti kode PIN penyerahan (${widget.pickupPin}) bisa diberikan saat sampah ditimbang ya.';
        } else {
          replyText = 'Siap kak, pesan diterima! Saya sedang fokus berkendara menuju lokasi Anda.';
        }

        setState(() {
          _isCourierTyping = false;
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: replyText,
              isSender: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        HapticFeedback.mediumImpact();
        _scrollToBottom();
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _sendMessage('Foto sampah / lokasi', imagePath: pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kirim Lampiran ke Kurir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: const Color(0xFF0D6938),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: Colors.blue.shade700,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.location_on_rounded,
                  label: 'Kirim Alamat',
                  color: Colors.orange.shade700,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMessage('📍 Patokan: Rumah pagar hijau di samping ruko');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/trashtocash_logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFEAF4EE),
                child: Icon(Icons.person, color: Color(0xFF0D6938), size: 38),
              ),
              const SizedBox(height: 14),
              Text(
                widget.courierName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${widget.courierId} • +62 812-8842-9910',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Honda Beat Hijau • B 4812 TZC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D6938),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6938),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Menghubungi ${widget.courierName} (+62 812-8842-9910)...',
                            ),
                            backgroundColor: const Color(0xFF0D6938),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                      label: const Text(
                        'Panggil',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101813) : const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courierName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isCourierTyping ? 'Sedang mengetik...' : 'Kurir Mitra • Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isCourierTyping
                          ? const Color(0xFFA7F3D0)
                          : Colors.white.withValues(alpha: 0.8),
                      fontWeight:
                          _isCourierTyping ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
            tooltip: 'Hubungi Kurir',
            onPressed: _showCallModal,
          ),
          IconButton(
            icon: Icon(
              _isSummaryExpanded ? Icons.info : Icons.info_outline,
              color: Colors.white,
            ),
            tooltip: 'Rincian Penjemputan',
            onPressed: () {
              setState(() => _isSummaryExpanded = !_isSummaryExpanded);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Pickup Summary Banner
          if (_isSummaryExpanded) _buildPickupSummaryBanner(isDark),

          // Message Stream List with Background Logo Watermark
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle Branded Background Logo Watermark
                Opacity(
                  opacity: isDark ? 0.06 : 0.08,
                  child: Image.asset(
                    'assets/images/trashtocash_logo.png',
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),

                // Message List
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildTopVerifiedBrandCard(isDark);
                    }
                    final message = _messages[index - 1];
                    if (message.isSystem) {
                      return _buildSystemMessage(message);
                    }
                    return _buildChatBubble(message, isDark);
                  },
                ),
              ],
            ),
          ),

          // Typing Indicator
          if (_isCourierTyping)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2822) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.courierName} sedang mengetik',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Replies Horizontal Chips
          _buildQuickRepliesSection(isDark),

          // Chat Input Box
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildTopVerifiedBrandCard(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16241B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(
              0xFF0D6938,
            ).withValues(alpha: isDark ? 0.35 : 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/trashtocash_logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Color(0xFF0D6938)),
                SizedBox(width: 5),
                Text(
                  'TrashToCash Official Courier Chat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6938),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Percakapan terenkripsi & dipantau untuk menjamin keamanan penjemputan sampah Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSummaryBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16241B) : const Color(0xFFEAF4EE),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0D6938).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0D6938).withValues(alpha: 0.25),
              ),
            ),
            child: Image.asset(
              'assets/images/trashtocash_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.categoryName} (${widget.weightKg} kg) • +${DatabaseHelper.formatRupiah(widget.estimatedReward)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D6938),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'KODE PIN PENYERAHAN: ${widget.pickupPin}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isSummaryExpanded = false),
            child: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    final isSender = message.isSender;
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSender
              ? const Color(0xFF0D6938)
              : (isDark ? const Color(0xFF1E2822) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSender ? 16 : 4),
            bottomRight: Radius.circular(isSender ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: File(message.imagePath!).existsSync()
                    ? Image.file(
                        File(message.imagePath!),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: isSender
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSender
                        ? Colors.white.withValues(alpha: 0.75)
                        : Colors.grey.shade500,
                  ),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 13,
                    color: Color(0xFF86EFAC),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesSection(bool isDark) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF0D6938),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF14241B)
                : const Color(0xFFEAF4EE),
            side: BorderSide(
              color: const Color(0xFF0D6938).withValues(alpha: 0.25),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => _sendMessage(reply),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16241B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D6938).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF0D6938),
                size: 22,
              ),
              onPressed: _showAttachmentOptions,
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101813) : const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan untuk kurir...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (val) => _sendMessage(val),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D6938),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
