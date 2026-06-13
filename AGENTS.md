# Salesiren Admin Panel Agent Guide

This repository is the Flutter Web admin panel for an AI-powered sale and offer alert product for Pakistan. The MVP starts with Lahore and admin-entered verified offers. The mobile app, notifications, website, AI extraction, retailer dashboard, and monetization come later.

## Permanent Project Instructions

Follow `/Users/zahid/Data/Zahid/Work/Flutter/Projects/Personal/ByteCinch/AI/salesiren/docs/CODEX_PROJECT_INSTRUCTIONS.md` for every task in this project unless the user explicitly overrides it.

Core permanent rules:

- Complete only the exact requested task.
- Prefer the smallest safe change.
- Do not build extra features.
- Do not refactor unrelated files.
- Do not rename files, folders, classes, variables, or methods unless asked.
- Do not change architecture unless asked.
- Do not scan the whole project.
- Read only the minimum files required for the current task.
- Keep responses short.
- Do not print full files unless asked.
- Do not create documentation unless asked.
- Do not add dependencies unless required; if required, ask first.
- Do not upgrade or replace packages unless asked.

Never run these commands unless the user explicitly asks:

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
```

Also do not run, build, compile, test, deploy, install packages, or write tests unless explicitly asked.

Do not run these git commands unless explicitly asked:

```bash
git commit
git push
git pull
git merge
git rebase
git checkout
git reset
```

For successful tasks, respond in this short format:

```text
Done.

Changed:
- file/path/example.dart: short explanation

Notes:
- Any important limitation or manual next step
```

For blocked tasks, respond in this short format:

```text
Blocked.

Reason:
- Short reason

Need:
- Exact file, decision, or instruction needed
```

## Product Scope

- Build the Admin Panel first because the mobile app depends on offer data.
- MVP city is Lahore only.
- Focus on verified offers from brands, malls, supermarkets, restaurants, electronics stores, and similar retailers.
- Do not build AI chatbot, retailer dashboard, payment system, cashback, wallet, complex recommendations, multi-country support, advanced scraper, or landing website unless explicitly requested.

## Tech Stack

- Flutter Web
- Riverpod
- Clean Architecture
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging later
- Repository abstraction so Firebase can later be replaced by a REST API or .NET/PostgreSQL backend.

## Architecture Standard

Use feature-first Flutter Clean Architecture.

```text
lib/
  core/
    constants/
    errors/
    extensions/
    routing/
    services/
    theme/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      presentation/
    cities/
      data/
      domain/
      presentation/
    categories/
      data/
      domain/
      presentation/
    brands/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    offers/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    reports/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
  firebase_options.dart
  main.dart
