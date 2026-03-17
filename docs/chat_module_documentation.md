# Chat Module Documentation

## Overview

The **chat folder** contains all UI screens and logic related to the messaging system in the application.

This module supports:

- Active chats
- Archived chats
- Direct chat
- Group chat
- Message sending
- Unread counter
- Archive / unarchive
- Delete chat
- Locked chats
- Participant list
- Role labels

Technologies used:

- Flutter
- Riverpod
- Firebase / Backend chat service
- Google Fonts
- Intl (time formatting)

---

## Folder Structure

```

chat/
│
├── chat_list_screen.dart
├── archived_chats_screen.dart
├── chat_room_screen.dart
│
models/
├── chat_model.dart
├── message_model.dart
├── user_model.dart
│
state/
├── chat_provider.dart
│
services/
├── chat_service.dart
├── task_service.dart

```

---

## 1. ChatListScreen

File:

```

chat_list_screen.dart

````

### Purpose

Displays all active chats for the current user.

Only chats that are NOT archived by the user are shown.

### Active chat filtering

```dart
final activeChats = allChats
    .where((c) => !c.archivedBy.contains(currentUser.uid))
    .toList();
````

### Features

* Swipe to archive
* Swipe to delete
* Popup menu actions
* Unread counter
* Locked chat indicator
* Start new chat
* Open archived chats
* View members
* Show participants preview

---

### Archive chat

```dart
await chatService.archiveChat(chat.chatId, currentUser.uid);
```

---

### Delete chat

```dart
await chatService.deleteChat(chat.chatId, currentUser.uid);
```

---

### Open archived chats

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ArchivedChatsScreen(currentUser: currentUser),
  ),
);
```

---

### Start new chat

Users are fetched using TaskService.

```dart
taskService.streamNgoVolunteers(currentUser.ngoId!)
```

Create or get chat

```dart
createOrGetDirectChat()
```

---

## 2. ArchivedChatsScreen

File:

```

archived_chats_screen.dart

```

### Purpose

Shows chats that the current user archived.

Only chats where:

```dart
chat.archivedBy.contains(currentUser.uid)
```

are shown.

---

### Filter archived chats

```dart
final archivedChats = allChats
    .where((c) => c.archivedBy.contains(currentUser.uid))
    .toList();
```

---

### Features

* View archived chats
* Swipe to unarchive
* Delete chat
* Open chat room

---

### Unarchive chat

```dart
await chatService.unarchiveChat(chat.chatId, currentUser.uid);
```

---

### Delete chat

```dart
await chatService.deleteChat(chat.chatId, currentUser.uid);
```

---

## 3. ChatRoomScreen

File:

```

chat_room_screen.dart

```

### Purpose

Displays messages inside a chat.

Supports:

* Direct chat
* Group chat
* Locked chat
* Roles
* Participants popup
* Message timestamps
* Message bubbles

---

### Message stream

```dart
chatMessagesProvider(chat.chatId)
```

---

### Send message

```dart
service.sendMessage(
  chatId: widget.chat.chatId,
  sender: widget.currentUser,
  text: text,
);
```

---

### Locked chat

If chat is locked:

```dart
if (widget.chat.isLocked)
```

UI shows:

```
This chat is locked (Task Completed)
```

---

### Participants (group chat only)

```dart
chatParticipantsProvider(chat.chatId)
```

Popup shows:

* Avatar
* Name
* Role
* You label

---

### Message bubble features

* Sender name
* Role badge
* Timestamp
* Own message color
* Other message color

---

## 4. ChatModel fields used

```
chatId
type
title
participants
ngoId
lastMessage
lastMessageTime
isArchived
isLocked
unreadCounts
archivedBy
deletedBy
```

---

## 5. MessageModel fields used

```
senderId
senderName
senderRole
text
createdAt
```

---

## 6. Providers used

```
userChatsProvider
chatMessagesProvider
chatParticipantsProvider
chatServiceProvider
```

---

## 7. Services used

```
ChatService
TaskService
```

Functions used:

```
sendMessage()
archiveChat()
unarchiveChat()
deleteChat()
markChatAsRead()
createOrGetDirectChat()
streamNgoVolunteers()
```

---

## 8. Features supported

* Active chats
* Archived chats
* Delete chat
* Unarchive chat
* Unread counter
* Locked chat
* Group chat members
* Roles (admin / volunteer / super_admin / developer_admin)
* Start new chat
* Swipe actions
* Popup menu
* Message timestamps
* Participant preview
* Member dialog

---

