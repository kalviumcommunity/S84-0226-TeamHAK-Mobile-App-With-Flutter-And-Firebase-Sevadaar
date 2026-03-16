# CHAT_PARTICIPANTS_FEATURE.md

## Chat Participant Names — Feature Changelog

### Overview
Added participant name visibility across the entire chat module — both in the chat list and inside group chat rooms. Users can now see who is in a conversation at a glance, and tap to view a full members popup with roles.

---

### Files Changed

| File | Type of Change |
|------|---------------|
| `lib/screens/chat/chat_list_screen.dart` | Modified |
| `lib/screens/chat/chat_room_screen.dart` | Modified |
| `lib/state/chat_provider.dart` | Modified |
| `lib/services/chat_service.dart` | Modified |

---

### 1. `lib/services/chat_service.dart`
**Added method: `fetchChatParticipants(String chatId)`**

- Reads the chat document from Firestore to get the `participants` UID array
- Batch-fetches all matching user documents from the `users` collection in parallel using `Future.wait`
- Returns a `List<UserModel>`, skipping any UIDs whose user doc no longer exists

---

### 2. `lib/state/chat_provider.dart`
**Added provider: `chatParticipantsProvider`**

- `FutureProvider.family<List<UserModel>, String>` keyed by `chatId`
- Calls `fetchChatParticipants()` on the `ChatService`
- Used by both `chat_list_screen.dart` and `chat_room_screen.dart`

---

### 3. `lib/screens/chat/chat_list_screen.dart`
**Refactored `_buildChatTile` → extracted as `_ChatTile` (`ConsumerWidget`)**

Extracting to its own `ConsumerWidget` was necessary so each tile can independently call `ref.watch(chatParticipantsProvider(...))` without causing the entire list to rebuild.

**New UI — participant names preview (group chats):**
- Shown as a small blue subtitle row below the chat title
- Format: `👥 Rahul, Priya, Amit +2 more` (first names only, max 3 shown)
- Tapping the names row opens the Members Popup

**New UI — Members Popup:**
- Triggered by tapping the names preview OR via the `⋮` menu → "View Members"
- Shows all participants with:
  - Circle avatar with first-letter initial
  - Full name with a **"You"** badge for the current user
  - Role subtitle (formatted, e.g. `super_admin` → `Super Admin`)
  - Colored role chip for `admin`, `super_admin`, `developer_admin`
  - Plain volunteers show no chip

**`⋮` PopupMenu — new item added:**
- `View Members` option added above Archive and Delete

---

### 4. `lib/screens/chat/chat_room_screen.dart`
**AppBar updated (group chats only):**

- Title font size reduced slightly (`16px`) to accommodate the subtitle
- Participant names shown as a tappable subtitle below the title
  - Format: `👥 Rahul, Priya +1 more ↓`
  - Shows a `keyboard_arrow_down` caret to signal it's tappable
  - Tapping the entire title area opens the Members Popup
- A `people_outline` icon button added to AppBar `actions`
  - Shows a small `CircularProgressIndicator` while participants load
  - Tapping opens the same Members Popup

**Members Popup (same design as chat list):**
- All logic self-contained within `_ChatRoomScreenState`
- Methods `_showParticipantsDialog`, `_formatRole`, `_roleChip` added

**Direct chats unaffected:**
- All new UI is guarded by `isGroup` checks — 1-on-1 chats look and behave exactly as before

---

### Firestore reads
Each chat tile and the chat room screen makes **one extra Firestore read** per chat to fetch participant user docs (batched). This is a `FutureProvider` (not a stream), so it fetches once per session and is cached by Riverpod until the provider is disposed.

---

### No breaking changes
- `ChatModel`, `UserModel`, `MessageModel` — unchanged
- All existing archive, delete, lock, unread-count logic — unchanged
- `archived_chats_screen.dart` — unchanged