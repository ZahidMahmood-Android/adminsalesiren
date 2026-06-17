# Bug Fixes

Log all bug fixes here **before** implementing. For new features use `docs/updates-and-features.md`.

---

## 2026-06-17 — Offer featured requires verified and listing status pill
**Files:** offer form/detail/list/actions as needed
**Fix:** Prevent unverified offers from being featured and align offer listing status pill style with notification request listing.

---

## 2026-06-17 — Login left panel post-animation jerk
**File:** `lib/features/auth/presentation/widgets/login_brand_panel.dart`
**Fix:** Replaced slide+audio trigger behavior with a stable fade-only text reveal to prevent the left panel from jerking after animation completes.

---

## 2026-06-17 — Login logo background removal
**File:** `lib/features/auth/presentation/widgets/login_brand_panel.dart`
**Fix:** Removed background wrapper from login logo so only the logo image appears on the login screen.

---

## 2026-06-17 — Logo green tile background and small sizing
**Files:** `lib/core/widgets/app_shell.dart`, `lib/features/auth/presentation/widgets/login_brand_panel.dart`
**Fix:** Removed green logo tile background and increased logo render size in sidebar/dashboard brand mark and login panel so the parrot icon fits better.

---

## 2026-06-17 — Notification request status selector overflow
**File:** `lib/features/notifications/presentation/screens/notification_requests_screen.dart`
**Fix:** Prevent right-side `RenderFlex` overflow by making status selector width adaptive based on how many action icons are rendered in each list row.

---

## 2026-06-17 — Notification request selector/pill/action alignment
**File:** `lib/features/notifications/presentation/screens/notification_requests_screen.dart`
**Fix:** Hide the status pill when status selector is visible, and keep view/edit/delete action icons to the right side of the selector in notification request list rows.

---

## 2026-06-17 — Published offer edit/delete lock
**Files:** offer list/detail actions and Firestore rules as needed
**Fix:** Published offers cannot be edited or deleted; they can only be expired.

---

## 2026-06-17 — Offer form dropdown assertion and expired edit lock
**Files:** offer form/detail/list widgets as needed
**Fix:** Prevent dropdown initial-value assertions from invalid/duplicate option values and block editing expired offers.

---

## 2026-06-17 — Dashboard recent offers ownership visibility
**Files:** dashboard screen/provider as needed
**Fix:** Show dashboard recent offers created by the current signed-in user only.

---

## 2026-06-17 — Notification request ownership visibility
**Files:** notification request repository/provider as needed
**Fix:** Show notification requests created by the current signed-in user only.

---

## 2026-06-17 — Profile settings routing
**Files:** app shell/profile navigation and router as needed
**Fix:** Ensure clicking Profile Settings opens the correct profile/settings page instead of redirecting to dashboard.

---

## 2026-06-17 — Offer image upload stuck and notification cleanup on delete
**Files:** offer form/actions, offer image repository, notification repository as needed
**Fix:** Prevent offer create/edit from getting stuck during image upload, and delete linked notification requests when an offer is deleted.

---

## 2026-06-17 — Offer list ownership, loaders, refresh, and delete confirmation
**Files:** offer list/detail/form/providers/widgets as needed
**Fix:** Show offers created by the current user where required, ensure save/delete actions show loading and refresh offer views, and require confirmation before deleting.

---

## 2026-06-17 — Manager CRUD permissions and city routing
**Files:** `app_router.dart`, `firestore.rules`, city/category/offer/notification screens/providers as needed
**Fix:** Ensure manager role has CRUD access for categories, cities, offers, and notification requests, and fix Add New City route redirecting to dashboard.

---

## 2026-06-17 — CRUD speed for categories, cities, and offers
**Files:** `firebase_offers_repository.dart`, `firebase_categories_repository.dart`, `firebase_cities_repository.dart`, `offer_providers.dart`, `category_providers.dart`, `city_providers.dart`
**Fix:** Reduce slow loading and action latency by keeping Firestore streams query-based, avoiding unnecessary initial empty emissions, and using server timestamps for lightweight create/update/delete writes where safe.

---

