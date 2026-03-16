import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../state/chat_provider.dart';
import 'chat_room_screen.dart';

class _C {
  static const bg = Color(0xFFEEF2F8);
  static const blue = Color(0xFF4A6CF7);
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
}

class ArchivedChatsScreen extends ConsumerWidget {
  final UserModel currentUser;

  const ArchivedChatsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUser.ngoId == null || currentUser.ngoId!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No active NGO association.')),
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
          'Archived Chats',
          style: GoogleFonts.plusJakartaSans(
            color: _C.textPri,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: _C.textPri),
      ),
      body: chatsAsync.when(
        data: (allChats) {
          // Filter ONLY chats archived by this user
          final archivedChats = allChats
              .where((c) => c.archivedBy.contains(currentUser.uid))
              .toList();

          if (archivedChats.isEmpty) {
            return const Center(
              child: Text(
                'No archived conversations.',
                style: TextStyle(color: _C.textSec),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: archivedChats.length,
            itemBuilder: (context, index) {
              final chat = archivedChats[index];
              return _buildArchivedChatTile(context, ref, chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildArchivedChatTile(BuildContext context, WidgetRef ref, ChatModel chat) {
    final isGroup = chat.type == 'group';
    final title = chat.title ?? 'Chat';

    return Dismissible(
      key: Key(chat.chatId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: _C.blue.withValues(alpha: 0.8),
        child: const Icon(Icons.unarchive, color: Colors.white),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) async {
        final chatService = ref.read(chatServiceProvider);
        await chatService.unarchiveChat(chat.chatId, currentUser.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title unarchived')),
          );
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
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _C.textPri,
            ),
          ),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _C.textSec),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _C.textSec),
            onSelected: (value) async {
              final chatService = ref.read(chatServiceProvider);
              if (value == 'unarchive') {
                await chatService.unarchiveChat(chat.chatId, currentUser.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title unarchived')),
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
                value: 'unarchive',
                child: Text('Unarchive'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          onTap: () async {
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
}
