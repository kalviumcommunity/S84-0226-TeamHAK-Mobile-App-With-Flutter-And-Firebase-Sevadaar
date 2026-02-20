# 📄 Project Description: NGO Task & Volunteer Management System

## 1\. Executive Summary

The NGO Task & Volunteer Management System is a centralized, real-time mobile application built to streamline operations, task delegation, and communication within a Non-Governmental Organization (NGO). The platform bridges the gap between organizational leaders (Super Admins), project managers (Admins), and on-the-ground workers (Volunteers). It features a robust First-Come-First-Serve (FCFS) task assignment engine, mathematically dynamic progress tracking, time-based visual urgency indicators, and integrated real-time communication.

## 2\. Technology Stack

* **Frontend:** Flutter (Dart) for building a natively compiled, cross-platform mobile application (iOS & Android).  
* **State Management:** Riverpod or BLoC (for reactive state binding).  
* **Backend:** Google Firebase  
  * **Firebase Authentication:** Secure email/password login and role-based access.  
  * **Cloud Firestore:** Real-time NoSQL database for syncing tasks, progress, and chats.  
  * **Firebase Cloud Functions:** Serverless functions for heavy logic (e.g., 24-hour timeout triggers, mathematical recalculations).  
  * **Firebase Cloud Messaging (FCM):** For push notifications.  
  * **Firebase Storage:** (Optional) For profile pictures or task image attachments.

---

## 3\. User Roles & Hierarchies

The application operates on a strict three-tier hierarchy:

### A. Super Admin (The Apex User)

* **Onboarding:** Pre-seeded into the database by developers.  
* **Capabilities:**  
  * Full visibility over the entire NGO's operations.  
  * Promotes registered Volunteers to Admins, or demotes Admins back to Volunteers based on performance.  
  * Assigns high-level **"To-Do" Tasks** to Admins (e.g., "Organize a beach cleanup drive"). These are simple checklist-style tasks rather than percentage-based tasks.  
  * Manages their own profile.

### B. Admin (The Project Manager)

* **Capabilities:**  
  * Creates detailed, percentage-based operational tasks.  
  * Invites Volunteers to tasks and manages the volunteer pool.  
  * Approves or Rejects volunteer progress updates.  
  * Overviews task completion, monitors task deadlines, and handles volunteer dropouts/removals.  
  * Accesses and moderates automated task-based group chats.

### C. Volunteer (The Workforce)

* **Onboarding:** All new users register via the app natively as Volunteers.  
* **Capabilities:**  
  * Toggles profile status between **Active** and **Inactive** (visibility toggle to signal availability for work).  
  * Receives task invitations and accepts/declines them.  
  * Submits manual progress requests (e.g., 0% to 30%) accompanied by mandatory textual notes.  
  * Communicates via 1-on-1 direct messaging or task-specific group chats.

---

## 4\. Detailed Application Flows

### Flow 1: Task Assignment & The FCFS Engine

1. **Task Creation:** Admin creates a task, setting a Title, Description, Deadline, and the `Max Volunteers` required (e.g., needs 3 people).  
2. **Invitation:** Admin selects a pool of Volunteers (e.g., invites 10 active volunteers) and sends out the task.  
3. **Notification:** The 10 volunteers receive a Push Notification: *"New task available\!"*  
4. **FCFS Locking (First-Come-First-Serve):** Volunteers view the task and click "Accept." The backend uses **Firestore Transactions** to prevent race conditions. The first 3 volunteers to accept are locked into the task. For the remaining 7, the task instantly disappears from their screens.  
5. **Insufficient Acceptance & Timer:** A 24-hour Cloud Function timer starts upon task creation. If the Admin invited 5 people for a 3-person task, but only 1 accepts within 24 hours, the Admin is notified. The Admin can then choose to close the task pool, officially dividing 100% of the task's workload to that single volunteer.

### Flow 2: Progress Tracking & Approval Workflow

Progress is dynamically calculated based on approved individual efforts.

