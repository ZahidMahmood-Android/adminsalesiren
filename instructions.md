# Salesiren Admin Panel — Instructions

Read and follow this file for **every task** unless the user explicitly overrides it.

This repository is the Flutter Web admin panel for an AI-powered sale and offer alert product for Pakistan. MVP starts with Lahore and admin-entered verified offers.

---

## 1. Task Workflow

Before making code changes:

1. Read only the minimum files required for the task.
2. Write the planned change summary first:
   - **New features / updates** → `docs/updates-and-features.md`
   - **Bug fixes only** → `docs/bug-fixes.md`
3. Update **all related docs** for the change (see section 15) — not only the changelog.
4. Make the smallest safe code change.
5. Run `dart format` after Dart edits.
6. Respond using the response format in section 2.

Do **not** create other markdown files unless the user asks.

---

## 2. Response Format

For successful tasks:

```text
Done.

Changed:
- file/path/example.dart: short explanation

Notes:
- Any important limitation or manual next step
```

For blocked tasks:

```text
Blocked.

Reason:
- Short reason

Need:
- Exact file, decision, or instruction needed
```

Keep responses short. Do not explain basic Flutter, Firebase, Riverpod, or Clean Architecture unless asked.

---

## 3. Core Behaviour Rules

- Complete only the exact requested task.
- Prefer the smallest safe change.
- Do not build extra features.
- Do not refactor unrelated files.
- Do not rename files, folders, classes, variables, or methods unless asked.
- Do not change architecture unless asked.
- Do not scan the whole project.
- Do not print full files unless asked.
- Do not add dependencies unless required; if required, ask first.
- Do not upgrade or replace packages unless asked.
- Do not revert user changes.
- Do not add TODOs unless asked.

---

## 4. Commands — Do Not Run Unless Asked

```bash
flutter run
flutter build
flutter test
dart test
dart analyze
pod install
gradle build
./gradlew build
xcodebuild
npm run build
firebase deploy
git commit
git push
git pull
git merge
git rebase
git checkout
git reset
```

Also do not run, build, compile, test, deploy, install packages, or write tests unless explicitly asked.

---

## 5. File Reading Rules

Read only files required for the current task. Do not open unless directly required:

```text
build/
.dart_tool/
.gradle/
ios/Pods/
android/.gradle/
.idea/
.vscode/
coverage/
```

Do not inspect lock files unless dependency resolution is the task.

---

## 6. Product Scope

**Build first:** Admin Panel → Firebase data → Mobile App → Notifications → Website → AI → Retailer dashboard → Monetization.

**MVP focus:**

- Lahore only.
- Verified offers from brands, malls, supermarkets, restaurants, electronics stores, and similar retailers.

**Do not build unless asked:**

- Mobile app screens
- AI chatbot
- Retailer dashboard
- Payment system, cashback, wallet
- Complex recommendations
- Multi-country support
- Advanced scraper
- Landing website

---

## 7. Tech Stack

- Flutter Web
- Riverpod
- Clean Architecture (feature-first)
- Firebase Auth, Cloud Firestore, Firebase Storage
- Firebase Cloud Messaging later
- Repository abstraction for future REST / .NET / PostgreSQL migration

---

## 8. Architecture

```text
lib/
  core/
    constants/ errors/ extensions/ routing/ services/ theme/ utils/ widgets/
  features/
    {feature}/
      data/ datasources/ models/ repositories/
      domain/ entities/ repositories/ usecases/
      presentation/ providers/ screens/ widgets/
  firebase_options.dart
  main.dart
```

**Layer rules:**

- Domain must not depend on Firebase or Flutter UI.
- Presentation must not call Firebase directly.
- Repository interface in domain; Firebase implementation in data.
- Providers in presentation layer.

**When adding a feature:**

1. Entity in `domain/entities/`
2. Repository interface in `domain/repositories/`
3. Firebase repository + model in `data/`
4. Providers in `presentation/providers/`
5. Screens in `presentation/screens/`
6. Routes in `app_router.dart`

---

## 9. Coding Rules

- Keep Firebase calls out of widgets.
- Keep business logic out of UI widgets.
- Use Riverpod for repositories, use cases, and screen state.
- Prefer `AsyncNotifier` or `Notifier` for new state unless existing code uses another pattern.
- Use `Notifier` for filters/search; `AsyncNotifier` for save/delete/update actions.
- Use loading, error, and success states for async UI.
- Use thin use case classes wrapping one repository method.
- Define app-wide constants in `core/constants/app_constants.dart`.
- Use `AppLogger.get('ClassName')` for startup, auth, repository writes, uploads, and action failures.
- Never log passwords, tokens, secrets, full Firebase config, or unnecessary personal data.

---

## 10. Implementation Patterns

### Firebase providers

