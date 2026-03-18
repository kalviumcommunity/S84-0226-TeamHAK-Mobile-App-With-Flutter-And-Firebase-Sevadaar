# NGO Forge — Developer Changelog & Implementation Guide

> **Project:** Flutter + Firebase NGO Management App  
> **Scope:** Super Admin dashboard, NGO lifecycle management, member role control, in-app chat  
> **Stack:** Flutter · Riverpod · Cloud Firestore · Google Fonts (DM Sans, Poppins, Space Mono)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [File Structure](#file-structure)
3. [Feature: Manage Admins Screen](#feature-manage-admins-screen)
4. [Feature: Super Admin Dashboard](#feature-super-admin-dashboard)
5. [Feature: Delete NGO](#feature-delete-ngo)
6. [Bug Fix: Snackbar Hidden Behind Bottom Sheet](#bug-fix-snackbar-hidden-behind-bottom-sheet)
7. [NgoService Reference](#ngoservice-reference)
8. [Design Tokens](#design-tokens)
9. [Known Gotchas](#known-gotchas)

---

## Architecture Overview

```
SuperAdminDashboard
├── _HeroCard               — dark gradient card showing NGO count + status
├── _ActionCard (×3)        — Your NGOs · Create NGO · Chats
│   └── _showMyNgosSheet()  — DraggableScrollableSheet listing all NGOs
│       └── _NgoCard        — per-NGO card with Manage / Copy / Delete actions
│           ├── ManageAdminsScreen  (push)
│           ├── Copy join code      (clipboard + snackbar)
│           └── _confirmAndDeleteNgo()
└── _showCreateNgoDialog()  — bottom sheet form → createNgo() → join code reveal
```

**State management:** Riverpod (`ConsumerWidget` / `ConsumerStatefulWidget`) for chat service access. All Firestore data is consumed via `StreamBuilder` — no local state caching needed.

---

## File Structure

| File | Purpose |
|---|---|
| `lib/screens/super_admin/super_admin_dashboard.dart` | Main dashboard UI + all sheet logic |
| `lib/screens/super_admin/manage_admins_screen.dart` | Member list with promote/demote/chat |
| `lib/services/ngo_service.dart` | All NGO Firestore operations |
| `lib/services/user_service.dart` | User read/write (role, ngoId) |
| `lib/services/auth_service.dart` | Firebase Auth wrapper |
| `lib/models/ngo_model.dart` | NGO data model |
| `lib/state/chat_provider.dart` | Riverpod providers for chat |

---

## Feature: Manage Admins Screen

**File:** `manage_admins_screen.dart`

Allows the Super Admin to view all members of their NGO and toggle roles between `volunteer` and `admin`.

### Role Hierarchy

```
developer_admin  ← cannot be modified (locked chip)
super_admin      ← cannot be modified (locked chip, "you" badge if current user)
admin            ← can be demoted → volunteer
volunteer        ← can be promoted → admin
```

### Member Sort Order

Members are sorted before rendering:

```dart
const order = {'super_admin': 0, 'admin': 1, 'volunteer': 2};
sorted.sort((a, b) => (order[a.role] ?? 3).compareTo(order[b.role] ?? 3));
```

### Role Toggle Flow

1. Tap **Promote** or **Demote** button on `_MemberCard`
2. Confirmation `AlertDialog` shown with action description
3. On confirm → calls `userService.promoteToAdmin()` or `userService.demoteToVolunteer()`
4. Success/error snackbar shown

### Direct Chat

Each member card has a `PopupMenuButton` with a **Chat** option. Tapping it:

1. Calls `chatService.createOrGetDirectChat()` to get or create a DM thread
2. Constructs a `ChatModel` and fetches the super admin's own `UserModel`
3. Pushes `ChatRoomScreen`

### Key Widgets

| Widget | Role |
|---|---|
| `_MemberCard` | `ConsumerStatefulWidget` — handles toggle + chat navigation |
| `_RoleChip` | Read-only locked badge (lock icon + label) |
| `_ToggleButton` | Promote (green ↑) or Demote (orange ↓) action button |

---

## Feature: Super Admin Dashboard

**File:** `super_admin_dashboard.dart`

### Entrance Animation

Five staggered `CurvedAnimation` instances driven by a single `AnimationController` (900 ms). Each element fades + slides in with a 120 ms offset:

```dart
_staggered = List.generate(5, (i) {
  final start = i * 0.12;
  return CurvedAnimation(
    parent: _entranceCtrl,
    curve: Interval(start.clamp(0, 0.8), (start + 0.5).clamp(0, 1),
        curve: Curves.easeOutCubic),
  );
});
```

### Hero Card

Dark gradient card (`#0A0F1E → #141B2D → #1a2340`) with:
- Shield icon + date badge
- "Welcome back / Super Admin" heading
- Live NGO count via `StreamBuilder` on `getNgosForSuperAdmin()`

### Quick Actions

Three `_ActionCard` tiles (press-scale animation via `AnimatedScale`):

| Action | Handler |
|---|---|
| Your NGOs | `_showMyNgosSheet()` |
| Create NGO | `_showCreateNgoDialog()` |
| Chats | Fetches user → pushes `ChatListScreen` |

### Create NGO Flow

1. `_showCreateNgoDialog()` — modal bottom sheet with validated form (name, description, address, email)
2. On submit → `NgoService.createNgo()` → `UserService.assignNgo()`
3. Sheet closes → `_showJoinCodeSheet()` shows the generated 8-digit code on a gradient card (tap to copy)

### Your NGOs Sheet

`DraggableScrollableSheet` (75 % initial, 95 % max) with a fixed header and scrollable `ListView` of `_NgoCard` widgets streamed live from Firestore.

---

## Feature: Delete NGO

**Files:** `super_admin_dashboard.dart` · `ngo_service.dart`

### UI — Delete Button in `_NgoCard`

A compact icon-only red button sits alongside **Manage Members** and **Copy Code** in the card's action row. It uses the `iconOnly: true` flag on `_SheetBtn`:

```dart
_SheetBtn(
  label: '',
  icon: Icons.delete_forever_rounded,
  color: _AppColors.red,
  bg: _AppColors.redLight,
  onTap: onDelete,
  iconOnly: true,
)
```

### Confirmation Dialog — `_confirmAndDeleteNgo()`

A two-step safety gate modeled on GitHub's repository deletion pattern:

1. **Warning banner** listing everything that will be erased:
   - All tasks and assignments
   - All chats and messages
   - All announcements
   - All member associations

2. **Name confirmation field** — the Delete button stays disabled until the user types the exact NGO name. Uses `StatefulBuilder` to reactively enable/disable:

```dart
onChanged: (val) {
  setS2(() => nameMatches = val.trim() == ngoName.trim());
},
// ...
onPressed: nameMatches ? () => Navigator.pop(ctx, true) : null,
```

3. On confirm → loading snackbar on root context → `NgoService.deleteNgo()` → success/error snackbar

### Service — `NgoService.deleteNgo()`

Deletion is performed in strict order to avoid orphaned data:

```
1. Reset all users where ngoId == ngoId
     → set ngoId: '', role: 'volunteer'
     → chunked in batches of 400 (Firestore limit is 500)

2. Delete tasks subcollection

3. Delete chats subcollection
     → for each chat doc: delete messages subcollection first, then the chat doc

4. Delete announcements subcollection

5. Delete the NGO document itself
```

**Why this order matters:** Members are reset first so they are never left pointing at a non-existent NGO, even if the operation fails partway through. The NGO doc is deleted last so it can act as a "lock" — if anything before it fails, the NGO still exists and can be retried.

### Helper — `_deleteSubcollection()`

Loops in batches of 400 until a collection is empty. Required because Firestore does not cascade-delete subcollections:

```dart
Future<void> _deleteSubcollection(CollectionReference col) async {
  const batchSize = 400;
  QuerySnapshot snap;
  do {
    snap = await col.limit(batchSize).get();
    if (snap.docs.isEmpty) break;
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  } while (snap.docs.length == batchSize);
}
```

> **Note:** Uses `_db` (the lazy getter) instead of `FirebaseFirestore.instance` directly, so it respects the service's error handling and platform checks.

---

## Bug Fix: Snackbar Hidden Behind Bottom Sheet

**File:** `super_admin_dashboard.dart` · `onCopy` callback in `_showMyNgosSheet()`

### Problem

When tapping **Copy Code** inside the Your NGOs sheet, the "copied" snackbar appeared behind the modal overlay and was invisible to the user.

**Root cause:** Flutter's modal bottom sheet is pushed onto the `Navigator` overlay stack. Any `ScaffoldMessenger` resolved from within the sheet's `BuildContext` (including one resolved from the parent `State`'s context) renders its snackbar at the `Scaffold` level — which is visually below the modal overlay layer.

### Failed Approaches

| Attempt | Why it failed |
|---|---|
| `ScaffoldMessenger.of(ctx)` (sheet context) | Finds the messenger below the sheet |
| `ScaffoldMessenger.of(context)` (State context) | Still below the modal overlay layer |

### Solution

Dismiss the sheet first, then show the snackbar using `Future.microtask` to wait one frame for the sheet to finish closing:

```dart
onCopy: () {
  // 1. Copy immediately — user doesn't lose data
  Clipboard.setData(ClipboardData(text: ngos[i].joinCode));

  // 2. Close the sheet
  Navigator.pop(ctx);

  // 3. Wait one frame, then show snackbar on the now-visible dashboard
  Future.microtask(() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(/* ... */),
  ));
},
```

**Why `Future.microtask`:** `Navigator.pop` schedules the route removal — the overlay hasn't updated yet in the same frame. A microtask defers the snackbar call to after the current frame completes, ensuring the sheet is gone before the snackbar renders.

---

## NgoService Reference

| Method | Signature | Description |
|---|---|---|
| `generateUniqueCode` | `Future<String>` | Generates a collision-free 8-digit numeric join code |
| `validateJoinCode` | `Future<NgoModel?>` | Looks up an NGO by join code |
| `createNgo` | `Future<NgoModel>` | Creates NGO doc with auto-generated join code |
| `createNgoFromRequest` | `Future<NgoModel>` | Simplified creation from developer admin approval |
| `getNgoById` | `Future<NgoModel?>` | Fetches a single NGO by document ID |
| `getNgosForSuperAdmin` | `Stream<List<NgoModel>>` | Live stream of all NGOs for a given super admin |
| `submitApplication` | `Future<void>` | Saves NGO application + fires EmailJS notification |
| `deleteNgo` | `Future<void>` | **Permanently deletes NGO + all related data** |
| `_deleteSubcollection` | `Future<void>` (private) | Batch-deletes all docs in a collection (loops until empty) |

---

## Design Tokens

All colors are defined in `_AppColors` in `super_admin_dashboard.dart`:

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#F1F5F9` | Page background |
| `surface` | `#FFFFFF` | Cards, sheets |
| `dark` | `#0A0F1E` | Hero gradient start, primary button |
| `darkCard` | `#141B2D` | Icon containers in dark contexts |
| `indigo` | `#4F46E5` | Primary accent |
| `indigoLight` | `#EEF2FF` | Indigo button backgrounds |
| `green` | `#10B981` | Success, active status |
| `greenLight` | `#ECFDF5` | Green button backgrounds |
| `red` | `#EF4444` | Destructive actions, errors |
| `redLight` | `#FEF2F2` | Red button backgrounds |
| `textPrimary` | `#0A0F1E` | Headings |
| `textSecondary` | `#64748B` | Body text |
| `textTertiary` | `#94A3B8` | Hints, labels, metadata |
| `border` | `#E2E8F0` | Card borders, dividers |

**Typography:**

| Font | Usage |
|---|---|
| `DM Sans` | All UI text (dashboard) |
| `Poppins` | All UI text (manage admins screen) |
| `Space Mono` | Join code display |

---

## Known Gotchas

**Firestore batch limit is 500** — `_deleteSubcollection` uses 400 as the chunk size to stay safely under the limit. The member reset loop in `deleteNgo` also chunks in groups of 400 for the same reason.

**Modal sheets don't share the root `ScaffoldMessenger`** — always dismiss a sheet before showing a snackbar if you need it visible. Never rely on context resolution from within a sheet's builder to surface UI above the modal layer.

**`_deleteSubcollection` does not recurse** — if your data model ever adds a subcollection inside `tasks` or `announcements`, you'll need to handle those nested collections manually before calling the helper on the parent.

**`Developer Admin` role is display-only** — `_isDeveloperAdmin` is checked in `_MemberCard` to show a locked chip, but `developer_admin` users are managed outside the Super Admin flow entirely. Do not add toggle logic for this role.

**Stream vs Future for NGO list** — `getNgosForSuperAdmin` returns a `Stream` so the hero card count and the NGO sheet both update live when an NGO is created or deleted without requiring a manual refresh.