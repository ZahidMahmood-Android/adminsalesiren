# Firestore rules & indexes sync

Sale Siren uses **one Firebase project** for both apps. Rules and indexes must stay aligned.

## Files (must match)

| File | Canonical source |
|------|------------------|
| `apps/adminpanel/firestore.rules` | **Edit here first** |
| `apps/mobileapp/firestore.rules` | Copy from admin panel (keep mobileapp line-1–2 sync comment) |
| `apps/adminpanel/firestore.indexes.json` | **Edit here first** |
| `apps/mobileapp/firestore.indexes.json` | Copy from admin panel (must be identical JSON) |

## Workflow after any rules/index change

1. Implement the change in `apps/adminpanel/firestore.rules` (or `firestore.indexes.json`).
2. Copy to `apps/mobileapp/`:
   ```bash
   cp apps/adminpanel/firestore.indexes.json apps/mobileapp/firestore.indexes.json
   # For rules: copy body from adminpanel; preserve mobileapp sync header comments.
   ```
3. Verify: `diff -w apps/adminpanel/firestore.rules apps/mobileapp/firestore.rules` (ignore header comments).
4. Log the change:
   - **Features / schema / new collections** → `docs/updates-and-features.md`
   - **Bug fixes / permission denials** → `docs/bug-fixes.md`
5. Deploy from either app directory (same Firebase project):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## Mobile app docs

Mobile-specific UI changes are also logged in `apps/mobileapp/docs/updates-and-features.md` and `apps/mobileapp/docs/bug-fixes.md`. Shared Firestore work is logged in **this** admin panel `docs/` folder.

## 2026-06-23 profile bootstrap rule

Admin and mobile rules include `isSelf(docId)` and explicit `allow get` paths for `users/{uid}` and `admins/{uid}`. This lets the signed-in account read its own profile/admin reference before broader role checks run.

## 2026-06-24 sent notification request edits

Admin and mobile rules allow brand-scoped users to update their own `notification_requests` when status is `sent`, as long as the status remains `sent`. This supports title/body edits after delivery without reopening publish/delete flows.

## 2026-06-24 app settings

Admin and mobile rules allow public read of `app_settings` and owner/admin writes. `app_settings/mobile_ads.enabled` controls whether the mobile app should show ads when ad UI is implemented.