1. **Execution:** Volunteer finishes a portion of their assigned work.  
2. **Submission:** Volunteer submits a **Progress Request** (e.g., changing their personal completion from 25% to 50%) and fills out a mandatory "What I did" note.  
3. **Review:** The Admin receives the request, reviews the note, and clicks **Approve** (or Reject).  
4. **Dynamic Math Calculation:** Upon approval, the Main Task Progress Bar recalculates automatically.  
   * *Formula:* `Main Progress = (Sum of all volunteers' individual progress percentages) / Total number of assigned volunteers`.  
   * *Example:* 3 volunteers are assigned (each responsible for 33.3% of the whole). If Volunteer A completes their 100%, the main bar jumps to 33.3%.  
5. **Completion:** When the Main Progress hits 100%, the Admin adds a `Final Note` for record-keeping, and the task is marked as "Completed."

### Flow 3: Volunteer Removal & Dynamic Math Adjustment

If a volunteer abandons a task or is removed by the Admin, the system re-balances the math instantly:

* *Scenario:* Volunteers A, B, and C are assigned. Volunteer A completes their full share (Main bar \= 33.3%). Volunteer B drops out and is removed by the Admin.  
* *System Action:* The task is now divided between only A and C (50% responsibility each). Since A's work is already 100% complete, their weight in the project increases. The Main Progress bar automatically jumps from 33.3% to 50% to reflect the new mathematical reality.

### Flow 4: Timeline & Urgency Color Coding (UI Flow)

To help Admins and Volunteers manage time visually, the main task card changes color based on the **Time Remaining** (Deadline vs. Creation Date), *not* the progress percentage.

* **Green:** More than 50% of the original time duration remains. All is well.  
* **Orange/Yellow:** Between 30% and 50% of the time remains. The deadline is approaching.  
* **Red:** Less than 30% of the time remains. Danger zone—Admins should immediately check on the volunteers to ensure the deadline is met.

### Flow 5: The Communication (Chat) Flow

1. **Automated Group Chats:** Once a task reaches its required number of volunteers (or the Admin manually closes the invite phase), a Firestore trigger automatically provisions a Group Chat room. The Admin and all assigned Volunteers are automatically added to it.  
2. **Direct Messaging:** Users can search for other users and initiate 1-on-1 private messaging.  
3. **Chat Archiving:** The moment a task's Main Progress hits 100% and is marked completed, the associated Group Chat is flagged as `isArchived = true`. The frontend reads this flag and disables the text-input field, turning the chat into a **Read-Only** historical record.

---

## 5\. System Architecture & Database Entities (High-Level)

The application relies on a heavily normalized Firestore database:

* **`users` Collection:** Stores profile details, roles (`super_admin`, `admin`, `volunteer`), and availability statuses (`active`, `inactive`).  
* **`tasks` Collection:** Stores Admin-created tasks. Holds arrays of `pendingInvites` and `assignedVolunteers`. Tracks the `mainProgress` (0-100), `deadline`, and timeline states.  
* **`task_assignments` Collection:** Tracks the individual percentage completion (0-100) of a specific volunteer for a specific task.  
* **`progress_requests` Collection:** A staging area where pending progress updates (and mandatory notes) wait for Admin approval.  
* **`sa_tasks` Collection:** Simple boolean-based (True/False) checklists created by Super Admins and assigned to Admins.  
* **`chats` & `messages` Collections:** Manages chat metadata (participants, type, linked taskId, `isArchived` status) and chronological chat payloads.

## 6\. Security and Data Integrity Protocols

* **Firestore Security Rules:** Stringent rules dictate that Volunteers can only read tasks they are invited to or assigned to. They cannot approve their own progress.  
* **Transactional Integrity:** Firestore Transactions are utilized heavily during the FCFS acceptance phase to ensure that if a task needs 3 people, exactly 3 people are assigned, even if 10 people tap "Accept" on their phones at the exact same millisecond.  
* **Role-Based Routing:** At login, the app fetches the user's role via Custom Claims / Firestore Document and routes them to a specifically tailored Dashboard (Super Admin Dashboard vs. Admin Dashboard vs. Volunteer Dashboard), completely sandboxing features they do not have access to.

---

**End of Document**  
*This comprehensive guide serves as the architectural blueprint and operational manual for developing the NGO Task & Volunteer Management System.*  