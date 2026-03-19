import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../state/chat_provider.dart';
import '../../state/auth_provider.dart';
import 'chat_room_screen.dart';
import 'archived_chats_screen.dart';

class _C {
  static const bg = Color(0xFFEEF2F8);
  static const blue = Color(0xFF4A6CF7);
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
}

class ChatListScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String? _activeNgoId;
  bool _isLoadingNgo = true;

  @override
  void initState() {
    super.initState();
    _resolveNgoId();
  }

  Future<void> _resolveNgoId() async {
    if (widget.currentUser.ngoId != null && widget.currentUser.ngoId!.isNotEmpty) {
      setState(() {
        _activeNgoId = widget.currentUser.ngoId;
        _isLoadingNgo = false;
      });
      return;
    }

    if (widget.currentUser.role == 'super_admin') {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('ngos')
            .where('superAdminId', isEqualTo: widget.currentUser.uid)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          setState(() {
            _activeNgoId = snap.docs.first.id;
            _isLoadingNgo = false;
          });
          return;
        }
      } catch (e) {
        // Ignore and let it fall through to empty state
      }
    }

    setState(() {
      _isLoadingNgo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingNgo) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeNgoId == null || _activeNgoId!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('You are not associated with an NGO yet.')),
      );
    }

    final chatsAsync = ref.watch(
      userChatsProvider(
        ChatParams(uid: widget.currentUser.uid, ngoId: _activeNgoId!),
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Active Chats',
          style: GoogleFonts.plusJakartaSans(
            color: _C.textPri,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: _C.textSec),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArchivedChatsScreen(currentUser: widget.currentUser),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStartChatModal(context, ref),
        backgroundColor: _C.blue,
        child: const Icon(Icons.message_rounded, color: Colors.white),
      ),
      body: chatsAsync.when(
        data: (allChats) {
          final activeChats = allChats
              .where((c) => !c.archivedBy.contains(widget.currentUser.uid))
              .toList();

          if (activeChats.isEmpty) {
            return const Center(
              child: Text(
                'No active conversations.',
                style: TextStyle(color: _C.textSec),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: activeChats.length,
            itemBuilder: (context, index) {
              final chat = activeChats[index];
              return _ChatTile(chat: chat, currentUser: widget.currentUser);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showStartChatModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final userService = ref.read(userServiceProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _C.textPri,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: userService.streamNgoMembers(_activeNgoId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users =
                        snapshot.data
                            ?.where((u) => u.uid != widget.currentUser.uid)
                            .toList() ??
                        [];
                    if (users.isEmpty) {
                      return const Center(
                        child: Text('No other members found.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _C.blue.withValues(alpha: 0.1),
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(color: _C.blue),
                            ),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.role),
                          onTap: () async {
                            Navigator.pop(context);
                            final service = ref.read(chatServiceProvider);
                            final chatId = await service.createOrGetDirectChat(
                              currentUserUid: widget.currentUser.uid,
                              targetUserUid: user.uid,
                              ngoId: _activeNgoId!,
                            );

                            final tempChat = ChatModel(
                              chatId: chatId,
                              type: 'direct',
                              title: user.name,
                              ngoId: _activeNgoId!,
                              participants: [widget.currentUser.uid, user.uid],
                              lastMessage: '',
                              lastMessageTime: DateTime.now(),
                              isArchived: false,
                              isLocked: false,
                              unreadCounts: {},
                              archivedBy: [],
                              deletedBy: [],
                            );
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    chat: tempChat,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted tile widget so it can watch its own provider
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final UserModel currentUser;

  const _ChatTile({required this.chat, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = chat.type == 'group';
    final title = chat.title ?? 'Chat';
    final unreadCount = chat.unreadCounts[currentUser.uid] ?? 0;

    // Watch participant names for this chat
    final participantsAsync = ref.watch(chatParticipantsProvider(chat.chatId));

    return Dismissible(
      key: Key(chat.chatId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: _C.orange.withValues(alpha: 0.8),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _C.red.withValues(alpha: 0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        final chatService = ref.read(chatServiceProvider);
        if (direction == DismissDirection.startToEnd) {
          await chatService.archiveChat(chat.chatId, currentUser.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$title archived')));
          }
        } else {
          await chatService.deleteChat(chat.chatId, currentUser.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$title deleted')));
          }
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: isGroup
                ? _C.blue.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            child: Icon(
              isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: isGroup ? _C.blue : _C.textSec,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
              fontSize: 16,
              color: _C.textPri,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Participant names preview ──────────────────────────────
              participantsAsync.when(
                data: (participants) {
                  if (participants.isEmpty) return const SizedBox.shrink();
                  // Show names of others (exclude current user), max 3
                  final others = participants
                      .where((u) => u.uid != currentUser.uid)
                      .toList();
                  if (others.isEmpty) return const SizedBox.shrink();

                  final preview = others
                      .take(3)
                      .map((u) => u.name.split(' ').first)
                      .join(', ');
                  final extra = others.length > 3
                      ? ' +${others.length - 3} more'
                      : '';

                  return GestureDetector(
                    onTap: () =>
                        _showParticipantsDialog(context, title, participants),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 12,
                            color: _C.blue,
                          ),
                          const SizedBox(width: 4),
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
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_,_) => const SizedBox.shrink(),
              ),

              // ── Last message ───────────────────────────────────────────
              Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? _C.textPri : _C.textSec,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chat.isLocked)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: _C.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _C.textSec),
                onSelected: (value) async {
                  final chatService = ref.read(chatServiceProvider);
                  if (value == 'archive') {
                    await chatService.archiveChat(chat.chatId, currentUser.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title archived')),
                      );
                    }
                  } else if (value == 'delete') {
                    await chatService.deleteChat(chat.chatId, currentUser.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$title deleted')));
                    }
                  } else if (value == 'members') {
                    final participants = ref.read(
                      chatParticipantsProvider(chat.chatId),
                    );
                    participants.whenData(
                      (users) => _showParticipantsDialog(context, title, users),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 18),
                        SizedBox(width: 8),
                        Text('View Members'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(value: 'archive', child: Text('Archive')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: _C.red)),
                  ),
                ],
              ),
            ],
          ),
          onTap: () async {
            if (unreadCount > 0) {
              await ref
                  .read(chatServiceProvider)
                  .markChatAsRead(chat.chatId, currentUser.uid);
            }

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatRoomScreen(chat: chat, currentUser: currentUser),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Shows a modal dialog listing all participants with avatar + role
  void _showParticipantsDialog(
    BuildContext context,
    String chatTitle,
    List<UserModel> participants,
  ) {
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
              // Header
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: _C.blue, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatTitle,
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

              // Participant list — scrollable if many members
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  separatorBuilder: (_,_) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final user = participants[i];
                    final isCurrentUser = user.uid == currentUser.uid;

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
                          if (isCurrentUser) ...[
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
                              child: Text(
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
        return null; // no chip for plain volunteers
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
}