## 2026-06-17 — Slow load/save/update/delete on offers, categories, and cities
**Files:** `firebase_offers_repository.dart`, `firebase_categories_repository.dart`, `firebase_cities_repository.dart`, `offer_providers.dart`, `category_providers.dart`, `city_providers.dart`
**Fix:** Replaced full-collection snapshot reads with query-based Firestore streams (`orderBy` and role/filter-aware `where` constraints), and removed extra initial empty-stream emits in providers that caused unnecessary intermediate loading/rebuild cycles.

---

## 2026-06-17 — Offer view/edit showed persistent loading + manager city/category permissions
**Files:** `offer_form_screen.dart`, `offer_details_screen.dart`, `app_router.dart`, `firestore.rules`
**Fix:** Removed stale action-loading dependency from offer edit/view UI paths to prevent persistent loading indicators, allowed manager access to city form routes, and expanded Firestore city/category write permissions so managers can add/update/activate/delete categories and cities.

---

## 2026-06-17 — Offers list kept showing loading after create/update
**File:** `lib/features/offers/presentation/screens/offers_list_screen.dart`
**Fix:** Removed global screen loading binding to `offerActionsProvider.isLoading` on the offers list page. This avoids stale action-state causing persistent loading UI after create/update navigation.

---

## 2026-06-17 — NetworkImageLoadException for blocked favicon/logo URLs
**File:** `lib/core/widgets/app_avatar.dart`
**Fix:** Replaced `CircleAvatar(backgroundImage: NetworkImage(...))` with a guarded `Image.network` render path using `errorBuilder`, so failed logo/favicon HTTP requests gracefully fall back to initials/icon instead of throwing `NetworkImageLoadException`.

---

## 2026-06-16 — Register brand allowed submission without selecting existing brand
**File:** `register_brand_screen.dart`
**Fix:** `_submit()` now returns early with a friendly error if `_selectedBrand == null`, preventing accidental brand creation outside the dedicated "New Brand" flow.

---

## Offer usage count not decremented when unpublished offer is deleted (2026-06-16)

**Problem:** When a brand admin creates an offer, `offersCreated` usage is incremented. If they delete the offer before it is published, the count is never decremented — the quota is permanently consumed even though the offer never went live.

**Fix:**
- `OfferActionsController.delete` now fetches the offer first. If it was unpublished (`!offer.isPublished`) and created by a `brand_admin`, it calls `subscriptionsRepositoryProvider.incrementUsage(offer.brandId, offersCreated: -1)` before deleting.
- `incrementUsage` implementation now clamps counts to `>= 0` to avoid negative usage values.

## Loader not shown during CRUD operations (2026-06-16)

**Problem:** List screens disable action buttons during async work (via `actionState.isLoading`) but show no visible in-progress indicator.

**Fix:** Added optional `loading` bool to `ScreenScaffold`. When `true`, a slim `LinearProgressIndicator` appears between the header and the content. All major list/detail screens pass `loading: <actionsProvider>.isLoading`.

## Published offer could still be deleted from list and detail screens (2026-06-16)

**Problem:** `offer_tile.dart` hid the delete button only for brand admins on published offers (`!publishedBrandOffer`). Super admin still saw the delete button on published offers.  

**Fix:** Delete button now hidden for ALL roles when `offer.isPublished`. In `offer_details_screen.dart` the delete button is similarly conditional. To remove a published offer, a super admin must unpublish it first. Edit remains unrestricted.

---

## Wrong import path for `showAppError` in payment screens (2026-06-16)

**Files:** `brand_payment_form_screen.dart`, `brand_payment_verify_screen.dart`

**Error:** Both files imported `'../../../../core/errors/app_error_dialog.dart'` which does not exist. `app_error_dialog.dart` (which exports `showAppError`) lives in `core/widgets/`, not `core/errors/`.

**Fix:** Changed the import to `'../../../../core/widgets/app_error_dialog.dart'` in both files.

**Rule to avoid recurrence:** `app_error_dialog.dart` is always at `lib/core/widgets/app_error_dialog.dart`. Never place it under `core/errors/`. Any new screen that uses `showAppError` must import from `core/widgets/`.

---

## Save Offer Permission Denied — `brand_usage` GET on Non-Existent Document (2026-06-15)

**Issue:** Brand admin gets `[cloud_firestore/permission-denied]` when saving a new offer.

