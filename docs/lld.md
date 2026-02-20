# 🏗️ Architecture Overview

* **Frontend:** Flutter (Dart) using **Riverpod** or **BLoC** for state management.  
* **Backend:** Firebase (Firestore for Database, Firebase Auth for Login, Cloud Functions for logic/triggers, Firebase Cloud Messaging (FCM) for Notifications).  
* **Role Management:** Handled via Firestore `users` collection and Custom Claims (for secure backend access).

---

# 🗄️ 1\. Firebase Firestore Database Schema

### Collection: `users`

Stores all profiles. Super Admin is pre-seeded manually.

{

  "uid": "user\_id\_string",

  "name": "John Doe",

  "email": "john@ngo.com",

  "role": "volunteer", // "super\_admin", "admin", "volunteer"

  "status": "active", // "active", "inactive" (Visibility toggle)

  "fcmToken": "token\_for\_push\_notifications",

  "createdAt": "timestamp"

}

### Collection: `tasks` (Admin \-\> Volunteer Tasks)

The core collection for volunteer tasks.

{

  "taskId": "task\_123",

  "title": "Clean the Beach",

  "description": "Collect plastic waste.",

  "adminId": "admin\_uid",

  "maxVolunteers": 5,

  "assignedVolunteers":, // Reached via FCFS

  "pendingInvites":, // Users who can currently see the invite

  "declinedBy":, 

  "status": "inviting", // "inviting" (open for 24h), "active" (locked in), "completed"

  "mainProgress": 0.0, // 0 to 100

  "createdAt": "timestamp",

  "deadline": "timestamp",

  "adminFinalNote": "" // Filled when task is 100% completed

}

### Collection: `task_assignments`

Tracks individual volunteer progress for a specific task.

{

  "assignmentId": "assign\_123",

  "taskId": "task\_123",

  "volunteerId": "vol\_1",

  "individualProgress": 0.0 // 0 to 100 (Only updates after Admin approval)

}

### Collection: `progress_requests`

When a volunteer submits an update for review.

{

  "requestId": "req\_123",

  "taskId": "task\_123",

  "volunteerId": "vol\_1",

  "requestedProgress": 40.0, // e.g., wants to jump from 25% to 40%

  "mandatoryNote": "Cleared the east side of the beach.",

  "status": "pending" // "pending", "approved", "rejected"

}

### Collection: `sa_tasks` (Super Admin \-\> Admin Tasks)

Simple To-Do checklist.

{

  "saTaskId": "sa\_task\_1",

  "title": "Organize Beach Drive",

  "description": "Create a task and assign 5 volunteers",

  "superAdminId": "sa\_uid",

  "assignedAdminId": "admin\_uid",

  "isCompleted": false,

  "createdAt": "timestamp"

}

### Collection: `chats` & Subcollection `messages`

// chats document

{

  "chatId": "chat\_123",

  "type": "group", // "group" or "direct"

  "taskId": "task\_123", // Null if direct message

  "participants":,

  "isArchived": false, // Turns true when task is 100%

  "lastMessage": "Great job guys\!",

  "lastMessageTime": "timestamp"

}

// messages subcollection under chats

{

  "messageId": "msg\_123",

  "senderId": "vol\_1",

  "text": "I am on my way.",

  "timestamp": "timestamp"

}

---

# ⚙️ 2\. Core Logical Flows & Algorithms

### A. Task Assignment & FCFS Logic (Transaction)

Because multiple volunteers might click "Accept" at the exact same millisecond, we MUST use a **Firestore Transaction** to prevent overbooking.

1. Admin creates task \-\> Adds target volunteers to `pendingInvites`.  
2. Volunteer sees Notification \-\> Clicks "Accept".  
3. **Transaction triggers:**  
   * Reads the `tasks` doc.  
   * Checks if `assignedVolunteers.length < maxVolunteers` AND `status == "inviting"`.  
   * If True: Adds volunteer to `assignedVolunteers`, removes from `pendingInvites`. Creates a `task_assignments` doc for them at 0%.  
   * If `assignedVolunteers.length` now equals `maxVolunteers`: Sets `status` to `"active"`, clears `pendingInvites`, and auto-creates the `chats` document.  
   * If False (Task Full): Returns an error to the user ("Task is already full").

### B. The 24-Hour Timer (Cloud Function)

* Write a **Firebase Cloud Function** (Scheduled or Task Queue) that triggers 24 hours after `createdAt`.  
* If `status` is still `"inviting"`, it checks how many accepted.  
* If \> 0, Admin gets a notification: "24h passed. 3/5 accepted. Do you want to close the task or extend?"  
* If Admin clicks "Close Task" \-\> Status changes to `"active"`, chat group is created, task math is locked to the 3 people.

### C. Task Progress Approval & Math (Cloud Function / Firestore Triggers)