`core/services/firebase_providers.dart`: `firebaseAuthProvider`, `firestoreProvider`, `firebaseStorageProvider`.

### State management

- **Streams:** `StreamProvider.autoDispose` for watched collections.
- **Filters:** `NotifierProvider` (e.g. `offerFiltersProvider`).
- **Actions:** `AsyncNotifierProvider.autoDispose` with action controllers.

### Image upload

Path: `offers/{offerId}/{timestamp}_{filename}`. Pick image → upload → update offer with URL. See `offer_form_screen.dart`.

### Offer flags

`isPublished`, `isVerified`, `isFeatured`. Status via `publishOffer()`, `verifyOffer()`, `featureOffer()`.

---

## 11. UI Standard

- Desktop web: left sidebar + top bar with email and logout.
- Use shared widgets: `AppCard`, `AppBadge`, `AppShell`, `AppLoadingView`, `AppErrorView`, `EmptyState`.
- Forms: `TextFormField` + `FormState.validate()` before submit.
- Async UI: `.when(data:, loading:, error:)` pattern.
- Clean admin dashboard; no marketing hero layout.
- Material 3 theme; green primary, coral/saffron accents.

---

## 12. Firestore Collections

- `admins`, `users`, `cities`, `categories`, `brands`, `offers`
- `offer_reports`, `notification_requests`, `notification_campaigns`
- `pricing_plans`, `brand_subscriptions`, `brand_usage`, `brand_payments`, `subscription_requests`

Schema: `docs/firestore-schema.md`. Setup: `docs/firebase-setup.md`.

---

## 13. Offer Form Validation

- Title, brand, category, city, discount text, start date, end date required.
- End date must be after start date.
- Image, source URL, online URL optional.
- Published and verified default to false.

---

## 14. Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Firebase init, logging, ProviderScope |
| `lib/core/routing/app_router.dart` | GoRouter, auth guards, shell nav |
| `lib/core/services/app_logger.dart` | Logging setup |
| `lib/core/services/firebase_providers.dart` | Firebase instances |
| `lib/core/widgets/app_shell.dart` | Sidebar + top bar shell |
| `lib/core/constants/app_constants.dart` | App-wide constants |
| `firestore.rules` / `storage.rules` | Security rules |

Logging details: `docs/logging.md`. Build/run: `docs/BUILD_AND_RUN.md`.

---

## 15. Change Documents

Always log the change **before** implementing. Also update every **related** doc below when the task touches that area — do not stop at the changelog alone.

| Document | Use for | Update when you change… |
|----------|---------|-------------------------|
| `docs/updates-and-features.md` | New features, enhancements, refactors requested as features | Any non-bug product or engineering work |
| `docs/bug-fixes.md` | Bug fixes, permission errors, runtime/console issues | Any defect fix |
| `docs/firestore-schema.md` | Collection/field shapes, subcollections, data conventions | Firestore models, new fields, grouped/nested data |
| `docs/firestore-rules-sync.md` | Rules/indexes sync between admin panel and mobile app | `firestore.rules`, `firestore.indexes.json` |
| `docs/firebase-functions-deployment.md` | Cloud Functions triggers, deploy steps, push/matching behavior | `functions/`, offer push, notification dispatch |
| `docs/firebase-setup.md` | Project setup, env, initial Firebase config | Setup steps, project IDs, console configuration |
| `docs/keys-and-secrets.template.md` | Secret key **structure** (tracked; no real secrets) | New keys, env vars, OAuth, reCAPTCHA |
| `docs/keys-and-secrets.md` | **Local only** (gitignored) — real keys & secrets | Copy from template; never commit |
| `docs/logging.md` | Logging conventions | Logger setup or log-level policy |
| `docs/BUILD_AND_RUN.md` | Local build/run commands | Build flags, run targets, platform setup |

**Checklist (apply what fits):**

1. Changelog first (`updates-and-features.md` or `bug-fixes.md`).
2. Schema doc if Firestore read/write shape changed.
3. Rules sync doc + copy rules/indexes to `apps/mobileapp` if security or indexes changed.
4. Functions deployment doc if Cloud Functions behavior or deploy commands changed.
5. Cross-link between changelog entry and detailed docs (e.g. “Schema: `docs/firestore-schema.md`”).
6. New keys or secrets → copy `docs/keys-and-secrets.template.md` to `docs/keys-and-secrets.md` (gitignored) and update both; never commit real secrets to tracked files.

Do **not** create other markdown files unless the user asks.

---

## 16. Error Fixing Rules

- Fix only the reported error.
- Do not refactor the full file.
- Choose the smallest safe fix.
- Log the fix in `docs/bug-fixes.md` before coding.

---

## 17. Final Rule

```text
Do the exact task only.
Use minimum context.
Make minimum changes.
Do not run/build/test/deploy unless asked.
Stop after the requested task is complete.
```
