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

**All keys (including reCAPTCHA, OAuth, signing):** local team copy `docs/keys-and-secrets.md` (gitignored). Structure: `docs/keys-and-secrets.template.md`.

```bash
--dart-define=FIREBASE_API_KEY=AIzaSyB2DMgu7ysAVNtVXzNoYx8RM3fahaXU2I0
--dart-define=FIREBASE_APP_ID=1:508084936274:web:09afbbe5f09874ea22498b
--dart-define=FIREBASE_MESSAGING_SENDER_ID=508084936274
--dart-define=FIREBASE_PROJECT_ID=salesiren-5539c
--dart-define=FIREBASE_AUTH_DOMAIN=salesiren-5539c.firebaseapp.com
--dart-define=FIREBASE_STORAGE_BUCKET=salesiren-5539c.firebasestorage.app
```

`measurementId` is only needed after Firebase Analytics is added to the Flutter app.

## Firebase App Check

The admin panel activates Firebase App Check during bootstrap.

For local debug builds, Firebase uses debug providers. Copy the debug token printed in the console and register it in Firebase Console → App Check → app → Manage debug tokens. You can also pass a fixed debug token:

```bash
--dart-define=FIREBASE_APPCHECK_DEBUG_TOKEN=your-debug-token
```

For Flutter Web release builds (including Cloudflare), bootstrap uses a reCAPTCHA provider with the SaleSiren site key baked in as a default. Override at build time if needed:

```bash
--dart-define=FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY=your-recaptcha-site-key
--dart-define=FIREBASE_APPCHECK_WEB_PROVIDER=v3
```

`FIREBASE_APPCHECK_WEB_PROVIDER` must match Firebase Console → App Check → Web app:

| Firebase App Check provider | `FIREBASE_APPCHECK_WEB_PROVIDER` | Flutter class |
|-----------------------------|----------------------------------|---------------|
| reCAPTCHA v3 | `v3` (default) | `ReCaptchaV3Provider` |
| reCAPTCHA Enterprise | `enterprise` | `ReCaptchaEnterpriseProvider` |

**Source of truth for the site key:** Firebase Console → App Check → Apps → Web (`1:508084936274:web:09afbbe5f09874ea22498b`) → copy the site key shown there. It must match the key passed to the client. The SaleSiren key in `docs/keys-and-secrets.md` is only valid if that is the same key registered in App Check.

Registered **SaleSiren** reCAPTCHA site key for App Check is stored in `docs/keys-and-secrets.md` (local, gitignored). Do not use `WebReCaptchaProvider` unless ReCAPTCHA Enterprise is configured in the Firebase Console.

### Cloudflare / custom domain

If the admin panel is served from a custom domain (e.g. `salesiren.bytecinch.com`), that hostname **must** be added to the SaleSiren reCAPTCHA key’s allowed domains:

1. Open [Google reCAPTCHA admin](https://www.google.com/recaptcha/admin) → **SaleSiren** key.
2. Under **Domains**, add each production host (e.g. `salesiren.bytecinch.com`) — no `https://` or trailing slash.
3. Save, wait ~1 minute, hard-refresh the admin panel.

In **Firebase Console → App Check → Web app**, confirm the provider secret matches the SaleSiren secret in `docs/keys-and-secrets.md`.

### Troubleshooting `appCheck/recaptcha-error` and `api2/clr` 400

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `recaptcha-error` / `api2/clr` 400 on Cloudflare | Custom domain not on reCAPTCHA key | Add exact browser host (e.g. `salesiren.bytecinch.com`) in reCAPTCHA admin |
| `api2/clr` 400 with correct domain | v2 checkbox key used as v3 | In reCAPTCHA admin, key must be **score-based (v3)** — not challenge/checkbox |
| `api2/clr` 400 after domain fix | Provider mismatch (v3 client, Enterprise in Firebase) | Rebuild with `--dart-define=FIREBASE_APPCHECK_WEB_PROVIDER=enterprise` |
| `no-provider` on web release | Missing site key at build time | Pass `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY` or use embedded default in `lib/main.dart` |
| Works on Firebase Hosting, fails on Cloudflare | Only `*.web.app` domains listed | Add the Cloudflare hostname |
| Works locally in debug, fails in release | Debug provider vs reCAPTCHA | Register debug token for debug; use domain list + release provider for production |

**Verify checklist**

1. Open the admin panel URL and note the exact hostname in the address bar.
2. [reCAPTCHA admin](https://www.google.com/recaptcha/admin) → SaleSiren → confirm **reCAPTCHA v3** (score) and hostname listed.
3. [Firebase Console → App Check](https://console.firebase.google.com/project/salesiren-5539c/appcheck) → Web app → note provider type (v3 vs Enterprise) and site key.
4. Rebuild with matching `--dart-define=FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY=...` and `--dart-define=FIREBASE_APPCHECK_WEB_PROVIDER=v3|enterprise`.
5. Redeploy to Cloudflare.

If the SaleSiren key is v2 or still fails, register a **new** score-based key through Firebase App Check and update both Firebase provider config and the client dart-define.

If Cloudflare **Bot Fight Mode** or strict security rules block `google.com` / `gstatic.com`, allow reCAPTCHA scripts for the admin hostname.

Android release builds use Play Integrity. Apple release builds use App Attest with DeviceCheck fallback.

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

The current draft allows public reads for active catalog data and role-based writes through `admins/{uid}` and `users/{uid}` profiles. See `firestore.rules` and `docs/bug-fixes.md`.

## Create Admin Document

After creating the first Firebase Auth user, add an admin marker document:

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

For role-aware flows, also create `users/{uid}` with `role`, `brandId` (for brand admins), and `isActive`.

## Dashboard Permission Troubleshooting

If login succeeds but the dashboard shows permission errors in Android Studio or Chrome DevTools:

1. Complete the [Create Admin Document](#create-admin-document) steps above.
2. Deploy the local `firestore.rules` file if the Firebase Console rules are different.
3. Refresh the admin panel.

Without `admins/{uid}` and/or a valid `users/{uid}` profile, the app will allow Firebase Auth login but block dashboard data that requires admin access.

## Cloud Functions

Offer publish FCM push runs in Cloud Functions (Gen 2). See **[firebase-functions-deployment.md](./firebase-functions-deployment.md)** for deploy steps, IAM setup, and the build service account fix for `salesiren-5539c`.
