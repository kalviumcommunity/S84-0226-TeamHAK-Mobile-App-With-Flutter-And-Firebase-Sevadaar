# 🛡 Sevadaar Admin Guide (NGO Owner)

Welcome to **Sevadaar – Volunteer Coordination System**

This guide explains how an **NGO Owner / Admin** can use the app to create tasks, assign volunteers, and approve completed work.

> 🏢 Admin = NGO Owner / Coordinator  
> Admin controls workflow and manages volunteers

---

# 🚀 Getting Started

## 1️⃣ Open App

Launch the Sevadaar mobile app.

You will see:

- Splash Screen
- Login Screen

---

## 🔐 Login as Admin

1. Enter email
2. Enter password
3. Tap Login

If your role = admin  
You will open → **Admin Dashboard**

If not admin → Volunteer dashboard opens

---

## 📝 Register as Admin (Only if allowed)

1. Tap Register
2. Enter name
3. Enter email
4. Enter password
5. Select role → admin
6. Create account

⚠ In real NGO use, admin accounts should be restricted.

---

# 📊 Admin Dashboard

Admin dashboard shows:

- Total Tasks
- Assigned Tasks
- In Progress Tasks
- Completed Tasks
- Approved Tasks

Admin can see ALL tasks.

Volunteers can see only their tasks.

---

# 📋 Task Workflow

Sevadaar workflow:

Created → Assigned → In Progress → Completed → Approved

Admin controls:

Created
Assigned
Approved

Volunteer controls:

In Progress
Completed

---


# 📝 Create New Task

Steps:

1. Open Admin Dashboard
2. Tap Create Task
3. Enter title
4. Enter description
5. Select volunteer
6. Set deadline
7. Save

Status = Created / Assigned

Task will appear in volunteer dashboard.

---

# 👥 Assign Volunteer

When creating task:

Choose user from volunteer list.

Field used:

assignedTo

Only assigned volunteer can update task.

---

# 🚧 Track Task Progress

Admin can see:

- Who is working
- Status
- Deadline
- Completion

Statuses:

Assigned → not started  
In Progress → working  
Completed → waiting approval  
Approved → finished

---

# ✅ Approve Completed Task

When volunteer marks completed:

1. Open task
2. Check details
3. Tap Approve

Status becomes → Approved

This means work is verified.

---

# 🔁 Reassign Task (Optional)

If wrong volunteer:

1. Open task
2. Edit
3. Change assigned user
4. Save

Task moves to new volunteer.

---

# 📜 View All Tasks

Admin can:

View all tasks
Filter by status
Filter by volunteer
Filter by deadline

Volunteers cannot do this.

---

# 👤 Manage Profile

Admin can:

View name
View email
Logout

Logout ends session.

Firebase keeps login active until logout.

---

# 🔐 Admin Permissions

Admin CAN:

✅ Create tasks  
✅ Assign volunteers  
✅ View all tasks  
✅ Approve tasks  
✅ Reassign tasks  
✅ View all users  

Admin CANNOT:

❌ Update volunteer profile  
❌ Delete Firebase users (unless backend allowed)

---

# ⚠ Important Rules for NGO Owner

✔ Do not share admin account  
✔ Assign tasks clearly  
✔ Approve only after checking  
✔ Use deadlines properly  
✔ Monitor progress daily  

---

# 🔒 Security Note

In production:

Admin registration should be disabled.

Only system owner should create admin.

Possible methods:

- Admin whitelist
- Secret code
- Manual role change in Firestore

---

# ❓ Common Issues

## Cannot see volunteers

Check Users collection

Role must be:

volunteer

---

## Cannot approve task

Status must be:

Completed

---

## Task not visible to volunteer

Check assignedTo field

Must contain correct user reference.

---

# 🤝 NGO Workflow with Sevadaar

Admin → Creates task  
Admin → Assigns volunteer  
Volunteer → Works  
Volunteer → Completes  
Admin → Approves  

This ensures:

Transparency
Accountability
Structured service

---

# 🌍 Thank You

Sevadaar helps NGOs manage volunteers efficiently.

Admin role keeps the system organized.

Built with Flutter + Firebase