**Root cause:** The `allow get` rules for `brand_usage`, `brand_subscriptions`, `brand_payments`, `notification_requests`, and `subscription_requests` all check `resource.data.brandId == brandId()`. In Firestore rules, when the requested document does **not yet exist**, `resource` is `null` and `resource.data.brandId` evaluates to `null`. The check `null == brandId()` is `false`, so the rule denies the read. This is hit by `getOrCreateCurrentUsage()` in the subscription repository, which first does a `doc.get()` to check if a usage record exists for the current month. If it doesn't, the GET is denied with `permission-denied` before the offer save even begins. The error propagates unhandled through `_submit()`.

**Fix:**
1. `firestore.rules` — Add `resource == null ||` guard before every `resource.data.brandId` check in `allow get` rules, so non-existent-document reads are permitted when the brand admin owns that document namespace.
2. `offer_form_screen.dart` — Wrap `checkOfferCreationLimits` / `checkFeaturedOfferLimits` calls in try-catch so a quota-check failure (e.g. Firestore rule gap) never surfaces as a hard "save" error. Also wrap `recordOfferCreated` / `recordFeaturedUsed` in try-catch so that usage-tracking failures after a successful save don't show as errors.

---

## Save Offer Permission Fix + User-Friendly Error Messages (2026-06-15)

**Issue 1 — Save offer permission denied for brand admin:**
Root cause: Previous rule fix in `createsOwnOffer()` removed the `published+approvedBy` branch, but brand admins can legitimately save an offer directly as "Published" (via the Status dropdown). The repo sets `approvalStatus: approved` in that path, which the simplified rule then rejected.
Fix: Restored the `published` branch in `createsOwnOffer()`.

**Issue 2 — Basic SnackBar for errors:**
All form errors (validation + save failures) were shown as plain unstyled `SnackBar`. Replaced with:
- `showAppError(context, error)` → `AlertDialog` with icon, title, and OK button (for save/action failures)
- Inline `showAppError(context, null, message: '...')` → same dialog for validation failures  
- `showAppSuccess(context, message)` → styled green `SnackBar` with checkmark (for confirmations like "Seeded N plans")

Files updated: `offer_form_screen`, `brand_form_screen`, `register_brand_screen`, `category_form_screen`, `city_form_screen`, `login_screen`, `pricing_plan_form_screen`, `pricing_plans_list_screen`, `brand_subscription_form_screen`, `brand_payment_verify_screen`, `subscription_request_form_screen`.

---

## Firestore Rules Brand Admin Fixes (2026-06-15)

**Issues fixed:**
1. `offer_reports` had no `list` rule — brand admins could not list their own reports.
2. `notification_requests` create allowed `status: 'approved'` for brand admins — should only be `'pending'`.
3. `createsOwnOffer()` had a dead `published+approvedBy` branch inside a `create` rule (publishing is an `update`, not a `create`); simplified to `pending_review` only.
4. Wildcard `match /{document=**}` gave super-admin unrestricted write on any collection — tightened to `read` only for unlisted collections.

---

## Subscription Enforcement for Brand Admin (2026-06-15)

**Requirement 1:** If brand admin's trial/subscription has expired, block all feature access and show a "Pay to continue" screen.
**Requirement 2:** If monthly quota is exhausted, block the specific action and show "Upgrade or wait for next month."

**Fix applied:**
- `brand_subscription.dart`: `isUsable` now also checks `endDate` has not passed.
- `app_shell.dart`: Added `_SubscriptionGate` that wraps child for brand admins. If subscription is expired/missing, shows blocking screen; My Subscription and Upgrade routes remain accessible.
- `offer_form_screen.dart`: Replaced snackbar limit messages with `AlertDialog` showing "Upgrade plan" and "Wait for next month" options.

---

## Documentation Consolidation (2026-06-15)

- Merged scattered fix/troubleshooting markdown files into this document.
- Removed duplicate root-level `*_FIX*.md` files and old `docs/CONSOLE_ISSUES_AND_FIXES.md`, `docs/FIRESTORE_PERMISSIONS.md`, `docs/FIRESTORE_PERMISSION_FIX.md`.

---

## My Subscription Screen Keeps Loading for Brand Admin (2026-06-15)

**Symptom:** Brand admin opens My Subscription; screen stays on loading spinner forever.

