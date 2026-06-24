# Bug Fixes

Log all bug fixes here **before** implementing. For new features use `docs/updates-and-features.md`.

**Firestore rules:** fix in `apps/adminpanel/firestore.rules` first, then sync to `apps/mobileapp` — see `docs/firestore-rules-sync.md`.

---

## 2026-06-24 — reCAPTCHA `api2/clr` 400 on Cloudflare

**Symptom:** Browser logged `POST https://www.google.com/recaptcha/api2/clr?k=6LeGTS8t… 400 (Bad Request)` and App Check still failed with `appCheck/recaptcha-error`.

**Cause:** Client provider/key must match how the web app is registered in Firebase App Check. A classic v3 site key with the wrong provider, a v2 (checkbox) key, an unlisted Cloudflare hostname, or a site key that does not match the Firebase App Check registration all make Google reject reCAPTCHA before token exchange.

**Fix:** Support `FIREBASE_APPCHECK_WEB_PROVIDER` (`v3` or `enterprise`) in bootstrap. Document verifying key type (score-based v3), allowed domains, and copying the site key from Firebase Console → App Check → Web app.

---

## 2026-06-24 — App Check `appCheck/recaptcha-error` on Cloudflare

**Symptom:** After fixing `no-provider`, Auth logged `AppCheck: ReCAPTCHA error` (`appCheck/recaptcha-error`) when fetching App Check tokens on `salesiren.bytecinch.com`.

**Cause:** The SaleSiren reCAPTCHA v3 site key is valid, but the Cloudflare custom domain was not listed in the key’s allowed domains. reCAPTCHA rejects `execute()` on unlisted hosts.

**Fix:** Document required domains in `docs/firebase-setup.md` and `docs/keys-and-secrets.md`. Web bootstrap logs the current host and reCAPTCHA admin link when token fetch fails.

