# Admin Dashboard Documentation

## Overview
The Admin Dashboard is a comprehensive Flutter-based interface designed for NGO administrators to manage tasks, volunteers, and progress requests. It provides a centralized hub for overseeing volunteer activities and task completion.

## Core Purpose
The dashboard serves as the administrative control panel where NGO administrators can:
- Create and manage volunteer tasks
- Monitor task progress and volunteer participation
- Review and approve/reject volunteer progress update requests
- Track task status across different stages (inviting, active, completed)
- View NGO information and admin profile details

## Architecture

### Key Dependencies
| Dependency | Purpose |
|------------|---------|
| Firebase Authentication | User management |
| Cloud Firestore | Real-time data storage |
| StreamBuilder | Real-time data streams |
| AnimationController | Smooth transitions |
| Google Fonts | Typography theming |

### Main Components

#### 1. **AdminDashboard (Main Widget)**
Entry point with tab-based navigation that manages user authentication state and NGO profile loading.

**Properties:**
- Tab navigation (Tasks/Requests/Sign Out)
- User profile loading
- Animated transitions
- Bottom navigation bar with pending request badge

#### 2. **Tasks Tab (_TasksTab)**
Displays all tasks created by the admin with real-time updates and filtering capabilities.

**Features:**
| Feature | Description |
|---------|-------------|
| Real-time stream | Live task updates from Firestore |
| Status filtering | Filter by Active/Inviting/Completed |
| Visual cards | Progress bars, deadlines, volunteer counts |
| Urgency indicators | Color-coded based on deadline proximity |
| Expired handling | Resolution dialog for expired invitations |
| Task creation | FAB to create new tasks |

**Task Status Flow:**
```
Inviting → Active → Completed
   ↑         ↓
Expired    Active (in progress)
```

#### 3. **Requests Tab (_RequestsTab)**
Manages volunteer progress update requests with approve/reject functionality.

**Request Data Display:**
- Volunteer name and avatar
- Task title
- Current progress vs requested progress
- Mandatory notes from volunteer
- Approve/Reject action buttons

**Request Processing Flow:**
```
Volunteer submits request
         ↓
Admin reviews in dashboard
         ↓
    ┌────┴────┐
    ↓         ↓
 Approve    Reject
    ↓         ↓
Task progress  Request
updated       removed
```

#### 4. **Header Component (_Header)**
Personalized greeting section displaying:
- Admin name and initials
- Current date
- NGO information (name, join code)
- Visual branding elements

#### 5. **Stat Bar (_StatBar)**
Quick overview and filtering component:
- Active tasks count (green)
- Inviting tasks count (blue)
- Completed tasks count (grey)
- Tap to filter tasks by status

## Data Models

### TaskModel
```dart
{
  taskId: String,
  title: String,
  description: String,
  status: String,        // 'inviting', 'active', 'completed'
  createdAt: DateTime,
  deadline: DateTime,
  inviteDeadline: DateTime,
  maxVolunteers: int,
  assignedVolunteers: List<String>,
  mainProgress: double
}
```

### ProgressRequestModel
```dart
{
  requestId: String,
  taskId: String,
  taskTitle: String,
  volunteerId: String,
  currentProgress: double,
  requestedProgress: double,
  mandatoryNote: String,
  status: String         // 'pending', 'approved', 'rejected'
}
```

## Visual Design System

### Color Palette
| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary Blue | `#4A6CF7` | Primary actions, inviting status |
| Green | `#22C55E` | Active tasks, approval actions |
| Orange | `#F59E0B` | Warnings, urgent items |
| Red | `#EF4444` | Rejection, deletion |
| Dark Blue | `#0D1B3E` | Hero card background |
| Text Primary | `#0D1B3E` | Main text |
| Text Secondary | `#6B7280` | Supporting text |

### Typography
- **Font Family**: DM Sans (Google Fonts)
- **Weights**: 400 (Regular), 500 (Medium), 700 (Bold), 800 (Extra Bold)
- **Sizes**: Ranging from 10px to 28px