**Cause:** `activeBrandSubscriptionProvider` calls `getActiveSubscriptionForBrand()` which queries `brand_subscriptions` with a `where('brandId', …)` filter. The existing Firestore rule requires the document to already exist (`resource.data.brandId`) for a `get`, but the subscription list query (`list`) was allowed. However, the `getActiveSubscriptionForBrand` does a **collection query** (not a document get), which falls under `list`. The brand admin `list` rule was correct, but the rule for `read` on individual docs checked `resource.data.brandId == brandId()` — fine. The real issue is that `activeBrandSubscriptionProvider` is a `FutureProvider` that calls the repository directly via `ref.watch(subscriptionsRepositoryProvider)`, but the provider itself reads `user.brandId` which is populated from `currentUserProvider`. If `currentUserProvider` returns null at the moment the provider first builds (profile still loading), `brandId` is empty and the query returns nothing — then the `FutureProvider` resolves to `null` and never re-runs because it doesn't watch the user.

**Root causes (two separate issues):**

1. `brand_subscriptions`, `brand_usage`, `brand_payments` rules used `allow read` with `resource.data.brandId` check. `resource.data` is only available for single-document `get` operations — not for collection-query `list` operations. Brand admin's `where('brandId', …)` query is a `list` and was blocked unconditionally.

2. `activeBrandSubscriptionProvider` used `ref.watch(currentUserProvider)` which returns `currentUserProfileProvider.value` — null if the profile future hasn't resolved yet. The provider would run immediately with an empty `brandId`, return `null` from the repository, resolve as `null`, and never re-run (FutureProvider doesn't rebuild on subsequent user changes unless it watches the profile future directly).

**Fix applied:**

- `firestore.rules`: split `allow read` into `allow get` (keeps `resource.data` check) + `allow list: if isAdminOrSuperAdmin() || isBrandAdmin()` for `brand_subscriptions`, `brand_usage`, `brand_payments`.
- `subscription_providers.dart`: changed `activeBrandSubscriptionProvider` to `await ref.watch(currentUserProfileProvider.future)` so it waits for the profile before querying.

