# Firebase Setup

## Project Setup

1. Create a Firebase project named `salesiren` or `salesiren-dev`.
2. Add a Web app in Firebase project settings.
3. Enable Firebase Auth email/password provider.
4. Create Cloud Firestore in production mode.
5. Create Firebase Storage.
6. Create the first admin in Firebase Auth.
7. Create `admins/{uid}` in Firestore for that admin user.

Example admin document:

```json
{
  "email": "admin@salesiren.pk",
  "name": "Salesiren Admin",
  "role": "owner",
  "createdAt": "serverTimestamp"
}
```

## Firebase Web App Config

Firebase Console web configuration for this project:

```js
const firebaseConfig = {
  apiKey: "AIzaSyB2DMgu7ysAVNtVXzNoYx8RM3fahaXU2I0",
  authDomain: "salesiren-5539c.firebaseapp.com",
  projectId: "salesiren-5539c",
  storageBucket: "salesiren-5539c.firebasestorage.app",
  messagingSenderId: "508084936274",
  appId: "1:508084936274:web:09afbbe5f09874ea22498b",
  measurementId: "G-LLKZP2X7L1"
};
```

For Flutter Web, these values map to `FirebaseOptions` in `lib/firebase_options.dart`. This admin panel currently reads them through `--dart-define` values or a generated FlutterFire config.

```bash
--dart-define=FIREBASE_API_KEY=AIzaSyB2DMgu7ysAVNtVXzNoYx8RM3fahaXU2I0
--dart-define=FIREBASE_APP_ID=1:508084936274:web:09afbbe5f09874ea22498b
--dart-define=FIREBASE_MESSAGING_SENDER_ID=508084936274
--dart-define=FIREBASE_PROJECT_ID=salesiren-5539c
--dart-define=FIREBASE_AUTH_DOMAIN=salesiren-5539c.firebaseapp.com
--dart-define=FIREBASE_STORAGE_BUCKET=salesiren-5539c.firebasestorage.app
```

`measurementId` is only needed after Firebase Analytics is added to the Flutter app.

## FlutterFire

Preferred setup:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This should generate real Firebase options for `lib/firebase_options.dart`.

Temporary setup with dart defines:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

## Initial Seed Data

Create `cities/lahore`:

```json
{
  "id": "lahore",
  "name": "Lahore",
  "country": "Pakistan",
  "isActive": true,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Create starter categories:

```json
[
  {
    "id": "clothing",
    "name": "Clothing",
    "iconName": "checkroom",
    "isActive": true,
    "sortOrder": 1
  },
  {
    "id": "grocery",
    "name": "Grocery",
    "iconName": "shopping_cart",
    "isActive": true,
    "sortOrder": 2
  },
  {
    "id": "restaurants",
    "name": "Restaurants",
    "iconName": "restaurant",
    "isActive": true,
    "sortOrder": 3
  },
  {
    "id": "electronics",
    "name": "Electronics",
    "iconName": "devices",
    "isActive": true,
    "sortOrder": 4
  }
]
```

Add `createdAt` and `updatedAt` timestamps to each category document.

## Rules

Review and deploy:

```bash
firebase deploy --only firestore:rules,storage
```

The current draft allows public reads for active catalog data and admin-only writes through the `admins/{uid}` document check.

## Dashboard Permission Troubleshooting

If login succeeds but the dashboard shows permission errors in Android Studio or Chrome DevTools, check these first:

1. Copy the signed-in user's Firebase Auth `uid`.
2. Create a Firestore document at `admins/{uid}`.
3. Add at least these fields:

```json
{
  "email": "admin@salesiren.pk",
  "name": "Salesiren Admin",
  "role": "owner",
  "createdAt": "serverTimestamp"
}
```

4. Deploy the local `firestore.rules` file if the Firebase Console rules are different.
5. Refresh the admin panel.

Without `admins/{uid}`, the app will allow Firebase Auth login but block dashboard data that requires admin access.