### Components
| Component | Description |
|-----------|-------------|
| Task Card | Rounded container with urgency strip |
| Status Chip | Colored label for task status |
| Stat Pill | Selectable statistic display |
| Avatar | Circular user initial display |
| Progress Badge | Percentage display with background |

## User Flows

### 1. Authentication Flow
```
App Launch
    ↓
Load User Profile
    ↓
Fetch NGO Data
    ↓
Display Dashboard
    ↓
[Error] → Show Login Screen
```

### 2. Task Management Flow
```
View Tasks Tab
    ↓
[Filter by Status] or [View All]
    ↓
Tap Task Card
    ↓
[If Expired] → Show Resolution Dialog
    ↓
[If Active] → Navigate to Task Details
    ↓
[Create New] → Tap FAB → Create Task Screen
```

### 3. Request Processing Flow
```
Navigate to Requests Tab
    ↓
View Pending Requests
    ↓
Review Progress and Notes
    ↓
Choose Action:
    ├─ Approve → Update Task Progress
    └─ Reject → Confirm → Remove Request
    ↓
Snackbar Confirmation
```

## Error Handling

| Error Type | Handling Method |
|------------|-----------------|
| Database Index | User-friendly message with instructions |
| Missing Profile | Empty state with retry option |
| Network Issues | StreamBuilder connection states |
| No Data | Custom empty state widgets |
| Authentication | Redirect to login |

## Key Functions

### Urgency Calculation
```dart
Color taskUrgencyColor(DateTime createdAt, DateTime deadline) {
  // Returns green (>50% time remaining)
  // Returns orange (30-50% time remaining)
  // Returns red (<30% time remaining or expired)
}
```

### Request Approval
```dart
Future<void> _approve() async {
  // Updates task progress to requested value
  // Shows success/error snackbar
  // Removes request from pending list
}
```

### Request Rejection
```dart
Future<void> _reject() async {
  // Shows confirmation dialog
  // Removes request without updating progress
  // Shows confirmation snackbar
}
```

## Real-time Updates
- All task data streams update automatically
- Pending request count updates on navigation badge
- No manual refresh required
- Instant feedback on approve/reject actions

## Security Features
- Authentication required for all routes
- Admin-specific data filtering by user ID
- NGO data tied to admin's organization
- Requests only visible for owned tasks

## Performance Optimizations
- `BouncingScrollPhysics` for smooth scrolling
- `AnimatedContainer` for efficient transitions
- `StreamBuilder` for minimal rebuilds
- `const` constructors where possible
- `ListView.builder` for memory efficiency

## Reusable Components

### _Avatar
Circular profile indicator with user initial.

### _Chip
Colored status indicator with label.

### _StatPill
Selectable statistic display with counter.

### _PulseLoader
Loading indicator with consistent styling.

### _LightDialog
Custom confirmation dialog with consistent theming.

## Future Enhancement Possibilities

1. **Task Editing**: Modify existing tasks
2. **Volunteer Management**: View and manage volunteers
3. **Analytics Dashboard**: Task completion metrics
4. **Export Reports**: Generate PDF/CSV reports
5. **Push Notifications**: Alert for new requests
6. **Task Templates**: Reusable task structures
7. **Performance Metrics**: Volunteer productivity tracking
8. **Bulk Operations**: Multi-select for approvals

## Technical Specifications

### Environment
- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase (Auth + Firestore)
- **Minimum SDK**: Flutter 3.x

### State Management
- Stream-based reactive programming
- Local state with setState for UI interactions
- InheritedWidget alternatives via service pattern

### Animations
| Animation | Duration | Trigger |
|-----------|----------|---------|
| Page Fade | 250ms | Navigation |
| Button Scale | 90-100ms | Press |
| Container | 200ms | Selection |
| Dashboard Fade | 500ms | Load complete |