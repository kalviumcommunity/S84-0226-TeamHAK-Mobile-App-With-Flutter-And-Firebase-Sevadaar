# Sevadaar - Setup & Configuration Guide

## Overview

Sevadaar is a volunteer management platform built with Flutter and Firebase. This guide explains how to set everything up and make authentication work.

---

## **Part 1: Why Login/Signup May Not Be Working**

### Current Status
- ✅ **Linux Desktop**: UI-only testing mode (Firebase features disabled for development)
- ⏳ **Android/iOS/Web**: Full Firebase functionality requires proper configuration

### Why Authentication Features Don't Work on Linux
Firebase SDKs are **platform-specific**:
- `firebase_core`, `firebase_auth`, `cloud_firestore` only have native implementations for Android, iOS, and Web
- Linux is a desktop platform with no Firebase plugin support
- On Linux, the app shows UI placeholders but cannot authenticate

**Solution**: To test login/signup, you need an actual device, emulator, or web platform.

---

## **Part 2: Setting Up Firebase (Mobile/Web)**

### Step 1: Verify Firebase Project Exists
Your Firebase project is already created at: `https://console.firebase.google.com/project/sevadaar`

### Step 2: Configure Android App

1. **Open Firebase Console** → Project: `sevadaar`
2. **Add Android App** (if not already added):
   - Package name: `com.teamhak.sevadaar.sevadaar`
   - SHA-1 certificate: Get from your Android keystore
     ```bash
     # Run this command to get your SHA-1:
     cd android && ./gradlew signingReport
     ```
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

### Step 3: Configure iOS App

1. **Firebase Console** → Add iOS App
   - Bundle ID: `com.teamhak.sevadaar` (or as configured)
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

### Step 4: Configure Google Sign-In

#### For Android:
1. Firebase Console → Authentication → Sign-in methods
2. Enable **Google Sign-In**
3. Add SHA-1 from your keystore (see Step 2)

#### For iOS:
1. Firebase Console → Authentication → Sign-in methods
2. Enable **Google Sign-In**
3. In Xcode: `Runner` → Signing & Capabilities → Add `Sign In with Google`
4. Configure reverse client ID in `GoogleService-Info.plist`

#### For Web:
1. Firebase Console → Authentication → Sign-in methods → Google (already enabled)
2. No additional configuration needed

### Step 5: Verify Environment Variables

Check `.env` file contains all required keys:
```dotenv
# Web
WEB_API_KEY=AIzaSyDHDJhl8axlrmneDbIZ_Bl-uJ1Qhi6dC5g
WEB_APP_ID=1:311701115408:web:47d04b4c03ffa446b23095
WEB_AUTH_DOMAIN=sevadaar.firebaseapp.com
WEB_PROJECT_ID=sevadaar
...

# Android
ANDROID_API_KEY=AIzaSyAKXjGU6_5kXIcQNeKzlv4dH0gse3I1d5o
ANDROID_APP_ID=1:311701115408:android:3056a0f7861ac1b1b23095
...
```

### Step 6: Test on Device/Emulator

#### Android Emulator:
```bash
flutter run  # Will auto-detect emulator
# OR
flutter run --device-id emulator-5554
```

#### Android Device:
```bash
flutter run  # Will auto-detect connected device
```

#### iOS Simulator:
```bash
flutter run -d "iPhone 14 Pro"  # List available: flutter devices
```

#### Web:
```bash
flutter run -d web-server  # Then open http://localhost:5000
```

---

## **Part 3: Creating a Super Admin Account**

### Automatic Method (Recommended)

We've provided a Node.js script to promote any user to super admin:

#### Prerequisites:
```bash
cd scripts
npm install   # Install firebase-admin dependency
```

#### Setup:
1. **Get Firebase Service Account Key**:
   - Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save as `scripts/serviceAccountKey.json`
   - ⚠️ Keep this file SECRET (add to `.gitignore`)

2. **Run Promotion Script**:
   ```bash
   cd scripts
   node promote_super_admin.js --email your-email@gmail.com
   ```

   Output:
   ```
   ✅ User 'your-email@gmail.com' promoted to super_admin!
   ```

### Manual Method (Firestore Console)

1. **Create a regular account first**:
   - Run app on mobile/web
   - Sign up with email/password or Google Sign-In

2. **Promote via Firebase Console**:
   - Go to: `https://console.firebase.google.com/project/sevadaar/firestore`
   - Collection: `users`
   - Find the user document
   - Edit `role` field from `volunteer` → `super_admin`
   - Save

3. **Reload the app** - You should now access Super Admin Dashboard

---

## **Part 4: Testing Auth Flows**

### Sign Up with Email/Password

1. **Tap "Sign Up"** on LoginScreen
2. **Enter**:
   - Full name: `John Doe`
   - Email: `john@example.com`
   - Password: `Password123`
   - Organisation code: `12345678` (must exist in Firestore `ngos` collection)
3. **Tap "Create Account"** → Routes to RoleRouter → Dashboard

### Sign Up with Google

1. **Tap "Continue with Google"** on SignupScreen
2. **Select account** → Google authentication
3. **First-time Google users**:
   - Shown form to enter name + organization code
   - After submission → Routes to dashboard