```

## Coding Rules

- Keep Firebase calls out of widgets.
- Use repository interfaces in the domain layer.
- Keep Firebase repository implementations in the data layer.
- Keep business logic out of UI widgets.
- Use Riverpod providers for repositories, use cases, and screen state.
- Prefer `AsyncNotifier` or `Notifier` for new Riverpod state unless existing code establishes another pattern.
- Use `Notifier` for mutable filter/search state to reduce rebuild overhead; use `AsyncNotifier` for async actions (save/delete/update).
- Use loading, error, and success states for async UI.
- Use `AppLogger` for app startup, auth events, repository writes, uploads, and action-controller failures.
- Do not log passwords, tokens, secrets, full Firebase config, or unnecessary user personal data.
- Keep widgets small and named clearly.
- Add comments only where they clarify non-obvious logic.
- Do not over-engineer. Build MVP flows first.
- Keep code easy to migrate later to a REST API.
- Use thin use case classes (e.g., `CreateOffer`) that wrap repository methods; keep use case files lightweight.
- Define app-wide constants (cities, default values, endpoints) in `core/constants/app_constants.dart`.

## Admin Panel MVP

Build these first:

- Firebase initialization
- Firebase Auth admin login
- Firestore models/entities for City, Category, Brand, and Offer
- Repository interfaces in domain layer
- Firebase repository implementations in data layer
- Riverpod providers
- Basic dashboard layout
- Brands CRUD
- Offers CRUD
- Firebase Storage image upload for offer images
- Firestore security rules draft for admin-only writes

## Implementation Patterns

### Firebase and Repositories

- Firebase service instances are provided via single-purpose providers in `core/services/firebase_providers.dart`: `firebaseAuthProvider`, `firestoreProvider`, `firebaseStorageProvider`.
- Repository interfaces are defined in `features/{feature}/domain/repositories/`.
- Firebase implementations are in `features/{feature}/data/repositories/` (e.g., `FirebaseBrandsRepository`, `FirebaseOffersRepository`).
- Repository providers instantiate Firebase repositories, e.g., `final offersRepositoryProvider = Provider<OffersRepository>((ref) => FirebaseOffersRepository(ref.watch(firestoreProvider)));`

### State Management and Providers

- **Data streams**: Use `StreamProvider.autoDispose` for watched collections (e.g., brands, offers, cities).
- **Mutable UI state** (filters, search): Use `NotifierProvider` for filter controllers to avoid excessive rebuilds. Example: `offerFiltersProvider` manages `OfferFilters` state with `update()` and `clear()` methods.
- **Async actions** (create/update/delete): Use `AsyncNotifierProvider.autoDispose` with an action controller that wraps repository calls and logs successes/failures (e.g., `OfferActionsController`, `BrandActionsController`).
- **Use cases**: Keep thin. A use case wraps one repository method, e.g., `CreateOffer` calls `repository.createOffer()`. Define them in `features/{feature}/domain/usecases/`.

### Image Upload Workflow

- Offer image upload uses `FirebaseOfferImageRepository` with path pattern `offers/{offerId}/{timestamp}_{filename}`.
- Upload happens after offer creation:
  1. Pick image via `image_picker`.
  2. Call `offerImageRepositoryProvider.uploadOfferImage()` with offerId, fileName, bytes, and contentType.
  3. Receive download URL.
  4. Update offer with image URL via `saveChanges()` use case.
- See `offer_form_screen.dart` for complete workflow.

### Offer Status and Filter Management

- Offers have `isPublished`, `isVerified`, and `isFeatured` flags.
- Status changes use repository methods: `publishOffer()`, `verifyOffer()`, `featureOffer()`.
- Offer filters use `OfferFilters` entity with optional fields; `copyWith()` supports selective clearing.
- Filters are watched via `offerFiltersProvider` (Notifier) and queries are built dynamically in `FirebaseOffersRepository.watchOffers()`.

### Constants and Defaults

- App-wide constants are in `core/constants/app_constants.dart`: `defaultCityId = 'lahore'`, `supportEmail`, etc.
- Use these for seeding defaults or fallback values.

### Logging

- Use named loggers: `AppLogger.get('ClassName')`.
- Log repository mutations, auth events, uploads, and action-controller errors.
- Logs include timestamps, level, logger name, message, and optional error/stack trace.
- See `AppLogger` in `core/services/app_logger.dart` and `setupAppLogging()` in `main.dart`.

## UI Standard

- Clean, professional admin dashboard.
- Desktop web layout should use a left sidebar.
- Top bar should show logged-in admin email and a logout action.
- Forms must use validation.
- Use responsive layout where reasonable.
- Avoid marketing-style landing pages for this app.
- Do not use visible instructional text for obvious controls.
- Use shared widgets from `core/widgets/`: `AppCard`, `AppBadge`, `AppShell`, `AppLoadingView`, `AppErrorView`, `EmptyState` for consistent styling.
- Forms should use `TextFormField` with validation and `FormState.validate()` before submit.
- Async screens use standard `when(data: ..., loading: ..., error: ...)` pattern with `AppLoadingView/AppErrorView` helpers.

## Firestore Collections

- `cities`
- `categories`
- `brands`
- `offers`
- `offer_reports`
- `notification_campaigns`
- `users`

## Key Files and Patterns

| File | Purpose |
|------|---------|
| `lib/main.dart` | Firebase init, logging setup, error handlers, root ProviderScope |
| `lib/firebase_options.dart` | Firebase config (generated by FlutterFire CLI; placeholder values) |
| `lib/core/routing/app_router.dart` | GoRouter with auth guards, named routes, shell navigation |
| `lib/core/services/app_logger.dart` | Logging setup and named logger factory |
| `lib/core/services/firebase_providers.dart` | Firebase service instance providers |
| `lib/core/theme/app_theme.dart` | Material 3 theme, colors (green primary, coral/saffron accents) |
| `lib/core/widgets/app_shell.dart` | Responsive layout shell (sidebar + top bar) |
| `lib/core/constants/app_constants.dart` | App-wide constants (defaultCityId, supportEmail, etc.) |
| `lib/features/{feature}/domain/entities/*.dart` | Immutable data classes (no business logic) |
| `lib/features/{feature}/domain/repositories/*.dart` | Abstract repository interfaces |
| `lib/features/{feature}/domain/usecases/*.dart` | Thin use case wrappers around repository methods |
| `lib/features/{feature}/data/repositories/firebase_*.dart` | Firebase implementations of repositories |
| `lib/features/{feature}/data/models/*.dart` | JSON serialization and `fromSnapshot()` constructors |
| `lib/features/{feature}/presentation/providers/*.dart` | Riverpod providers (repository, stream, action controller) |
| `lib/features/{feature}/presentation/screens/*.dart` | Feature screens; watch providers and dispatch actions |
| `lib/features/{feature}/presentation/widgets/*.dart` | Reusable feature-specific widgets |

When adding a new feature:
1. Define the domain entity in `domain/entities/`.
2. Define the repository interface in `domain/repositories/`.
3. Create the Firebase repository in `data/repositories/` and the model in `data/models/`.
4. Create providers in `presentation/providers/` (repository, stream/future, action controller).
5. Create screens in `presentation/screens/` that consume providers.
6. Add routes to `app_router.dart`.

## Offer Form Validation

- Title required.
- Brand required.
- Category required.
- City required.
- Discount text required.
- Start date required.
- End date required.
- End date must be after start date.
- Image optional but supported.
- Source URL optional.
- Online URL optional.
- Published defaults to false.
- Verified defaults to false.

## Development Discipline

- Read existing code before editing.
- Follow established file organization and naming once code exists.
- Keep changes tightly scoped to the requested feature.
- Run `dart format` after Dart edits.
- Run `dart analyze` when meaningful after implementation.
- Run `flutter test` to validate domain logic and filters.
- Do not revert user changes.
- Do not introduce unrelated refactors.
- Prefer small, reviewable commits or task batches.
- Use `flutter run -d chrome` to test locally; `flutter run -d web-server` for development with hot reload.
- After implementation, verify Firebase connectivity, logging output, and Firestore/Storage operations via the web inspector console.
