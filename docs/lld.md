# 🏗️ Architecture Overview

* **Frontend:** Flutter (Dart) using **Riverpod** for state management.  
* **Backend:** Firebase (Firestore for Database, Firebase Auth for Login, Cloud Functions for logic/triggers, Firebase Cloud Messaging (FCM) for Notifications).  
* **Role Management:** Handled via Firestore `users` collection and role field (for dashboard routing).  
* **NGO Scoping:** All data is scoped to a specific NGO via `orgId`. One user belongs to one NGO at a time.

---

# 🗄️ 1\. Firebase Firestore Database Schema

### Collection: `users`

Stores all profiles. Super Admin is promoted via developer script.

{

  "uid": "user\_id\_string",

  "name": "John Doe",

  "email": "john@ngo.com",

  "role": "volunteer", // "super\_admin", "admin", "volunteer"

  "status": "active", // "active", "inactive" (Visibility toggle)

  "fcmToken": "token\_for\_push\_notifications",

  "orgId": "ngo\_doc\_id", // nullable for super\_admin

  "createdAt": "timestamp"

}

### Collection: `ngos`

Stores NGO/Organisation data. Created by Super Admin from within the app.

{

  "name": "Green Earth NGO",

  "description": "We clean beaches and plant trees.",

  "address": "Mumbai, India",

  "contactEmail": "admin@greenearth.org",

  "joinCode": "47392810", // 8-digit numeric, DB-unique

  "superAdminId": "sa\_uid",

  "createdAt": "timestamp"

}

### Collection: `ngo_applications`

Submitted by users who want Super Admin access for their NGO.

{

  "applicantName": "Ramesh Kumar",

  "applicantEmail": "ramesh@gmail.com",

  "ngoName": "Green Earth NGO",

  "ngoDescription": "We clean beaches...",

  "ngoAddress": "Mumbai, India",

  "ngoPhone": "9876543210",

  "status": "pending", // "pending", "approved", "rejected"

  "submittedAt": "timestamp"

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

├── models/              \# Data models

│   ├── user\_model.dart

│   ├── ngo\_model.dart

│   ├── ngo\_application\_model.dart

│   ├── task\_model.dart

│   └── chat\_model.dart

│

├── services/

│   ├── auth\_service.dart      \# Firebase Auth login/logout/Google Sign-In

│   ├── ngo\_service.dart       \# NGO CRUD, join code gen, application submit

│   ├── db\_service.dart        \# Firestore queries (Transactions, updates)

│   └── fcm\_service.dart       \# Push Notifications handling

│

├── state/               \# Riverpod Providers

│   ├── auth\_provider.dart     \# Manages current user state & role

│   ├── task\_provider.dart     \# Manages task fetching & filtering

│   └── chat\_provider.dart     \# Manages chat streams

│

├── screens/

│   ├── splash\_screen.dart

│   ├── landing\_page.dart

│   ├── role\_router.dart       \# Routes to correct dashboard by role

│   ├── auth/

│   │   ├── login\_screen.dart

│   │   ├── signup\_screen.dart

│   │   ├── google\_signup\_form\_screen.dart

│   │   └── ngo\_application\_screen.dart

│   ├── super\_admin/       \# SA Dashboard, Create NGO, Manage Admins

│   ├── admin/             \# Admin Dashboard, Create Task, Review Progress

│   ├── volunteer/         \# Volunteer Dashboard, Task Invites, Submit Progress

│   └── chat/              \# Chat List, Chat Room

│

└── main.dart

scripts/

├── promote\_super\_admin.js  \# Node.js script to promote a user to super\_admin

└── package.json

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

1. ~~**Setup Firebase:** Create the project, enable Auth (Email/Password + Google), Firestore, and Storage.~~ ✅  
2. ~~**Build Auth Flow:** Login, Signup, Google Sign-In, NGO Application, Role Router.~~ ✅  
3. ~~**Create promote script:** Node.js script to promote a user to Super Admin.~~ ✅  
4. **Build Super Admin Dashboard:** Create NGO, view join codes, manage admins.  
5. **Develop Admin/Volunteer Task UI:** Build the FCFS assignment flow.  
6. **Implement Progress Math:** Add the approval workflow and dynamic progress recalculations.  
7. **Integrate Chat & Notifications:** Add the auto-group creation and FCM notifications.

---

# 🔐 Auth & Onboarding Flow

```
SplashScreen
  └─► LandingPage ("Get Started")
        └─► LoginScreen
              ├─► SignupScreen (name + email + password + 8-digit NGO code)
              │     └─► "Have an NGO? Become a Super Admin" ──► NgoApplicationScreen → Success
              │     └─► on signup success ──► RoleRouter
              │
              ├─► Google Sign-In
              │     ├─► (returning user) ──► RoleRouter
              │     └─► (new user) ──► GoogleSignupFormScreen (name + NGO code) ──► RoleRouter
              │
              └─► "Have an NGO? Become a Super Admin" ──► NgoApplicationScreen

RoleRouter ──► super_admin ──► SuperAdminDashboard
           ──► admin       ──► AdminDashboard
           ──► volunteer   ──► VolunteerDashboard
```

### Super Admin Promotion Flow

1. Person fills NgoApplicationScreen → saved to Firestore `ngo_applications` + auto-email sent via EmailJS.
2. Developer verifies the NGO is legit.
3. Developer runs: `cd scripts && node promote_super_admin.js --email user@example.com`
4. Script sets their Firestore `role` to `"super_admin"`.
5. Developer emails them their login info.
6. They log in → RoleRouter → SuperAdminDashboard → they can create NGOs and get join codes.
