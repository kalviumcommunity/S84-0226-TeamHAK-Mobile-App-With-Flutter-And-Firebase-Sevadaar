# Login & Signup Implementation Documentation

## Overview

The Sevadaar mobile app implements a comprehensive authentication system using Firebase Authentication and Firestore. The system supports multiple authentication methods and integrates with the NGO (Non-Governmental Organization) management features.

## Authentication Architecture

### Core Components

1. **AuthService** (`lib/services/auth_service.dart`)
   - Handles all Firebase Authentication operations
   - Manages Firestore user profile storage
   - Provides Google Sign-In integration
   - Includes error handling and user-friendly messages

2. **AuthProvider** (`lib/state/auth_provider.dart`)
   - Riverpod-based state management
   - Streams Firebase auth state changes
   - Maintains current user profile state

3. **Authentication Screens**
   - `LoginScreen` - Main login interface
   - `SignupScreen` - User registration
   - `GoogleSignupFormScreen` - Profile completion for Google users

## User Roles & Permissions

The system supports three user roles:
- **Volunteer** - Default role for regular users
- **Admin** - NGO administrators
- **Super Admin** - System administrators

## Authentication Flows

### 1. Email/Password Signup

**Process:**
1. User provides: name, email, password, 8-digit NGO join code
2. System validates NGO code against Firestore `ngos` collection
3. Creates Firebase Auth account
4. Stores user profile in Firestore `users` collection
5. Sets default role as 'volunteer'
6. Updates Firebase Auth display name
7. Redirects to role-based dashboard

**Key Methods:**
- `AuthService.signUp()`
- `NgoService.validateJoinCode()`

### 2. Email/Password Login

**Process:**
1. User provides email and password
2. Firebase Auth verifies credentials
3. Retrieves user profile from Firestore
4. Handles fallback lookup by email for pre-created accounts
5. Redirects to role-based dashboard

**Key Methods:**
- `AuthService.signIn()`
- `AuthService.getUserProfile()`

### 3. Google Sign-In

**Process:**
1. User initiates Google OAuth flow
2. Firebase Auth processes Google credentials
3. System checks for existing user profile:
   - First by Firebase UID
   - Then by email (for pre-created accounts)
4. **New Google Users:**
   - Redirected to `GoogleSignupFormScreen`
   - Must provide name and NGO join code
   - Profile created in Firestore
5. **Returning Google Users:**
   - Direct access to dashboard

**Key Methods:**
- `AuthService.signInWithGoogle()`
- `AuthService.completeGoogleSignUp()`

## Data Models

### UserModel
```dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'volunteer', 'admin', 'super_admin'
  final String status; // 'active', etc.
  final String orgId; // NGO organization ID
  final DateTime createdAt;
  // ... additional fields
}
```

## Security Features

- **NGO Code Validation:** 8-digit codes required for signup
- **Email Verification:** Firebase Auth handles email validation
- **Password Requirements:** Minimum 6 characters (Firebase default)
- **Profile Completion:** Google users must complete NGO association
- **Role-Based Access:** Different permissions based on user roles

## Error Handling

The system provides user-friendly error messages for common scenarios:
- Email already in use
- Invalid email format
- Weak password
- User not found
- Incorrect password
- Too many requests
- Invalid NGO code

## UI/UX Features

### Login Screen
- Animated particle background
- Staggered entrance animations
- Glassmorphic design elements
- Gradient accents
- Form validation with real-time feedback
- Links to signup and NGO application

### Signup Screen
- Consistent design with login screen
- NGO code input with validation
- Google sign-in option
- Link to NGO application for organizations

### Google Signup Form
- Pre-filled name from Google profile
- NGO code requirement
- Clean, focused completion flow

## Integration Points

- **Role Router:** Directs users to appropriate dashboards based on role
- **NGO Service:** Validates join codes and manages organization data
- **Firebase Firestore:** Stores user profiles and NGO information
- **Riverpod:** Manages authentication state across the app

## Future Enhancements

Potential improvements could include:
- Email verification flow
- Password reset UI
- Multi-factor authentication
- Social login expansion (Facebook, Apple)
- Advanced role management
- Audit logging for security events