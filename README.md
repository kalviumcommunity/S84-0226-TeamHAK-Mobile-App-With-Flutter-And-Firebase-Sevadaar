# 🌍 Sevadaar – Volunteer Coordination System

A modern, structured **Flutter + Firebase** mobile application designed to streamline NGO volunteer task management through real-time workflow tracking and admin approval.

> 🤝 Empowering service through technology
> 📊 Bringing structure to volunteer coordination
> ⚡ Delivering real-time impact

---

## Demo Video (https://drive.google.com/file/d/1kmzesAmqtLM-ar331XvIPMHrDFCRl-F4/view?usp=sharing)

# 🚀 Features

## 🧩 Core Functionality

✅ 👤 Role-Based Authentication (Admin & Volunteer)
✅ 📝 Task Creation & Assignment
✅ 🔄 Structured Workflow Management
✅ 🛡 Admin Approval Before Final Completion
✅ 🔥 Real-Time Firestore Synchronization
✅ 🔐 Secure Role-Based Access Control

---

## 📊 Workflow Model

Sevadaar follows a structured lifecycle:

```
🆕 Created → 📌 Assigned → 🚧 In Progress → ✅ Completed → 🛡 Approved
```

This ensures:

* 📈 Transparency
* 🎯 Accountability
* 🤝 Clear ownership
* 📋 Organized task tracking

---

# 👥 User Experience

🔐 Persistent Login Sessions (Firebase-managed)
📱 Cross-Platform Support (Android & iOS)
⚡ Fast Navigation via Auth State Listener
🎨 Clean NGO-Focused UI
📊 Real-Time Dashboard Analytics

---

# 🛠 Technology Stack

🖥 Framework: Flutter (Dart)
🔐 Authentication: Firebase Authentication
📂 Database: Cloud Firestore
🔄 State Management: StreamBuilder with Firebase Streams
🎨 UI System: Material Design 3
🏗 Architecture: Reactive Role-Based Rendering

---

# 📱 Application Screens

🚀 Splash Screen – Branding & Initialization
🔑 Login Screen – Secure Authentication
📝 Register Screen – Role-Based Account Creation
📊 Admin Dashboard – Task Statistics & Overview
📋 Volunteer Dashboard – Assigned Tasks
📄 Task Detail Screen – Status Updates & Approval
👤 Profile Screen – User Account Management

---

# 🔥 Firebase Integration

## 🔐 Authentication & Auto-Login

Sevadaar uses Firebase Authentication for secure session management.

```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return RoleBasedDashboard();
    }
    return LoginScreen();
  },
);
```

### 🎯 Benefits

* 🔁 Automatic session persistence
* 🔒 Secure token handling
* ⚡ Real-time authentication updates
* 📱 Cross-platform session consistency

---

# 📂 Firestore Data Structure

## 👤 Users Collection

Stores authenticated user data.

Fields:

* displayName
* email
* role (admin / volunteer)
* createdAt
* updatedAt

---

## 📋 Tasks Collection

Core workflow entity.

Fields:

* title
* description
* assignedTo (DocumentReference)
* createdBy (DocumentReference)
* status
* deadline
* approvedBy
* approvedAt
* createdAt
* updatedAt

---

## 📜 AuditLogs (Optional)

Tracks task status changes and approval history.

---

# 🔄 Role Permissions

### 👤 Volunteer Can:

* 📌 Update status to In Progress
* ✅ Mark task as Completed

### 👩‍💼 Admin Can:

* 📝 Create tasks
* 📌 Assign volunteers
* 🛡 Approve completed tasks
* 👀 View all tasks

---

# 📦 Project Structure

```
lib/
├── screens/
│   ├── splash_screen.dart
│   ├── auth_wrapper.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── admin_dashboard.dart
│   ├── volunteer_dashboard.dart
│   ├── task_list_screen.dart
│   ├── task_detail_screen.dart
│   └── profile_screen.dart
├── widgets/
│   ├── task_card.dart
│   ├── status_badge.dart
│   └── dashboard_card.dart
├── models/
├── services/
├── firebase_options.dart
└── main.dart
```

---

# 🎯 Getting Started

## 📋 Prerequisites

* Flutter SDK 3.0+
* Firebase Project Setup
* Android Studio / VS Code

---

## ⚙ Installation

Clone the repository:

```
git clone https://github.com/yourusername/S84-0226-TeamHAK-Mobile-App-With-Flutter-And-Firebase-Sevadaar.git
cd Sevadaar
```

Install dependencies:

```
flutter pub get
```

Configure Firebase:

* Add google-services.json to android/app/
* Add GoogleService-Info.plist to ios/Runner/
* Ensure firebase_options.dart is configured

Run the app:

```
flutter run
```

---

# 🧪 Testing Plan

## 🔐 Authentication Test

1️⃣ Register account
2️⃣ Login
3️⃣ Close app
4️⃣ Reopen

✅ Expected: Auto-login to dashboard

---

## 🔄 Workflow Test

1️⃣ Admin creates task
2️⃣ Admin assigns volunteer
3️⃣ Volunteer updates status
4️⃣ Admin approves task

✅ Expected: Real-time updates reflected instantly

---

## 🛡 Role-Based Access Test

Volunteer:

* ❌ Cannot approve tasks
* ❌ Cannot view all tasks

Admin:

* ✅ Can view all tasks
* ✅ Can approve tasks

---

# 🎨 Design Philosophy

🌍 Social Impact Focus
🔵 Trust-driven color system
🟢 Green for approval
🟠 Orange for in-progress
📊 Clear visual hierarchy

---

# 📈 Non-Functional Highlights

⚡ Smooth UI transitions
🔐 Secure Firestore rules
📱 Responsive layouts
📊 Real-time synchronization
📈 Scalable Firestore structure

---

# 👥 Team HAK

🧑‍💻 Kartikay – UI & System Design
🧑‍💻 Harsh – Firebase Integration
🧑‍💻 Avinash – Workflow Logic & Testing

🤝 Collaborative full-stack development model.

---

# 🎯 Vision

Sevadaar is engineered to bring structure, accountability, and transparency to NGO volunteer coordination through a real-time, mobile-first experience that connects people, purpose, and technology.

---
