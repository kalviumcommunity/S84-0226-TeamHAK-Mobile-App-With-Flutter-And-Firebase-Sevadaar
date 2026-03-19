import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../state/chat_provider.dart';

class _C {
  static const bg = Color(0xFFEEF2F8);
  static const blue = Color(0xFF4A6CF7);
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
}

class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatModel chat;
  final UserModel currentUser;

  const ChatRoomScreen({
    super.key,
    required this.chat,
    required this.currentUser,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      final service = ref.read(chatServiceProvider);
      await service.sendMessage(
        chatId: widget.chat.chatId,
        sender: widget.currentUser,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  /// Shows a modal dialog listing all participants with avatar + role
  void _showParticipantsDialog(List<UserModel> participants) {
    final title = widget.chat.title ?? 'Chat';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: _C.blue, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _C.textPri,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: _C.textSec, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                '${participants.length} member${participants.length == 1 ? '' : 's'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _C.textSec,
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // ── Participant list ─────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final user = participants[i];
                    final isMe = user.uid == widget.currentUser.uid;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: _C.blue.withValues(alpha: 0.12),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            color: _C.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _C.textPri,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _C.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        _formatRole(user.role),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _C.textSec,
                        ),
                      ),
                      trailing: _roleChip(user.role),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'developer_admin':
        return 'Developer Admin';
      case 'admin':
        return 'Admin';
      case 'volunteer':
        return 'Volunteer';
      default:
        return role
            .split('_')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  Widget? _roleChip(String role) {
    Color bg;
    Color fg;
    switch (role) {
      case 'super_admin':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'developer_admin':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
      case 'admin':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      default:
        return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatRole(role),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chat.title ?? 'Chat';
    final isGroup = widget.chat.type == 'group';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.chatId));

    // Only fetch participants for group chats
    final participantsAsync = isGroup
        ? ref.watch(chatParticipantsProvider(widget.chat.chatId))
        : null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: GestureDetector(
          // Tap the title area to open members popup (group only)
          onTap: isGroup
              ? () {
                  participantsAsync?.whenData(
                    (users) => _showParticipantsDialog(users),
                  );
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Chat title ────────────────────────────────────────────
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: _C.textPri,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              // ── Participant names subtitle (group only) ───────────────
              if (isGroup)
                participantsAsync!.when(
                  data: (participants) {
                    final others = participants
                        .where((u) => u.uid != widget.currentUser.uid)
                        .toList();
                    if (others.isEmpty) return const SizedBox.shrink();

                    final preview = others
                        .take(3)
                        .map((u) => u.name.split(' ').first)
                        .join(', ');
                    final extra = others.length > 3
                        ? ' +${others.length - 3} more'
                        : '';

                    return Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 11,
                          color: _C.blue,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '$preview$extra',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _C.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _C.blue,
                        ),
                      ],
                    );
                  },
                  loading: () => Text(
                    'Loading members...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.textSec,
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: _C.textPri),
        // ── Members icon button (group only) ──────────────────────────
        actions: isGroup
            ? [
                participantsAsync!.when(
                  data: (users) => IconButton(
                    icon: const Icon(Icons.people_outline, color: _C.textSec),
                    tooltip: 'View members',
                    onPressed: () => _showParticipantsDialog(users),
                  ),
                  loading: () => const SizedBox(
                    width: 48,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: TextStyle(color: _C.textSec),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUser.uid;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (widget.chat.isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: _C.textSec),
              const SizedBox(width: 8),
              Text(
                'This chat is locked (Task Completed).',
                style: GoogleFonts.plusJakartaSans(
                  color: _C.textSec,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment
              .end, // aligns send button to bottom when text grows
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null, // ← allows vertical growth
                minLines: 1, // ← starts as single line
                keyboardType: TextInputType.multiline, // ← multiline keyboard
                textInputAction:
                    TextInputAction.newline, // ← Enter adds new line
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: _C.textSec),
                  filled: true,
                  fillColor: _C.bg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: _C.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textSec,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (message.senderRole == 'admin' ||
                      message.senderRole == 'super_admin' ||
                      message.senderRole == 'developer_admin')
                    _RoleLabel(role: message.senderRole),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _C.blue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : _C.textPri,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8, left: 8),
            child: Text(
              DateFormat('hh:mm a').format(message.createdAt),
              style: const TextStyle(fontSize: 10, color: _C.textSec),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleLabel extends StatelessWidget {
  final String role;
  const _RoleLabel({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String displayRole;

    switch (role) {
      case 'super_admin':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayRole = 'Super Admin';
        break;
      case 'developer_admin':
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        displayRole = 'Developer';
        break;
      case 'admin':
      default:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayRole = 'Admin';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
