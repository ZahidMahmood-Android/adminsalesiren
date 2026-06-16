# Salesiren Admin Panel

Flutter Web admin panel for managing verified sale and offer data for the Salesiren MVP.

## Built So Far

- Firebase Auth, Firestore, Storage with role-aware access (super admin, brand admin)
- Cities, categories, brands, offers CRUD; users list; master-data seed settings
- Brand registration, notification-request publish flow, dashboard analytics
- Offer reports, image upload, app-wide logging, security rules

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

Configure Firebase per `docs/firebase-setup.md` before connecting to a real project.

## Documentation

| File | Purpose |
|------|---------|
| [`instructions.md`](./instructions.md) | **Agent and developer rules** — read before every task |
| [`docs/updates-and-features.md`](./docs/updates-and-features.md) | New features and enhancements log |
| [`docs/bug-fixes.md`](./docs/bug-fixes.md) | Bug fixes and troubleshooting |
| [`docs/firestore-schema.md`](./docs/firestore-schema.md) | Firestore collection schema |
| [`docs/firebase-setup.md`](./docs/firebase-setup.md) | Firebase setup and admin document |
| [`docs/logging.md`](./docs/logging.md) | Logging standard |
| [`docs/BUILD_AND_RUN.md`](./docs/BUILD_AND_RUN.md) | VS Code tasks and build/run |
| [`AGENTS.md`](./AGENTS.md) | Short pointer for Cursor/agent tooling |