4. **Existing Google users**:
   - Directly routes to dashboard (no form)

### Sign In with Email/Password

1. **LoginScreen** → Enter email + password
2. **Tap "Sign In"** → Routes to RoleRouter → Dashboard

### Sign In with Google

1. **LoginScreen** → Tap Google button
2. Same flow as Sign Up above

### Create NGO Application (Become Super Admin)

1. **LoginScreen** → Tap "Have an NGO? Become a Super Admin"
2. **Fill form**:
   - Your Details: name, email
   - NGO Details: name, description, address, phone
3. **Submit** → Firestore saves + EmailJS email sent (if configured)
4. **Next steps**: Contact team for super admin approval

---

## **Part 5: Configuring Email Notifications (Optional)**

For NGO application emails, configure EmailJS:

1. **Create EmailJS Account**: https://www.emailjs.com
2. **Add Service** (Gmail):
   - Service ID: `gmail`
   - Setup authorized SMTP connection
3. **Create Template**:
   - Template ID: (your-template-id)
   - Variables: `{applicant_name}`, `{ngo_name}`, etc.
4. **Update `.env`**:
   ```dotenv
   EMAILJS_SERVICE_ID=gmail
   EMAILJS_TEMPLATE_ID=your-template-id
   EMAILJS_PUBLIC_KEY=your-public-key
   ```
5. Restart app for changes to take effect

---

## **Part 6: Firestore Database Setup**

### Collections to Create

Auto-created by the app on first use, or manually:

#### 1. `users` Collection
```json
{
  "uid": "firebaseUID",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "volunteer|admin|super_admin",
  "status": "active|inactive",
  "orgId": "ngoDocId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2. `ngos` Collection
```json
{
  "ngoId": "documentId",
  "name": "NGO Name",
  "description": "...",
  "address": "...",
  "contactEmail": "...",
  "joinCode": "12345678",  // 8-digit code, unique
  "superAdminId": "firebaseUID",
  "createdAt": "timestamp"
}
```

#### 3. `ngo_applications` Collection
```json
{
  "applicationId": "documentId",
  "applicantName": "...",
  "applicantEmail": "...",
  "ngoName": "...",
  "ngoDescription": "...",
  "ngoAddress": "...",
  "ngoPhone": "...",
  "status": "pending|approved|rejected",
  "submittedAt": "timestamp"
}
```

#### 4. `tasks` Collection (future)
```json
{
  "taskId": "documentId",
  "title": "...",
  "description": "...",
  "orgId": "ngoDocId",
  "status": "active|completed",
  "createdAt": "timestamp"
}
```

---

## **Part 7: Firestore Security Rules**

Update Security Rules in Firebase Console → Firestore → Rules:

```firestore_rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: Only own doc + admins of same org
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId || 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // NGOs: Super admins who created them
    match /ngos/{ngoId} {
      allow read: if resource.data.superAdminId == request.auth.uid;
      allow write: if request.auth.uid == resource.data.superAdminId;
      allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // NGO Applications: Public read for admins only
    match /ngo_applications/{docId} {
      allow read, write: if request.auth != null;
    }
    
    // Tasks: Org members only
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.orgId == resource.data.orgId;
    }
    
    // Default: deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## **Part 8: Troubleshooting**

### "Firebase App not initialized" on Linux
✅ **Expected behavior** - Firebase doesn't support Linux. Use mobile/web for testing.

### "Invalid NGO code" error
- Code must be exactly 8 digits
- Code must exist in Firestore `ngos` collection
- Check super admin created the NGO first

### Google Sign-In fails
1. Verify SHA-1 certificate added to Firebase (Android)
2. Verify bundle ID matches Firebase config (iOS)
3. Verify Google Service credentials in project

### "No Firebase App '[DEFAULT]' created"
- Ensure Firebase is initialized before auth calls
- Check `.env` file has all required keys
- Restart app after `.env` changes

### Email notifications not sending
- Optional feature; app works without it
- Verify `.env` has EmailJS keys
- Check EmailJS dashboard for error logs

---

## **Part 9: Deployment Checklist**

Before production:

- [ ] Firebase project created and configured
- [ ] Android app configured with SHA-1
- [ ] iOS app configured with bundle ID
- [ ] Google Sign-In enabled for all platforms
- [ ] Firestore security rules updated
- [ ] `.env` file with all credentials set (and not in git)
- [ ] First super admin created via script
- [ ] First NGO created by super admin
- [ ] Test email notifications (optional)
- [ ] Test all sign-in methods on device/web
- [ ] Verify role-based routing works
- [ ] Update .env before any commit

---

## **Quick Start Recap**

```bash
# 1. Setup environment
cd /path/to/sevadaar
cat .env  # Verify Firebase credentials

# 2. Create super admin
cd scripts
npm install
node promote_super_admin.js --email admin@example.com

# 3. Test on mobile
flutter run  # Connect device or open emulator first

# 4. Sign in with email/password or Google
# 5. Navigate to Super Admin Dashboard
# 6. Create NGO with auto-generated 8-digit code
# 7. Share code with volunteers for signup
```

---

## **Support**

For questions:
- Check Firestore Console for data validation
- Review `.env` file configuration
- Test on real device, not Linux desktop
- Check Firebase project settings match credentials
