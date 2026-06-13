# Fix: Missing or Insufficient Permission in Firestore

## The Problem

You're seeing: **"Missing or insufficient permission cloud_firestore"**

This means the Firestore security rules are blocking an operation you tried to perform.

## The Cause (99% of the time)

You logged in successfully with Firebase Auth, **BUT** you haven't created the admin document yet.

The app requires an `admins/{uid}` document to exist in Firestore to grant you admin permissions.

## Solution (Follow These Exact Steps)

### Step 1: Get Your User ID from Firebase Console

1. Go to **[Firebase Console](https://console.firebase.google.com/)**
2. Select your **Salesiren** project
3. Go to **Authentication** (left sidebar)
4. Find your user in the list
5. Click on it to open details
6. Copy the **UID** value (looks like: `abc123xyz...`)

### Step 2: Create the Admin Document in Firestore

1. Go to **Firestore Database** (left sidebar)
2. Click **Create collection**
3. Type **`admins`** as collection name
4. Click **Next**
5. Document ID: **Paste your UID** (from Step 1)
6. Click **Create document**
7. Add field:
   - Field name: **`email`**
   - Type: **string**
   - Value: **Your email address**
8. Click **Add field** again:
   - Field name: **`role`**
   - Type: **string**
   - Value: **`owner`**
9. Click **Save**

### Step 3: Refresh the App

1. Go back to the admin panel in your browser
2. Press **F5** to refresh
3. The error should be gone! ✅

---

## If It Still Doesn't Work

### Check 1: Did The Admin Document Actually Save?

```
Firebase Console
→ Firestore Database
→ Collections
→ Click "admins"
→ Should see your UID as a document
```

If it's not there, repeat **Step 2** above.

### Check 2: Deploy the Rules

The security rules need to be deployed to Firebase:

```bash
firebase deploy --only firestore:rules,storage
```

If you can't run this command, go to Firebase Console and manually copy the rules:

1. **[Get the rules from GitHub](./firestore.rules)**
2. Firebase Console → Firestore → **Rules** tab
3. Click **Edit rules**
4. Paste the content
5. Click **Publish**

### Check 3: Check Your UID Matches

Make sure the document ID in Firestore exactly matches your UID:

```
Firebase Console
→ Authentication
→ Your user
→ Copy UID exactly
→ Firestore
→ admins collection
→ Document ID should be exactly the same
```

### Check 4: Browser Cache

Clear your browser's cache:
- **Chrome**: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
- Select "All time"
- Click "Clear data"
- Refresh the admin panel

---

## Error Messages and Their Meanings

| Error | Cause | Fix |
|-------|-------|-----|
| "permission-denied" | Admin document missing | Create `admins/{uid}` document |
| "permission-denied" on reports | Not admin when reading reports | Create admin document |
| "permission-denied" on brand save | Not admin when writing brands | Create admin document |
| "permission-denied" on image upload | Not admin when uploading to storage | Update `storage.rules` in Firebase |

---

## Visual Indicators in the App

After following the steps above:

✅ **You'll see:**
- Dashboard loads without errors
- Metric cards show actual numbers (not "!")
- Brands list has data
- Can create new offers

❌ **You might see:**
- Red "!" on metric cards
- "⚠️ Hover for details" message
- Error tooltip on hover
- This means hover over the card to see details

If you see red "!" on the "Pending reports" card, look at the details tooltip - it will show what's wrong.

---

## Why This Happens

The app uses **role-based access control**:

```javascript
// Security rule pseudocode
function isAdmin() {
  return user_is_signed_in 
    AND admins/{uid} document exists
}
```

So:
1. ✅ You sign in with Firebase Auth
2. ❌ But no `admins/{uid}` document exists
3. ❌ So Firestore blocks your reads/writes
4. ✅ Once you create `admins/{uid}`, rules grant admin access

---

## Need Help?

If none of these steps work:

1. Check browser console for detailed error (Press **F12**)
2. Check Firebase Console for any alerts or warnings
3. Try the alternative rule deployment method (see Check 2 above)
4. Verify all steps were followed exactly

---

## Quick Reference

**What to create:**

```json
Collection: admins
Document ID: [your-uid-from-firebase-auth]
Fields:
  - email (string): your-email@example.com
  - role (string): owner
```

**That's it!** The admin panel will immediately grant you access.