When an Admin **Approves** a `progress_requests` document:

1. Update `task_assignments` \-\> `individualProgress` \= `requestedProgress`.  
2. **Recalculate Main Progress:**  
   * Fetch all `task_assignments` for `taskId`.  
   * `mainProgress` \= `(Sum of all individualProgress) / Number of assignedVolunteers`.  
   * Update `mainProgress` in the `tasks` doc.  
3. If `mainProgress == 100`:  
   * Set task `status` to `"completed"`.  
   * Find the associated `chats` document and set `isArchived = true` (Frontend will disable the text input field based on this flag).  
   * Prompt Admin to add `adminFinalNote`.

### D. Volunteer Removal & Dynamic Math Adjustment

If Admin removes Volunteer B:

1. Delete Volunteer B's `task_assignments` doc.  
2. Remove Volunteer B from `assignedVolunteers` array in the `tasks` doc.  
3. Remove Volunteer B from the `chats` participants.  
4. **Instantly Recalculate:** Fetch the *remaining* `task_assignments`. Sum their individual progress and divide by the *new* total of volunteers. (As discussed, if A is at 100% and was 1 of 3, removing B and C makes A's work worth 100% of the main bar).

### E. Timeline Color Code Logic (Frontend Flutter UI)

Run this logic locally in Flutter using the `createdAt` and `deadline` timestamps.

Color getTaskColor(DateTime createdAt, DateTime deadline) {

  final now \= DateTime.now();

  final totalDuration \= deadline.difference(createdAt).inMinutes;

  final timeRemaining \= deadline.difference(now).inMinutes;

  

  if (timeRemaining \<= 0\) return Colors.red; // Overdue

  

  double percentageRemaining \= (timeRemaining / totalDuration) \* 100;

  

  if (percentageRemaining \> 50\) {

    return Colors.green;

  } else if (percentageRemaining \> 30 && percentageRemaining \<= 50\) {

    return Colors.orange; // or Yellow

  } else {

    return Colors.red; // Danger zone

  }

}

---

# 📱 3\. Flutter App Architecture (Folder Structure)

lib/

│

├── core/

│   ├── constants/       \# Colors, TextStyles, Strings

│   ├── utils/           \# Date formatters, Timeline Color logic math

│   └── theme.dart       \# App Theme

│

├── models/              \# Data models (User, Task, Chat, ProgressRequest)

│   ├── user\_model.dart

│   ├── task\_model.dart

│   └── chat\_model.dart

│

├── services/

│   ├── auth\_service.dart      \# Firebase Auth login/logout

│   ├── db\_service.dart        \# Firestore queries (Transactions, updates)

│   └── fcm\_service.dart       \# Push Notifications handling

│

├── state/               \# Providers/Blocs

│   ├── auth\_provider.dart     \# Manages current user state & role

│   ├── task\_provider.dart     \# Manages task fetching & filtering

│   └── chat\_provider.dart     \# Manages chat streams

│

├── ui/

│   ├── screens/

│   │   ├── auth/              \# Login, Register

│   │   ├── super\_admin/       \# SA Dashboard, Manage Admins, SA Tasks

│   │   ├── admin/             \# Admin Dashboard, Create Task, Review Progress

│   │   ├── volunteer/         \# Volunteer Dashboard, Task Invites, Submit Progress

│   │   └── chat/              \# Chat List, Chat Room (Input disabled if isArchived)

│   │

│   └── widgets/               \# Reusable widgets (TaskCard, ProgressBar, StatusToggle)

│

└── main.dart

---

# 🔒 4\. Firebase Security Rules (High Level)

To ensure users can't hack the system:

* **Super Admin:** Can read/write everything.  
* **Admin:** Can read all volunteers, write to `tasks` they created, write to `chats` they are in, approve `progress_requests`.  
* **Volunteer:**  
  * Can only read `tasks` where their ID is in `assignedVolunteers` or `pendingInvites`.  
  * Can only write to `progress_requests` where their ID matches.  
  * Can read `chats` where their ID is in `participants`.  
  * Can read `sa_tasks`? **No.** (Denied).

---

# 🚀 Next Steps for Development

1. **Setup Firebase:** Create the project, enable Auth (Email/Password), Firestore, and Storage.  
2. **Seed the Super Admin:** Manually add your first user into Firestore and give them `"role": "super_admin"`.  
3. **Build Auth Flow:** Create the Flutter login screens and route the user to the correct Dashboard based on their `role` fetched from Firestore.  
4. **Develop Admin/Volunteer Task UI:** Build the FCFS assignment flow first without the math.  
5. **Implement Progress Math:** Add the approval workflow and dynamic progress recalculations.  
6. **Integrate Chat & Notifications:** Add the auto-group creation and FCM notifications.
