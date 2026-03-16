import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../state/chat_provider.dart';
import '../../services/task_service.dart';
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

class ChatListScreen extends ConsumerWidget {
  final UserModel currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUser.ngoId == null || currentUser.ngoId!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('You are not associated with an NGO yet.')),
      );
    }

    final chatsAsync = ref.watch(userChatsProvider(ChatParams(
      uid: currentUser.uid,
      ngoId: currentUser.ngoId!,
    )));

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
                  builder: (_) => ArchivedChatsScreen(currentUser: currentUser),
                ),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStartChatModal(context, ref),
        backgroundColor: _C.blue,
        child: const Icon(Icons.message_rounded, color: Colors.white),
      ),
      body: chatsAsync.when(
        data: (allChats) {
          // Filter out chats archived by this user
          final activeChats = allChats
              .where((c) => !c.archivedBy.contains(currentUser.uid))
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
              return _buildChatTile(context, ref, chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, WidgetRef ref, ChatModel chat) {
    final isGroup = chat.type == 'group';
    final title = chat.title ?? 'Chat';
    final unreadCount = chat.unreadCounts[currentUser.uid] ?? 0;

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
          // Archive
          await chatService.archiveChat(chat.chatId, currentUser.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title archived')),
            );
          }
        } else {
          // Delete/Hide
          await chatService.deleteChat(chat.chatId, currentUser.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title deleted')),
            );
          }
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: isGroup ? _C.blue.withValues(alpha: 0.1) : Colors.grey.shade200,
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
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unreadCount > 0 ? _C.textPri : _C.textSec,
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chat.isLocked)
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title deleted')),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: _C.red)),
                  ),
                ],
              ),
            ],
          ),
          onTap: () async {
            // Mark as read immediately when tapping
            if (unreadCount > 0) {
              await ref.read(chatServiceProvider).markChatAsRead(chat.chatId, currentUser.uid);
            }
            
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    chat: chat,
                    currentUser: currentUser,
                  ),
                ),
              );
            }
          },
        ),
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
        final taskService = TaskService(); // using to stream users
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
                  stream: taskService.streamNgoVolunteers(currentUser.ngoId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data?.where((u) => u.uid != currentUser.uid).toList() ?? [];
                    if (users.isEmpty) {
                      return const Center(child: Text('No other members found.'));
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _C.blue.withValues(alpha: 0.1),
                            child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: _C.blue)),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.role),
                          onTap: () async {
                            Navigator.pop(context);
                            final service = ref.read(chatServiceProvider);
                            final chatId = await service.createOrGetDirectChat(
                              currentUserUid: currentUser.uid,
                              targetUserUid: user.uid,
                              ngoId: currentUser.ngoId!,
                            );
                            
                            // Let's open the chat room. We need a transient ChatModel for navigation, or load it.
                            final tempChat = ChatModel(
                              chatId: chatId,
                              type: 'direct',
                              title: user.name,
                              ngoId: currentUser.ngoId!,
                              participants: [currentUser.uid, user.uid],
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
                                    currentUser: currentUser,
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
