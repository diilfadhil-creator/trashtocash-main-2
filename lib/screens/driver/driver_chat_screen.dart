import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trashtocash/helpers/chat_sync_helper.dart';
import 'package:trashtocash/models/driver_model.dart';

class DriverChatScreen extends StatefulWidget {
  final DriverOrderItemModel order;

  const DriverChatScreen({super.key, required this.order});

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _driverQuickReplies = [
    '👋 Halo kak, saya sedang menuju ke lokasi ya',
    '📍 Saya sudah sampai di depan rumah/pagar ya',
    '⏳ Mohon tunggu sekitar 2-3 menit lagi',
    '📦 Mohon pastikan sampah sudah siap ditimbang ya',
    '🔔 Saya coba telepon ya kak jika belum keluar',
  ];

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
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

  void _sendDriverMessage(String text, {String? imagePath}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty && imagePath == null) return;

    ChatSyncHelper.instance.sendMessage(
      senderRole: 'driver',
      text: cleanText,
      imagePath: imagePath,
    );

    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 80);
      if (photo != null) {
        _sendDriverMessage('', imagePath: photo.path);
      }
    } catch (e) {
      debugPrint('Error picking chat image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121915) : const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6938),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.order.userName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Penyetor Sampah • ${widget.order.wasteName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
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
            tooltip: 'Telepon Warga',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungi ${widget.order.userPhone}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Order Context Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEAF4EE),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF0D6938), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.order.userAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : const Color(0xFF0D6938),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ValueListenableBuilder<List<SyncChatMessage>>(
              valueListenable: ChatSyncHelper.instance.messagesNotifier,
              builder: (context, messages, _) {
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                );
              },
            ),
          ),

          // Quick Replies
          _buildQuickRepliesBar(isDark),

          // Chat Input Field
          _buildChatInputField(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SyncChatMessage msg, bool isDark) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }

    // In Driver Chat:
    // If msg.senderRole == 'driver', it is from the current user (isSender = true)
    // If msg.senderRole == 'user', it is from the customer (isSender = false)
    final bool isFromMe = msg.isFromDriver;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFromMe
              ? const Color(0xFF0D6938)
              : (isDark ? const Color(0xFF263229) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isFromMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isFromMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFromMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.order.userName,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6938),
                  ),
                ),
              ),
            if (msg.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(msg.imagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13,
                  color: isFromMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isFromMe ? Colors.white60 : Colors.grey,
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar(bool isDark) {
    return Container(
      height: 42,
      color: isDark ? const Color(0xFF18221C) : Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _driverQuickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final reply = _driverQuickReplies[idx];
          return ActionChip(
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF0D6938),
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF263229)
                : const Color(0xFFEAF4EE),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => _sendDriverMessage(reply),
          );
        },
      ),
    );
  }

  Widget _buildChatInputField(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D6938)),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_outlined, color: Color(0xFF0D6938)),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan untuk warga...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF263229) : const Color(0xFFF4F8F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (text) => _sendDriverMessage(text),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0D6938),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _sendDriverMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