| Area | Summary |
|------|---------|
| [Dashboard AsyncValue](#dashboard-asyncvalue-value-error) | Fixed `.value` on `AsyncValue` causing runtime crash |
| [Dashboard errors](#dashboard-metric-error-tooltips) | Added error tooltips on metric cards |
| [Firestore permissions](#firestore-permission-denied) | Admin document setup and rules deployment |
| [Storage rules](#storage-rules-database-reference) | Fixed database path syntax; added deny-all fallback |
| [Admin access slow](#admin-access-check-performance) | Stream → one-time query with 5s timeout |
| [Copy to clipboard](#copy-to-clipboard-not-working) | Real clipboard via `CopyUtils` |
| [Admin diagnostics](#admin-access-diagnostics) | Diagnostics screen for permission debugging |
| [Brand admin offers](#brand-admin-offer-permissions) | Save/update permissions for unpublished offers |
| [Offer form scoping](#offer-form-variable-scoping) | Local variable scoping after pending save change |

---

## Dashboard AsyncValue `.value` Error

**Symptom:** `NoSuchMethodError: The getter 'value' was called on null` on dashboard.

**Cause:** Dashboard used `.value` on `AsyncValue<List<City>>` and `AsyncValue<List<Category>>`.

**Fix:** Use `.when(data:, loading:, error:)` pattern in `dashboard_screen.dart`.

---

## Dashboard Metric Error Tooltips

**Symptom:** Metric cards showed `!` on error with no detail.

**Fix:** Added `errorMessage` tooltip support on `_MetricCard` so Firestore permission, network, and index errors are visible on hover.

---

## Firestore Permission Denied

**Symptom:** Login succeeds but dashboard/brands/offers show `permission-denied`.

**Cause:** Missing Firestore access documents. App requires at least one of:

- `admins/{uid}` document, and/or
- `users/{uid}` with correct `role` and `isActive: true`

**Fix steps:**

1. Copy Firebase Auth UID from app error/diagnostics screen.
2. Create `admins/{uid}`:

```json
{
  "email": "admin@example.com",
  "name": "Admin",
  "role": "owner",
  "createdAt": "serverTimestamp"
}
```

3. For role-aware flows, create `users/{uid}` with `role`, `brandId` (brand admins), `isActive: true`.
4. Deploy rules: `firebase deploy --only firestore:rules,storage`
5. Hard refresh browser (`Cmd+Shift+R` / `Ctrl+Shift+F5`).

**Common errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| `permission-denied` on read | Missing admin/user doc | Create `admins/{uid}` or `users/{uid}` |
| `permission-denied` on write | Not admin or rules not deployed | Verify doc + deploy rules |
| `permission-denied` on upload | Storage rules check `admins/{uid}` only | Ensure admin doc exists |
| Composite index required | Multi-field offer query | Click Firebase Console link in error to create index |

---

## Firestore Rules Architecture (Reference)

Role helpers in `firestore.rules`:

- `isSuperAdmin()` — `admins/{uid}` or `users/{uid}` with `role: super_admin`
- `isBrandAdmin()` — `users/{uid}` with `role: brand_admin` and valid `brandId`
- Brand admins: scoped offers, own categories, own notification requests
- Super admins: full access

| Collection | Brand admin | Super admin |
|------------|-------------|-------------|
| `cities` | Read only | Full write |
| `categories` | Own records | Full write |
| `brands` | Limited profile update | Full write |
| `offers` | Own brand | Full write |
| `notification_requests` | Own brand | Full write |

Setup details: `docs/firebase-setup.md#create-admin-document`.

**Note:** `storage.rules` still checks legacy `admins/{uid}` for image uploads. Brand admins need that document or updated storage rules for uploads.

---

## Storage Rules Database Reference

**Symptom:** Inconsistent admin check between Firestore and Storage.

**Fix:**

- Changed `firestore.exists(/databases/(default)/documents/...)` to `/databases/default/documents/...`
- Added explicit deny-all for unmatched storage paths
- Added inline comments in `storage.rules`

---

## Admin Access Check Performance

**Symptom:** 2–5+ second delay after login on "Checking admin access".

**Cause:** Real-time Firestore stream (`.snapshots()`) for admin doc check.

**Fix** in `auth_providers.dart`:

- `StreamProvider` → `FutureProvider`
- `.snapshots()` → `.get()` with 5-second timeout
- Cached result; no continuous stream overhead
- Timeout-specific error message in `app_shell.dart`

**Expected:** ~0.5–1s check instead of 2–5s.

---

## Copy to Clipboard Not Working

**Symptom:** Copy buttons showed snackbar but did not copy text.

**Fix:**

- Added `lib/core/utils/copy_utils.dart`
- Updated `app_shell.dart` copy buttons and clickable UID
- Diagnostics screen copy support

---

## Admin Access Diagnostics

**Symptom:** Hard to debug why admin document was not detected.

**Fix:** Added `admin_access_diagnostics_screen.dart`:

- Account info (email, UID with copy)
- Real-time admin access status
- Troubleshooting checklist
- Accessible via "Run Diagnostics" on admin setup screen

---

## Brand Admin Offer Permissions

**Symptom:** Brand admin could not save offer edits or image URLs on unpublished offers.

**Fix:**

- Updated Firestore rules for brand-admin create/update on own offers
- Brand-admin saves remain pending/unpublished; publish only via Notification Requests
- Fixed offer form status visibility

---

## Offer Form Variable Scoping

**Symptom:** Compile/runtime issue after pending/unpublished save change.

**Fix:** Corrected local variable scoping in `offer_form_screen.dart`.

---

## Console / Runtime Issues After Login

**Expected dashboard behavior:**

1. Metric cards with counts (role-dependent)
2. Recent offers list
3. Analytics charts where configured
4. Real-time provider streams

**If errors persist:**

1. Browser console (F12) — look for `[AdminAccessProvider]`, `permission-denied`
2. Firebase Console — verify collections and admin/user documents
3. Deploy rules and hard refresh
4. Run Diagnostics from admin setup screen

**Composite index:** When filtering offers by city/category/brand, create the index from the Firebase Console link in the error message.

---

## Quick Fix Checklist (~5 min)

1. Rebuild app if code changed: `flutter pub get`
2. Login → note UID from setup/diagnostics screen
3. Create `admins/{uid}` in Firestore (and `users/{uid}` if using roles)
4. `firebase deploy --only firestore:rules,storage`
5. Hard refresh browser
6. Run Diagnostics → expect green admin access status

---

## Emergency Rules (Development Only)

Never use in production:

```javascript
match /{document=**} {
  allow read, write: if true;
}
```

Re-deploy real rules: `firebase deploy --only firestore:rules,storage`
