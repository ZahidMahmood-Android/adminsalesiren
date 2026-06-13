# Firestore & Storage Permissions Guide

This guide helps troubleshoot and understand the Firestore and Firebase Storage security rules for the Salesiren Admin Panel.

## Overview

The app uses role-based access control:
- **Public users**: Can read published offers only
- **Admin users**: Can read/write all data, manage brands, offers, and reports
- **Admin status**: Determined by presence of `admins/{uid}` document in Firestore

## Security Rules Architecture

### Firestore Rules (`firestore.rules`)

```javascript
function isSignedIn() {
  return request.auth != null;
}

function isAdmin() {
  return isSignedIn()
    && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}
```

#### Collection Permissions

| Collection | Read | Write | Notes |
|------------|------|-------|-------|
| `cities` | Public | Admin only | Seed data, rarely changes |
| `categories` | Public | Admin only | Seed data, rarely changes |
| `brands` | Public | Admin only | Created by admins |
| `offers` | Published only (public) /<br/>All (admin) | Admin only | Status-based visibility |
| `offer_reports` | Any user (own)<br/>Admin (all) | Users (create own)<br/>Admin (manage) | User reports → Admin review |
| `users` | Self only<br/>Admin (view all) | Self only<br/>Admin (delete) | User profiles |
| `admins` | Self only | Disabled | Must be created via Firebase Console |
| `notification_campaigns` | Admin only | Admin only | Future feature |

### Storage Rules (`storage.rules`)

```javascript
function isAdmin() {
  return isSignedIn()
    && firestore.exists(/databases/default/documents/admins/$(request.auth.uid));
}

match /offers/{allPaths=**} {
  allow read: if true;                    // Public read
  allow write: if isAdmin()               // Admin write only
    && request.resource.size < 5MB        // Size limit
    && request.resource.contentType.matches('image/.*');  // Images only
}
```

## Common Permission Issues and Fixes

### Issue 1: "Permission Denied" After Login

**Symptoms:**
- Successfully logged in
- Dashboard shows "Admin access is not configured"
- Browser console shows no errors

**Root Cause:**
The admin user document doesn't exist in Firestore.

**Solution:**
Create the admin document manually in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Salesiren project
3. Go to **Firestore Database** → **Collections** tab
4. Click **+ Create collection**
5. Collection ID: `admins`
6. Click **Next**
7. Document ID: Copy your `uid` from the app UI (shown in the dialog)
8. Add field:
   - Field name: `email`
   - Type: `string`
   - Value: Your admin email
9. Click **Add field** again:
   - Field name: `role`
   - Type: `string`
   - Value: `owner` or `admin`
10. Click **Save**
11. Refresh the admin panel browser tab

### Issue 2: "Read Failed: Missing/Insufficient Permission"

**Symptoms:**
- Login works
- Dashboard shows error tooltips on metric cards
- Console shows: `FirebaseException: [cloud_firestore/permission-denied]`

**Root Cause:**
- Admin document is missing
- Rules not deployed
- Incorrect database reference

**Solution:**

**Step 1: Verify Admin Document Exists**
```bash
Firebase Console → Firestore → Collections → admins → {your-uid}
```

**Step 2: Deploy Security Rules**
```bash
cd /path/to/adminpanel
firebase deploy --only firestore:rules
```

**Step 3: Ensure Rules Match Current Code**
Compare `/firestore.rules` with Firebase Console:
```
Firebase Console → Firestore → Rules → Click "Edit rules"
```
The rules should match the content in `/firestore.rules`.

### Issue 3: "Write Failed: Missing/Insufficient Permission"

**Symptoms:**
- Can read data but cannot create/update brands or offers
- Buttons don't respond or show errors
- Console shows write permission errors

**Root Cause:**
- User is not an admin (missing admin document)
- Storage upload failing

**Solution:**

**For Firestore Writes:**
1. Verify admin document exists (see Issue 1)
2. Verify rules are deployed (see Issue 2)

**For Storage Writes (image upload):**
1. Verify image is under 5MB
2. Verify image is a valid image file (JPEG, PNG, etc.)
3. Ensure storage.rules is deployed:
   ```bash
   firebase deploy --only storage
   ```

### Issue 4: Composite Index Required

**Symptoms:**
- Offers list shows error
- Console shows: `PlatformException(Error performing query, The query requires a composite index)`

