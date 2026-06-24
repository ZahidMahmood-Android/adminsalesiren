# Sale Siren — Keys & Secrets (template)

**Do not put real secrets in this file.** Copy to `keys-and-secrets.md` (gitignored) and fill in values.

Shared reference for **admin panel**, **mobile app**, **Firebase**, **Cloud Functions**, and **hosting**.  
Team access only — never commit `keys-and-secrets.md` or paste secrets in chat/PRs.

---

## Quick links

| Area | Canonical doc |
|------|----------------|
| Firebase setup | `docs/firebase-setup.md` |
| Functions deploy | `docs/firebase-functions-deployment.md` |
| Mobile release signing | `apps/mobileapp/docs/release_management.md` |

---

## Firebase project

| Key | Value |
|-----|--------|
| Project ID | `salesiren-5539c` |
| Project number | `508084936274` |
| Console | https://console.firebase.google.com/project/salesiren-5539c |

---

## Admin panel (Flutter Web)

| Key | Env / location |
|-----|----------------|
| API key | `FIREBASE_API_KEY` / `lib/firebase_options.dart` |
| App ID | `FIREBASE_APP_ID` |
| Auth domain | `FIREBASE_AUTH_DOMAIN` |
| Storage bucket | `FIREBASE_STORAGE_BUCKET` |
| App Check reCAPTCHA **site** key | `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY` |
| App Check web provider (`v3` or `enterprise`) | `FIREBASE_APPCHECK_WEB_PROVIDER` |
| App Check debug token | `FIREBASE_APPCHECK_DEBUG_TOKEN` |

---

## reCAPTCHA (SaleSiren — App Check / web)

| Key | Value |
|-----|--------|
| Registered name | SaleSiren |
| Site key (public, HTML / dart-define) | `YOUR_RECAPTCHA_SITE_KEY` |
| Secret key (server / Firebase Console only) | `YOUR_RECAPTCHA_SECRET_KEY` |

### Allowed domains

List every production hostname (e.g. `salesiren.bytecinch.com`) on the reCAPTCHA key. Do not add `localhost` to the production key — use App Check debug tokens locally.

## Mobile app — Android

| Key | File |
|-----|------|
| Package | `com.bytecinch.salesiren` |
| `google-services.json` | `apps/mobileapp/android/app/google-services.json` |
| Release keystore | `apps/mobileapp/android/key.properties` (local, gitignored) |

---

## Mobile app — iOS

| Key | File |
|-----|------|
| Bundle ID | `com.bytecinch.salesiren` |
| `GoogleService-Info.plist` | `apps/mobileapp/ios/Runner/GoogleService-Info.plist` |
| Reversed client ID | `ios/Runner/Info.plist` URL scheme |

---

## Social sign-in (Firebase Auth)

| Provider | Notes |
|----------|--------|
| Email / password | Admin panel |
| Google | OAuth clients in `google-services.json` / `GoogleService-Info.plist` |
| Apple | iOS capability + Firebase Auth; no mobile client secret |
| Facebook | _Not configured — add App ID / secret here when enabled_ |

---

## Hosting & share links

| Key | Value |
|-----|--------|
| Share / App Links domain | `https://salesiren.bytecinch.com` |
| Cloudflare / DNS | _Add account or zone token here if used_ |

---

## Cloud Functions / CI

| Key | Notes |
|-----|--------|
| Service account JSON | _Never commit — use Firebase CLI login or CI secret store_ |
| GCP project number | `508084936274` |

---

## Dart-define bundle (admin web example)

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=508084936274 \
  --dart-define=FIREBASE_PROJECT_ID=salesiren-5539c \
  --dart-define=FIREBASE_AUTH_DOMAIN=salesiren-5539c.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=salesiren-5539c.firebasestorage.app \
  --dart-define=FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY=...
  --dart-define=FIREBASE_APPCHECK_WEB_PROVIDER=v3
```
