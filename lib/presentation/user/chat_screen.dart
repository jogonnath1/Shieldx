import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/message_service.dart';
import '../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/date_time_extensions.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String complaintId;
  const ChatScreen({super.key, required this.complaintId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final MessageService _service;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _service = MessageService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      try {
        debugPrint('MARK AS READ: marking messages for complaint ${widget.complaintId} by user ${currentUser.id}');
        await _service.markAsRead(widget.complaintId, currentUser.id);
        debugPrint('MARK AS READ: successfully marked as read');
      } catch (e, st) {
        debugPrint('MARK AS READ ERROR: $e\n$st');
      }
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _isSending = true);
    final profile = ref.read(authNotifierProvider).valueOrNull;
    if (profile == null) return;
    try {
      await _service.sendMessage(
        complaintId: widget.complaintId,
        senderId: profile.id,
        senderRole: profile.role,
        content: text,
      );
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my-complaints');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _service.watchMessages(widget.complaintId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final msgs = snap.data ?? [];
                  if (msgs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: AppColors.textHint, size: 48),
                          const SizedBox(height: 12),
                          Text('No messages yet.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Start a conversation with the admin.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                    _markMessagesAsRead();
                  });
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg = msgs[i];
                      final isMe = msg.senderId == profile?.id;
                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                      ).animate().fadeIn(duration: 200.ms).slideY(
                            begin: 0.1,
                            duration: 200.ms,
                          );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        fillColor: AppColors.surfaceLight,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings,
                  size: 16, color: AppColors.primary),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? AppColors.primaryGradient
                    : const LinearGradient(colors: [
                        AppColors.surfaceLight,
                        AppColors.surfaceLight
                      ]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content ?? '',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                    message.sentAt != null
                        ? DateFormat('hh:mm a').format(message.sentAt!.toBangladeshTime())
                        : '',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
