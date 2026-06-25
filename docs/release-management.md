# Admin Panel — Release Management

Log every **production web release** here **before** running `flutter build web --release`.

The VS Code task **Flutter: Build Web Release** and `tool/build_web_release.sh` refuse to build until today's section exists in this file.

---

## Release checklist

1. Add a `## YYYY-MM-DD` section below (summary, version, deploy target).
2. Run `flutter analyze` — no warnings.
3. Build: `./tool/build_web_release.sh` or VS Code **Flutter: Build Web Release**.
4. Deploy `build/web/` only (never commit `build/`).
5. Verify hosting (Firebase / Cloudflare) and App Check after deploy.

**Do not commit:** `build/`, `docs/keys-and-secrets.md`, `.env`, `functions/node_modules/`, Firebase debug logs, local IDE caches.

---

## 2026-06-24

| Field | Value |
|-------|--------|
| Version | `1.0.0+1` (from `pubspec.yaml`) |
| Target | `https://salesiren.bytecinch.com` |
| Summary | Hygiene pass: unused imports removed, deprecated APIs replaced, feature-based nav, bug report submit for all admin users. |
| Deploy notes | Redeploy Cloud Functions if registration email verification changed; refresh Firestore rules if not yet deployed. |