**Manual (required):** [Google reCAPTCHA admin](https://www.google.com/recaptcha/admin) → **SaleSiren** key → add `salesiren.bytecinch.com` under domains. Confirm Firebase Console → App Check → Web app uses the matching secret for site key `6LeGTS8t…`.

---

## 2026-06-19 — App Check `app-check/no-provider` on Cloudflare web deploy

**Symptom:** After deploying the admin panel to Cloudflare, bootstrap logged `AppCheck: No attestation provider was passed to initializeAppCheck()` (`app-check/no-provider`).

**Cause:** `String.fromEnvironment` used the reCAPTCHA site key value as the define name instead of `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY`, so release web builds had an empty key and fell back to `WebReCaptchaProvider()` (requires ReCAPTCHA Enterprise in Firebase config).

**Fix:** Read `FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY` with the documented SaleSiren site key as `defaultValue`, and use `ReCaptchaV3Provider` for web release builds.

---

## 2026-06-24 — No-access users seeing admin navigation

**Symptom:** A signed-in user with no admin access could see admin panel navigation options after login or during profile resolution.

**Cause:** The shell built sidebar/header navigation before the admin access check rendered the no-access view. Navigation fallback also returned the owner/admin item list while the current profile was still null.

**Fix:** Gate the shell frame on `adminAccessProvider` before drawing admin navigation, and return no navigation items until the admin profile is resolved.

---

## 2026-06-24 — FCM dispatch successCount 0 (stale fcmTokens)

**Symptom:** Admin logs `FCM dispatch sent 0 notifications` after resend/publish even though mobile users exist.

**Cause:** `fcmTokens` used `arrayUnion`, so old invalid tokens from reinstalls/debug builds accumulated. FCM attempted every stale token and all failed.

**Fix:** Mobile app replaces `fcmTokens` with the current device token on sync (and clears when notifications disabled). Admin dispatch logs distinguish no tokens vs all invalid vs partial failure.

---

## 2026-06-24 — FCM `cloudmessaging.messages.create` denied

**Symptom:** `cloudmessaging.messages.create` denied on `projects/salesiren-5539c`; push dispatch `successCount=0` with a token present.

**Cause:** Cloud Functions Gen 2 default runtime service account (`508084936274-compute@developer.gserviceaccount.com`) lacks FCM send permission. `roles/firebasemessaging.admin` alone may not include `cloudmessaging.messages.create`.

**Fix:** Functions now run as `salesiren-5539c@appspot.gserviceaccount.com` via `setGlobalOptions`. Redeploy functions. If it still fails, grant that account **Firebase Admin** (`roles/firebase.admin`) or use the `firebase-adminsdk-*` service account from IAM.

---

**Symptom:** `successCount=0 tokenCount=1 invalidTokenCount=0` — FCM rejected the send without marking the token invalid (often APNs/auth or sender mismatch).

**Fix:** Cloud Function records first FCM error on `offer_push_jobs.lastError`, treats `messaging/sender-id-mismatch` as removable tokens, and admin logs include the FCM error text.

---

## 2026-06-24 — Flutter error presenter null crash

**Symptom:** Admin web crashes with `Unexpected null value` from `diagnostics.dart` while reporting a Flutter framework error.

**Cause:** The global `FlutterError.onError` handler called `FlutterError.presentError(details)` directly. On Flutter Web, the debug diagnostics renderer can throw while rendering some structured errors.

**Fix:** Guard the framework error presenter so the original error is logged and a secondary diagnostics-rendering failure cannot crash the app.

---

## 2026-06-24 — Cloud Function Firestore permission denied

**Symptom:** `dispatchOfferPushOnJob` logs `Missing or insufficient permissions` from `@google-cloud/firestore` / gRPC while reading Firestore in Cloud Functions.

**Cause:** This is not a Firestore rules denial. Cloud Functions Admin SDK uses the function runtime service account, and that service account is missing Firestore/Datastore IAM permission.

**Fix:** Grant the deployed function runtime service account **Cloud Datastore User** (`roles/datastore.user`) on project `salesiren-5539c`. See `docs/firebase-functions-deployment.md`.

---

## 2026-06-24 — Offer push job has no result

**Symptom:** Admin panel logs `FCM dispatch finished with no job result` after writing `offer_push_jobs/{jobId}`.

**Cause:** `dispatchOfferPushOnJob` could return without updating the job when the offer was missing or not published, leaving the admin poller with no `dispatchCompletedAt`, `sentCount`, or `lastError`. The web poll window was also short for Gen 2 cold starts.

**Fix:** Mark skipped jobs with `lastError`/completion fields and extend admin polling so the UI receives an actual job result or error instead of a silent timeout.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnJob --project salesiren-5539c`

---

## 2026-06-24 — Admin web still blocked by sendOfferPush CORS

**Symptom:** Admin web still shows `sendOfferPush` CORS preflight blocked from localhost.

**Cause:** The browser calls the HTTPS callable directly from Flutter Web. If the deployed callable endpoint is still missing CORS headers, the browser blocks the request before Cloud Functions code runs.

**Fix:** Skip the direct `sendOfferPush` callable on Flutter Web. The admin panel already writes `offer_push_jobs`; `dispatchOfferPushOnJob` sends the FCM notification from Cloud Functions without a browser CORS request.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnJob --project salesiren-5539c`

---

## 2026-06-24 — sendOfferPush CORS preflight blocked on web

**Symptom:** Admin web publish fails before calling `sendOfferPush`: browser blocks the preflight with `No 'Access-Control-Allow-Origin' header`.

**Cause:** The deployed callable endpoint is not returning CORS headers for browser preflight from localhost/admin web.

**Fix:** Set explicit `cors: true` on the v2 callable `sendOfferPush` options so web origins can complete the Firebase callable preflight. Auth and role checks still run inside the callable.

**Deploy:** `firebase deploy --only functions:sendOfferPush --project salesiren-5539c`

---

## 2026-06-24 — Offer publish Cloud Function push not reaching mobile

**Symptom:** Firebase Console notifications reach the device, but publishing an offer from the admin panel does not send mobile push through Cloud Functions.

**Cause:** The callable `sendOfferPush` authorized only against `users/{uid}`, so legacy owner/admin accounts backed only by `admins/{uid}` could be rejected. The broadcast recipient loader also only queried explicit `mobile_user` role fields, so token-bearing legacy consumer docs could be skipped.

**Fix:** Allow `sendOfferPush` callers through either `users/{uid}` privileged roles or `admins/{uid}` admin reference roles, and include a token-bearing user scan fallback while still excluding privileged/admin roles.

**Deploy:** `firebase deploy --only functions:sendOfferPush,functions:dispatchOfferPushOnJob --project salesiren-5539c`

---

## 2026-06-19 — Offer delete leaves images in Firebase Storage

**Symptom:** Deleting an offer removes the Firestore document but uploaded images under `offers/{offerId}/` remain in Storage.

**Cause:** `deleteOffer` only deleted the Firestore doc. Storage rules also blocked delete because `allow write` required `request.resource` (null on delete).

**Fix:** Delete the `offers/{offerId}/` folder plus any image URLs on the offer/lines before removing the doc. Split Storage rules into create/update vs delete for offer images.

---

## 2026-06-24 — sendOfferPush callable Int64 error on Flutter web

**Symptom:** `sendOfferPush response parsing skipped on web; reading Firestore job result | Unsupported operation: Int64 accessor not supported by dart2js`.

**Cause:** `cloud_functions` deserializes callable responses on web using Int64 for some wire fields. The function often completes, but `callable.call()` still throws when parsing the response.

**Fix:** On web, skip `sendOfferPush` callable entirely — `offer_push_jobs` write triggers `dispatchOfferPushOnJob`, then poll `offer_push_jobs` for `sentCount`. Callable path kept for non-web only.

**Follow-up (2026-06-19):** Skipping the callable left dispatch dependent on the Firestore trigger alone; polling timed out with no `dispatchCompletedAt`. Restore the callable on web (Int64 only breaks response parsing — the function still runs), swallow that parse error quietly, and extend job polling.

---

## 2026-06-24 — Admin push job scheduled but FCM never sent

**Symptom:** Admin logs show `offer_push_jobs` scheduled and mobile users with `fcmTokens`, but no device notification. `notification_requests` stays `approved` (not `sent`).

**Cause:** FCM is sent only by Cloud Functions. Scheduling a Firestore job does nothing if `dispatchOfferPushOnJob` / `sendOfferPush` are not deployed or the trigger did not run.

**Fix:** Add callable `sendOfferPush` (immediate dispatch from admin after job write), job claim deduplication, and admin logs for `successCount` / deploy hints.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnJob,functions:sendOfferPush --project salesiren-5539c`

---

## 2026-06-19 — Push publish debug logging (users + FCM tokens)

**Symptom:** Publishing a notification request only logs `Publishing offer line…` in the admin panel; no visibility into FCM recipients or whether the push job ran.

**Fix:** Log `offer_push_jobs` scheduling details and enumerate mobile users with `fcmTokens` in the admin panel console; expand Cloud Function logs with per-user/token dispatch details.

---

## 2026-06-19 — ListTile ink splashes invisible in admin panel

**Symptom:** Debug warning: “ListTile background color or ink splashes may be invisible” — tap/hover feedback missing on list rows and switch tiles (especially inside colored offer-line cards).

**Cause:** [ListTile](https://api.flutter.dev/flutter/material/ListTile-class.html) paints ink on the nearest [Material](https://api.flutter.dev/flutter/material/Material-class.html) ancestor; opaque [DecoratedBox](https://api.flutter.dev/flutter/widgets/DecoratedBox-class.html) / [Container](https://api.flutter.dev/flutter/widgets/Container-class.html) backgrounds between the tile and that Material hide the splash.

**Fix:** Add `AppListTileMaterial` wrapper and use it for all `ListTile` / `SwitchListTile` / `CheckboxListTile` instances; tune `listTileTheme` selected/hover colors.

---

## 2026-06-19 — Admin notification-request publish does not reach mobile users

**Symptom:** FCM works from Firebase Console, but publishing a notification request from the admin panel does not deliver push to mobile users (foreground, background, or killed).

**Causes:**
1. `publishOffer()` did not pass `requestId` into `offer_push_jobs`, so job dispatch could not tie to the approved request.
2. Cloud Function targeted only users matching offer category/brand interests; most mobile users were excluded even when candidates were found.
3. `dispatchOfferPushOnPublish` and `dispatchOfferPushOnJob` could both fire on first publish (duplicate path); re-publishes on already-published offers only relied on the job path.
4. FCM token was not written during `ensureRegistered` — only after preference sync / permission grant.

**Fix:**
- Admin: `publishOffer(..., requestId:)` schedules `offer_push_jobs` with `requestId`.
- Cloud Function: `offer_push_jobs` dispatch broadcasts to all mobile users with `fcmTokens` (`notificationEnabled !== false`); skip duplicate `onPublish` dispatch.
- Mobile: sync FCM token to Firestore during `ensureRegistered` when notifications are enabled locally.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnPublish,functions:dispatchOfferPushOnJob` from `apps/adminpanel`.

---

## 2026-06-19 — User management errors only in console

**Symptom:** Delete/edit user (or toggle active) fails silently for managers; `Only owners can manage users` appears only in the browser console.

**Fix:** Run owner checks inside `AsyncValue.guard` so errors land in provider state; listen on the users list and edit screens to show `showAppError`; disable manage actions for non-owners on the list.

---

## 2026-06-19 — New brand navigates to dashboard

**Symptom:** Tapping **New brand** (or **Add brand**) redirects to the dashboard instead of opening the brand form.

**Fix:** Allow `/brands/new` for managers in router redirect guards; keep `/brands/register` and `/brands/new` blocked for brand admins only.

---

## 2026-06-19 — AppAvatar image error during brand listing build

**Symptom:** `Build scheduled during frame` assertion when brand logos fail to load on the brands list.

**Fix:** Stop calling `setState` from `CircleAvatar.onBackgroundImageError` during layout; use `Image.network` with `errorBuilder` for safe fallback rendering.

---

**Symptom:** `AdminAccessProvider` logs `permission-denied` for uid on startup; admin panel shows missing access.

**Fix:** Standalone Firestore `allow get` bootstrap for `users/{uid}` and `admins/{uid}`; guard `targetIsOwner()` when `resource` is null; await auth ID token before profile reads; catch `permission-denied` on admin fallback and `selected_categories` fetch.

---

**Symptom:** `AdminAccessProvider` logged `User profile self-read denied... checking admin reference` as a warning even though the admin-reference fallback can be expected for legacy owner accounts.

**Fix:** Silenced only the expected `users/{uid}` permission-denied fallback message. Real admin profile failures still log as warnings.

---

## 2026-06-23 — Admin profile check still permission denied

**Symptom:** `AdminAccessProvider` still logged `permission-denied` while checking the signed-in admin profile.

**Fix:** Made Firestore profile self-read rules explicit for both `users/{uid}` and `admins/{uid}` so profile bootstrap can read the signed-in account before broader role checks run.

---

## 2026-06-23 — Admin profile self-read permission denied

**Symptom:** `AdminAccessProvider` logged `permission-denied` while loading the signed-in user's admin profile.

**Fix:** Made admin profile lookup continue to the `admins/{uid}` fallback when `users/{uid}` is denied and adjusted Firestore self-read rules to allow the signed-in user/admin reference before broader role checks.

---

## 2026-06-23 — Offer image NetworkImageLoadException

**Symptom:** Firebase Storage offer images could throw `NetworkImageLoadException` with statusCode `0` on Flutter Web.

**Fix:** Added a web-friendly shared network image widget with graceful fallback and used it on offer list, detail, and form preview images.

---

## 2026-06-23 — App Check bootstrap logger type

**Symptom:** Compile failed because `_activateFirebaseAppCheck` expected `AppLogger` while bootstrap passed a `Logger`.

**Fix:** Updated the App Check helper to accept the actual `Logger` type returned by `AppLogger.get()`.

---

## 2026-06-23 — Users navigation opens dashboard

**Symptom:** Clicking Users could route back to Dashboard instead of showing the Users page.

**Fix:** Kept Users as an allowed sidebar route for owner, manager, and brand-scoped admin navigation.

---

## 2026-06-23 — Firebase App Check provider missing

**Symptom:** Firebase logged `No AppCheckProvider installed` and used placeholder App Check tokens.

**Fix:** Added Firebase App Check startup activation so Firebase services receive a platform provider during admin panel bootstrap.

---

## 2026-06-23 — Admin panel stale compile references

**Symptom:** Compile failed on stale references for `_discountType`, `isSuperAdminProvider`, and missing user registration arguments.

**Fix:** Reconnected the references to the current offer-line, owner-provider, and user-registration APIs.

---

## 2026-06-23 — Admin role utility missing members

**Symptom:** Admin panel compile failed with `Member not found: 'UserRoleUtils.isMobileUserOnly'` and related role-helper calls.

**Fix:** Restored the shared role utility helpers used by auth and user-management screens.

---

## 2026-06-19 — Dashboard featured/normal offers UI, bell badge, brand logos, publish push

**Mobile:** Featured carousel + separate “Top Offers” list; removed header bell; unread dot on bottom-nav Alerts tab; brand logos from `/brands` on explore screens.

**Admin:** Offer image required on create/edit; `offer_push_jobs` schedules FCM dispatch on publish.

**Cloud Functions:** `dispatchOfferPushOnJob` trigger + mobile-user fallback when category queries return no candidates.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnPublish,functions:dispatchOfferPushOnJob,firestore:rules`

---

## 2026-06-19 — Mobile users not notified when manager publishes offer

**Symptom:** Publishing an offer from the admin panel did not deliver push notifications to mobile users (including with the app open).

**Causes:**
1. Cloud Function required **both** category and brand interest (`categoriesMatch` AND `brandMatches`), so users matched only by `selected_categories` were excluded.
2. `isMobileRecipient` did not fall back to `role` when `roles` was an empty array.
3. `publishOffer()` did not set `isVerified: true`, so published offers stayed hidden from the mobile feed.
4. Mobile FCM tokens were often never written to `users/{uid}.fcmTokens` (only on preference change, not on login/resume/token refresh).
5. Foreground display needed Android 13+ notification permission for local notifications.

**Fix:**
- Cloud Function: `userWantsOffer()` uses category **OR** brand match; improved role resolution; include `title`/`body` in FCM `data`.
- Admin: `publishOffer` sets `isVerified: true`; managers/owners see all notification requests; direct publish from offer form auto-verifies.
- Mobile: `FcmTokenSyncListener` syncs token on login/resume/refresh; Android notification permission; default `notificationEnabled` on profile.

**Deploy:** `firebase deploy --only functions:dispatchOfferPushOnPublish` from `apps/adminpanel`.

---

## 2026-06-19 — Mobile: CircularDependencyError on preferences sync

**Symptom:** `CircularDependencyError: syncUserPreferencesProvider` at startup.

**Cause:** `AppPreferences._set()` watched `syncUserPreferencesProvider`, which watched `appPreferencesProvider`.

**Fix:** Extracted `pushUserPreferencesToFirestore` helper; preferences use `read` not `watch`; moved connectivity to `connectivity_providers.dart`.

---

## 2026-06-19 — Mobile: light theme showing dark widgets

**Symptom:** Some cards/backgrounds stayed dark in light mode.

**Fix:** Aligned scaffold/background widgets with theme (`AppScaffold`, `AppThemedBackground`, `AppDarkCard` usage).

---

## 2026-06-19 — Mobile: logout landed on wrong screen

**Symptom:** After logout, user was not returned to welcome/landing.

**Fix:** Router/sign-out flow navigates to welcome screen.

---

## 2026-06-19 — Brand logo URLs not loading on web (Google favicons)

**Symptom:** Brand logos from URLs like `https://www.google.com/s2/favicons?sz=256&domain=…` do not display.

**Cause:** Flutter Web `NetworkImage` defaults to `WebHtmlElementStrategy.never`, fetching bytes via XHR which fails CORS for third-party favicon hosts.

**Fix:** Use `WebHtmlElementStrategy.prefer` on brand logo `Image.network` / `NetworkImage` loads. Simplify `AppAvatar` to `Image.network` with `errorBuilder` fallback.

---

## 2026-06-19 — Users list keeps refreshing for manager

**Symptom:** Manager users screen repeatedly shows loading / refreshes.

**Cause:** `managedUsersProvider` used `await ref.watch(currentUserProfileProvider.future)` inside an `async*` stream. Auth token refreshes re-ran the profile future, cancelled the Firestore subscription, and restarted the stream. The `role != owner` query also required `orderBy` and was fragile.

**Fix:** Build the users stream synchronously; depend only on auth uid and primary role via `select`. Manager query uses `where('role', whereIn: [...])` plus client-side owner filter. Add **Brands** to manager sidebar nav (`_managerItems`).

---

## 2026-06-19 — Users listing keeps loading

**Symptom:** Users screen stays on loading spinner.

**Cause:** `managedUsersProvider` read `isOwner` / `isManager` from `currentUserProvider` before the profile future resolved. Managers briefly ran an unfiltered `users` query (blocked by rules), then switched to a `role != owner` query. Firestore `!=` filters also require `orderBy` on the same field.

**Fix:** Wait for `currentUserProfileProvider.future` before subscribing. Manager query uses `where('role', isNotEqualTo: owner).orderBy('role')` plus client-side owner filter. Split `users` read rules into `get` (per-doc) and `list` (collection query) so manager list queries are allowed.

---

## 2026-06-18 — Mobile Google sign-in Firestore users write denied

**Files:** `firestore.rules`, `apps/mobileapp/firestore.rules`
**Fix:** Relaxed mobile self-write rules so merge updates succeed when `role` is missing or only `roles` contains `mobile_user`. Replaced strict `selfUpdateDoesNotEscalate` role equality check with `dataIsMobileUserOnly` + `existingHasPrivilegedRole` guards.

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
