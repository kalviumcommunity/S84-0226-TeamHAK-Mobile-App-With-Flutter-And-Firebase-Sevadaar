# 🌍 Sevadaar

https://github.com/user-attachments/assets/7c5a48af-4af0-4e19-b2c9-14fb01bd8952



**A robust, real-time NGO Task & Volunteer Management System built to empower non-profits with automated workflows, transparent task delegation, and centralized communication.**

> 🤝 *Empowering service through technology*   
> 📊 *Bringing structure to volunteer coordination*   
> ⚡ *Delivering real-time impact*

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-blue?style=for-the-badge)](https://riverpod.dev/)

---

## 📌 Table of Contents
- [About The Project](#-about-the-project)
- [Key Features](#-key-features)
- [Role Hierarchies](#-role-hierarchies)
- [Workflow Deep Dive](#-workflow-deep-dive)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Meet Team HAK](#-meet-team-hak)

---

## 📖 About The Project

Sevadaar bridges the operational gap between Super Admins (NGO Leaders), Admins (Project Managers), and Volunteers (On-the-ground workforce). By leveraging dynamic progress tracking and a First-Come-First-Serve (FCFS) assignment model, Sevadaar completely eliminates the friction of manual task delegation.

---

## 🚀 Key Features

* 🔐 **Multi-Tier Authentication:** Secure, role-based login via Firebase Auth.
* 🏃 **FCFS Task Engine:** Smart, race-condition-free task acceptance.
* 📈 **Dynamic Progress Math:** System recalculates overall progress automatically when individual workloads shift or users drop out.
* ⏳ **Urgency Indicators:** Color-coded timelines (Green, Yellow, Red) based on approaching deadlines.
* 💬 **Automated Chat Rooms:** Contextual group chats provisioned directly from active tasks.
* ⚡ **Instant Sync:** Real-time NoSQL updates powered by Cloud Firestore.

---

## 👥 Role Hierarchies

### 👑 Developer / Super Admin (The Apex)
* Pre-seeded into the system infrastructure.
* Has global visibility over all tasks, users, and transactions.
* **Core Action:** Promotes active Volunteers to Admins (or demotes them), and sets high-level "To-Do" checklist tasks for Admins to execute.

### 👩‍💼 Admin (The Project Manager)
* Directly manages standard Volunteers.
* **Core Action:** Creates percentage-based tasks, invites volunteers, reviews/approves progress updates, and ensures task progression. Moderates auto-generated group chats.

### 👤 Volunteer (The Workforce)
* The dynamic workforce that accepts tasks on a FCFS basis.
* **Core Action:** Submits manual, documented progress reports to Admins. Can toggle availability visibility ("Active/Inactive").

---

## 📊 Workflow Deep Dive

1. **The Task Race (FCFS)**  
   When a task requiring  volunteers is published to a pool, the first  to accept lock in their spots. A Firebase Transaction automatically revokes the invite for the remaining users.
2. **Progress Mathematics**  
   Task completion isn't a guess—it's calculated. As volunteers submit progress on their segments, the overall task progression updates the moment an Admin hits "Approve". If a volunteer leaves the team halfway, the system instantly recalculates the main progress bar based on the remaining active members. 
3. **Deadlines & Danger Zones**  
   Task cards dynamically shift UI states:  
   🟢 **Green:** Relaxed (> 50% time left)  
   🟡 **Yellow:** Impending (30% - 50% time left)  
   🔴 **Red:** Danger Zone (< 30% time left)
4. **Chat Archiving**  
   When an active task hits 100% completion, its corresponding internal team chat is immediately flagged as read-only. 

---

## 🛠 Tech Stack

* **Frontend Framework:** Flutter (Dart)
* **State Management:** Riverpod
* **Backend Database:** Cloud Firestore
* **Authentication:** Firebase Auth & Google Sign-In
* **Serverless Backend:** Firebase Cloud Functions (Timeout triggers, complex math calculations)
* **Push Notifications:** Firebase Cloud Messaging (FCM)

---

## 💻 Getting Started

### Prerequisites
* Flutter SDK (3.11.0 or newer)
* Firebase CLI Configuration
* Code Editor (VS Code / Android Studio)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kalviumcommunity/S84-0226-TeamHAK-Mobile-App-With-Flutter-And-Firebase-Sevadaar.git
   cd Sevadaar
   ```
2. **Install Flutter Dependencies**
   ```Bash
   flutter pub get
   ```
3. **Run the App**
   ```Bash
   flutter run
   ```

---

## 👨‍💻 Meet Team HAK

The team adopted a **holistic, cross-functional collaboration model** to deliver Sevadaar, operating without rigid silos to ensure seamless feature integration.

* 🎨 **Harsh:** Drove the frontend UI/UX implementations, visual design system, styling structures, and tackled critical application bug fixes.
* ⚙️ **Avinash & Kartikay:** Led the core system architecture, business logic workflows, screen functionalities, and formulated the overall product idea and system design. 

*(Everyone touched the entire codebase to bring the project together as a cohesive unit.)*

---