**Root Cause:**
Firestore requires composite indexes for queries with multiple `where` clauses.

**Solution:**
1. The error message in Firebase Console contains a clickable link
2. Click that link to automatically create the index
3. Wait 5-10 minutes for the index to build
4. Refresh the app

Alternatively, create manually:
```
Firebase Console → Firestore → Indexes → Create Composite Index
Collection: offers
Fields: cityId (Ascending), createdAt (Descending)
```

## Rule Deployment

### Deploy Rules from CLI

```bash
# Deploy all rules
firebase deploy --only firestore:rules,storage

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Storage rules
firebase deploy --only storage
```

### Verify Rules Are Deployed

1. Go to Firebase Console
2. **Firestore** → **Rules** tab
3. Should show the current rules
4. **Storage** → **Rules** tab
5. Should show the current rules

## Testing Rules Locally

### Firestore Rules Emulator

```bash
npm install -g firebase-tools
firebase emulators:start --only firestore
```

Then run app against emulator (requires configuration).

### Manual Testing in Console

1. Firebase Console → Firestore → Rules
2. Click **Rules playground** button
3. Test scenarios:
   - **Unauthorized read**: Leave auth empty, test read
   - **User read published**: Set auth with random UID, test read from offers
   - **Admin read all**: Set auth with admin UID (from admins collection), test read

## Understanding Rule Expressions

### Variable: `$(database)`
The current database ID (usually `default`).

### Function: `exists(path)`
Returns `true` if the document at `path` exists. Used to check admin status.

### Context: `request.resource`
The data being written. Used to check size, type, etc.

### Context: `resource.data`
The data already in Firestore. Used to check field values (e.g., `isPublished`).

## Debugging Steps

### 1. Check Browser Console (F12)

```
[FirebaseAuthRepository] Admin sign-in succeeded for uid=abc123
[FirebaseLoggedInView] Watching admin access
[FirebaseException] ... permission-denied ...
```

### 2. Check Firestore Rules Playground

Go to Firebase Console → Firestore → **Rules** → **Rules playground**

**Test a read:**
```
Collection: brands
Document: any-id
Auth: Set UID to your uid
```

### 3. Check Admin Document Exists

```
Firebase Console → Firestore
Collections → admins → {your-uid}
```

Verify fields:
- `email`: Your email
- `role`: `admin` or `owner`
- `createdAt`: Timestamp (if set)

### 4. Check Rules Syntax

```bash
cd /path/to/adminpanel
firebase deploy --only firestore:rules --dry-run
```

If rules have syntax errors, the dry-run will show them.

## Rule Syntax Reference

### Read Permission
```javascript
allow read: if <condition>;
```
Allows field reads and document existence checks.

### Write Permission
```javascript
allow write: if <condition>;
```
Allows create, update, and delete operations.

### Create/Update/Delete (Granular)
```javascript
allow create: if <condition>;
allow update: if <condition>;
allow delete: if <condition>;
```

## Firestore Security Best Practices

✅ **DO:**
- Always check `isSignedIn()` before any permission
- Use `isAdmin()` for sensitive collections
- Validate field types and values in `request.resource`
- Limit write size and content type
- Log permission changes

❌ **DON'T:**
- Allow public writes to sensitive collections
- Hardcode UIDs in rules (use `request.auth.uid`)
- Allow null/empty data
- Skip authentication checks

## Emergency Rules (Development Only)

⚠️ **NEVER USE IN PRODUCTION** ⚠️

For local development debugging:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // ⚠️ DEBUG ONLY
    }
  }
}
```

**To re-enable security:**
```bash
firebase deploy --only firestore:rules
```
Deploys the actual rules from `/firestore.rules` file.

## Support

If issues persist:
1. Check this guide's troubleshooting section
2. Review Firebase Console error messages
3. Check browser DevTools (F12) Console tab
4. Verify all admin documents are created
5. Ensure rules file is deployed to Firebase Console

## Related Files

- `firestore.rules` - Firestore security rules
- `storage.rules` - Firebase Storage rules
- `lib/core/widgets/app_shell.dart` - Admin access check UI
- `docs/firebase-setup.md` - Firebase project setup
- `docs/CONSOLE_ISSUES_AND_FIXES.md` - Additional troubleshooting

