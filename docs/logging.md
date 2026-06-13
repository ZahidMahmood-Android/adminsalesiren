# Logging Standard

## Overview

The admin panel uses `package:logging` through `lib/core/services/app_logger.dart`.

`setupAppLogging()` is called during app startup in `main.dart`. It configures:

- `Level.ALL` in debug builds.
- `Level.INFO` in release builds.
- Console output through Flutter `debugPrint`.
- Central logging for Flutter framework errors.
- Central logging for uncaught platform errors.

## Where To Log

Log at boundaries where the information helps debug production behavior:

- App startup and Firebase initialization.
- Auth sign-in/sign-out attempts and failures.
- Repository writes and deletes.
- Firebase Storage uploads.
- Riverpod action-controller failures.
- Important filter or workflow state changes at `fine` level.

## What Not To Log

Never log:

- Passwords.
- Auth tokens.
- API keys or full Firebase config.
- Raw image bytes.
- Large Firestore payloads.
- Unnecessary user personal data.

## Usage

```dart
final log = AppLogger.get('ClassName');

log.info('Offer created id=$offerId');
log.warning('Deleting brand id=$brandId');
log.severe('Upload failed', error, stackTrace);
```

Use stable names such as repository, provider, or controller class names. Prefer IDs and workflow labels over full object dumps.
