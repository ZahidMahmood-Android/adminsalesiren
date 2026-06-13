# Salesiren Admin Panel

Flutter Web admin panel for managing verified sale and offer data for the Salesiren MVP.

## Built So Far

- Firebase initialization
- Firebase Auth admin login
- Clean Architecture feature folders
- Riverpod repository and screen state providers
- Premium Material 3 admin theme
- Dashboard shell with sidebar and top bar
- Brands CRUD
- Offers CRUD
- Firebase Storage offer image upload
- Offer report review and status update
- App-wide logging for startup, auth, repository writes, uploads, and action failures
- Firestore and Storage rules drafts

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

Before using real Firebase services, configure Firebase with FlutterFire or pass the required `--dart-define` values documented in `docs/firebase-setup.md`.

## Documentation

- `AGENTS.md`: product and engineering standards for future work.
- `docs/admin-panel-mvp-plan.md`: original MVP implementation plan.
- `docs/implementation-log.md`: what was generated and why.
- `docs/firebase-setup.md`: Firebase setup, seed data, and rule deployment.
- `docs/firestore-schema.md`: Firestore collection schema.
- `docs/logging.md`: Logging standard and safe logging rules.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
