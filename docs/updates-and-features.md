# Updates and New Features

Log all new features, enhancements, and non-bug work here **before** implementing.

**Firestore rules/indexes:** edit `apps/adminpanel` first, copy to `apps/mobileapp` — see `docs/firestore-rules-sync.md`.

---

## 2026-06-19 — Unified selectors and shimmer loading

Shared `AppFieldSelector`, `SingleSelectField`, and updated `MultiSelectField` for consistent dropdown-style fields; shimmer placeholders replace spinners on data fetch loading states.

---

## 2026-06-19 — Offer open-ended end dates

Offer form supports fixed end date, ongoing, or until stock ends (`endDateMode`); open-ended offers store no `endDate` in Firestore.

---

## 2026-06-19 — Auto-generated city and category IDs

New city/category forms no longer accept a manual ID; Firestore assigns the document ID on create. Edit screens show the ID read-only.

---

## 2026-06-19 — Offer form category scope and city defaults

Offer create/edit: multi-select categories (dropdown), whole-brand scope option, Lahore default city, and select-all cities in picker.

---

Title: `{brand}: {discountText}`. Body: ad title + full stop + ad description (single line).

---

## 2026-06-19 — Notification title/body format

Title: `{brand}: {discountText}`. Body: offer title then description.

---

## 2026-06-19 — Notification listing edit/publish title refresh

Edit and publish on existing notification requests re-fetch the linked offer to suggest title (offer + discount) and description.

---

## 2026-06-19 — Smart default notification titles

Default push title blends offer title with discount (when not already present); still editable in preview.

---

## 2026-06-19 — Offer notification defaults and publish preview

Notification requests use offer title and description; pre-publish dialog to edit push title, body, and image option.

---

## 2026-06-19 — Notification publish UI compact selector

Hide brand publish-all buttons when collapsed; per-request segmented publish control with compact Publish action.

---

## 2026-06-19 — Notification requests list UI polish

Rename publish buttons (no counts), collapsible brand cards, per-request publish action panel (with/without notification only).

---

## 2026-06-24 — Notification request publish modes

Notification requests list: publish pending offers with or without push — per request, per brand card, and publish-all at the top.

Remove unused imports project-wide, replace deprecated APIs (`dart:html`, `withOpacity`, dropdown `value`), add `docs/release-management.md` + release build script, and tighten `.gitignore` for push hygiene.

When `AppLoadingOverlay` is active during API/Firebase work, action buttons stay disabled but no longer show their own `CircularProgressIndicator`. Shared `AppAsyncButtonIcon` / `AppAsyncProgressIcon` helpers; applied across login, registration, CRUD forms, subscriptions, settings seed, and bug report screens.

---

## 2026-06-24 — Bug report submit for all admin users

Report Bug (`/bug-reports/submit`) is available to every signed-in admin-panel user. Managing bug reports (`/bug-reports`) remains owner-assigned.

Sidebar and route guards respect owner-assigned `featureIds` for all non-owner users (e.g. bug reports, reports, pricing). Role-specific nav lists are merged then filtered by feature access; brand/manager hardcoded route allowlists removed in favor of feature checks plus structural restrictions.

When an inbox is already verified in Firebase Auth (no Firestore profile yet), detect it on send/check, show the verified email, and prompt the admin to complete Step 2 registration.

Keep a single email field in the verification step only (no duplicate below after verify). Vertically center the send-verification button with the email input row.

---

## 2026-06-24 — Registration email verification without web CORS

Flutter web starts/checks/cancels registration email verification via `registration_email_verification_jobs` and `dispatchRegistrationEmailVerificationJob` (same pattern as `offer_push_jobs`), avoiding HTTPS callable CORS from localhost and Cloudflare.

---

## 2026-06-24 — Registration email verification UI polish

Improve the user registration email verification card: clearer idle/pending/verified states, verified-only green check on the email field, and a more polished step layout.

---

## 2026-06-24 — Admin branding logo refresh

Replaced admin branding assets with the new Sale Siren icon and complete logo: full combined logo for login, icon-only mark for dashboard/sidebar branding, and icon-only mark for browser favicon/PWA icons.

---

## 2026-06-24 — Notification image control and mobile ads setting

Notification requests now include a Send with image option so push notifications can be delivered with or without the offer image. Owner settings include a mobile ads toggle stored as `app_settings/mobile_ads.enabled` for the mobile app to read when ads are implemented.

Schema: `docs/firestore-schema.md` (Notification Requests, App Settings). Functions: `docs/firebase-functions-deployment.md`.

Update: when Send with image is enabled, notification requests store the first top-level offer image and push dispatch prefers that stored request image.

---

## 2026-06-24 — Offer replacement and cleanup lifecycle

Notification requests can be edited after they are sent, expired offers can be duplicated into a fresh editable replacement, and a scheduled Cloud Function removes expired offers older than 10 days with their Storage images and related notification/push records. Duplicated offers copy content/settings but require fresh images so later cleanup cannot break replacement offers.

Docs: `docs/firebase-functions-deployment.md`, `docs/firestore-rules-sync.md`.

---

## 2026-06-24 — Appealing default offer notification titles

Default notification request titles now combine the offer title with discount text/type so mobile push notifications are more descriptive than “New offer available.”

---

## 2026-06-24 — User-friendly push notification errors in admin UI

When FCM dispatch fails or sends to zero devices, show a clear dialog (not only console logs) with actionable guidance for IAM, missing tokens, stale tokens, and iOS APNs setup.

---

## 2026-06-19 — Human-readable labels for internal slugs in admin UI

Show proper display names (e.g. **Price Drop** instead of `price_drop`) for alert types, roles, statuses, discount types, subscription types, payment methods, and other snake_case tags across admin panel lists and badges.

---

## 2026-06-19 — Resend notification on notification request list

Move **Resend notification** from the offers list to each published notification request in the notification requests list. Reschedules `offer_push_jobs` for that request’s offer/line and invokes `sendOfferPush`.

---

## 2026-06-24 — Resend notification button on offer list (superseded)

~~Each published offer in the offers list shows a **Resend notification** action~~ — moved to notification requests listing (see 2026-06-19 entry above).

---

## 2026-06-19 — Firestore app features catalog and per-user access

Seed `app_features` for admin panel and mobile app modules. Owners assign `featureIds` when registering or editing users. Navigation and routing respect assigned features; owners keep full access.

---

## 2026-06-19 — Mobile users default to all mobile app features

Mobile-only users receive every mobile feature on app signup/login and when resolving access, so older profiles without `featureIds` still see the full app.

---

## 2026-06-19 — User-friendly error messages across admin panel

Centralized friendly error text for lists, forms, dashboard, profile, diagnostics, and inline field loads. Raw Firebase/exception strings are no longer shown in the UI.

---

## 2026-06-19 — Branded AppLoader on all list and CRUD loading states

Unified loading UX to use the mobile-style `AppLoader` for Firebase/list fetches and CRUD operations, with a shared overlay on screens during async actions.

---

Moved page titles from the scaffold header slot into the body on all list screens. Notification requests list now has offers-style search. Published offers remain editable until their end date passes.

---

Expanded list search to match names, ids, sort order, status flags, and other metadata across catalog screens. List pages now show only the branded mobile-style loader until data is ready. Users list redesigned with summary chips, search, responsive grid, and rich user tiles.

---

Redesigned brands list with summary stat chips, responsive card grid, and rich brand tiles (logo, metadata badges, status labels).

---

## 2026-06-19 — List search on offers, brands, cities, and categories

Added a shared search field to offers, brands, cities, and categories list screens. Search filters client-side by name, id, related metadata, and stored search keywords.

---

## 2026-06-19 — Cities and categories listing UI polish

Redesigned city and category list screens with summary stat chips, responsive card grid layout, and richer tiles (color accents, metadata badges, improved actions).

---

## 2026-06-19 — Offers filter loading fix and stats-only dashboard

Fixed offers list stuck loading when filters change by decoupling the Firestore stream from filter state (client-side filtering). Dashboard now shows statistics-only with charts and animated count transitions; recent offers section removed.

---

Create-offer drafts persist in browser storage per user so accidental navigation does not lose in-progress cards. Notification requests list uses the same brand-grouped card layout as the offers list.

---

Each offer card on the create/edit form now includes its own status, verification, lifecycle, brand, cities, dates, featured flag, and image display settings. Batch create saves one Firestore offer per card. Offers list filters use dropdown multi-select instead of chips.

---

Grouped offer creation now uses complete per-offer cards (title, description, category, discount, multiple images, multiple link sources) instead of shared images/URLs with discount-only lines. One Firestore offer document stores enriched `offerLines`; mobile detail switches title, images, and links per selected line.

Schema: `docs/firestore-schema.md` (Offers `offerLines`).

---

## 2026-06-23 — Offer Multiple Images and Mobile Display Settings

Offers now support multiple uploaded image URLs while keeping `imageUrl` as the primary fallback. Added offer-level mobile image settings for slider auto-advance and detail image view mode (`carousel` or `grid`).

Schema: `docs/firestore-schema.md` (Offers).

---

## 2026-06-23 — Offer and Notification Card Polish

Improved offer listing cards with richer image/status presentation, added brand labeling to notification request cards, and hid publish-all actions when there are no pending requests to publish.

---

## 2026-06-23 — Grouped Offer and Notification Admin Lists

Updated offer administration so create can submit multiple single-line offers, edit stays focused on the current offer, offers and notification requests use brand/offer grouped card layouts, offer filters support multi-selection, and notification requests support top-level and group-level publish-all actions.

---

## 2026-06-23 — Shared keys & secrets document

`docs/keys-and-secrets.md` (gitignored, team local) and `docs/keys-and-secrets.template.md` (tracked) centralize Firebase, reCAPTCHA SaleSiren, Google/Apple sign-in OAuth, and deploy keys for admin + mobile.

---

## 2026-06-19 — Grouped mall offers with multiple offer lines

Offers can contain multiple `offerLines` (category + discount per line) under one brand/city/date group. Admin form uses an offer-lines editor; notification requests are created per line with publish-one or publish-all; mobile detail shows line picker and “Other offers” when grouped. Schema: `docs/firestore-schema.md` (Offers, Notification Requests, Offer Push Jobs).

---

## 2026-06-19 — Manager offers default to pending review

New offers default to `pending_review` / unpublished. Managers cannot set Published on the offer form; they publish via **Notification Requests**. Repository and Firestore rules enforce pending-only saves for managers. Brand admins may still publish directly from the form.

---

## 2026-06-19 — Firestore rules & indexes sync workflow

Added `docs/firestore-rules-sync.md`. Canonical rules live in `apps/adminpanel/firestore.rules`; mobile copy must stay identical. Merged `firestore.indexes.json` (offers composite indexes + `saved_brands` / `selected_categories` collection-group overrides) in both apps.

---

## 2026-06-19 — User doc: drop legacy `selectedCategories` and `favoriteBrands`

Mobile and admin no longer write `selectedCategories` or `favoriteBrands` on `users/{uid}`. Categories live in `selected_categories` subcollection; brand favorites in `saved_brands` subcollection. Legacy array fields are deleted on sync and still read once for migration.

---

## 2026-06-19 — Selected categories subcollection

User catalog preferences moved from `users/{uid}.selectedCategories` array to `users/{uid}/selected_categories/{categoryId}` (`categoryId`, `createdAt`). Admin panel `SelectedCategoriesSync`, Cloud Functions `userCategoryIdsForUser()`, Firestore rules, and collection-group index updated.

---

## 2026-06-19 — Favorite brands subcollection only

Brand favorites stored in `users/{uid}/saved_brands/{docId}` (`categoryId`, `brandName`, `createdAt`). Removed `favoriteBrands` array from user document.

---

## 2026-06-19 — Multiple roles per user

Users support `roles: string[]` (plus legacy single `role`). Admin registration/edit shows role chips from seeded `roles` collection. Firestore rules use `userRoleList()` / `hasUserRole()`. Settings seeds roles with auto-generated document IDs.

---

## 2026-06-19 — User notification toggle (`notificationEnabled`)

Admin user add/edit exposes `notificationEnabled` (single field). Mobile app syncs the same field to Firestore preferences.

---

## 2026-06-19 — Push targeting by user preferences (no FCM topics)

Removed mobile FCM category-topic subscription. Cloud Function matches published offers to users via `selected_categories` subcollection and `saved_brands` / `brandIds` filters.

---

## 2026-06-19 — Mobile: dashboard category tabs from user catalog

Home feed category chips show only categories the user selected in onboarding/settings, not the full catalog.

---

## 2026-06-19 — Mobile: settings “Pick your catalog”

Renamed interests copy to catalog-focused label (`pickYourCatalog`).

---

## 2026-06-19 — Admin: brand logos in list

Brands list shows `logoUrl` via `AppAvatar` / `BrandModel` (supports `logoUrl`, `logurl`, `logUrl`).

---

## 2026-06-19 — Mobile: guest favorites sync on sign-in

Local saved offers/brands merge to Firestore when a guest signs in.

---

## 2026-06-19 — Firebase Functions deployment guide

Added `docs/firebase-functions-deployment.md` with deploy steps and the build service account IAM fix for `salesiren-5539c`.

---

## 2026-06-19 — FCM push to matching users when offer is published

Cloud Function `dispatchOfferPushOnPublish` runs when an offer becomes published. It finds mobile users whose selected categories and brands match the offer, reads their `fcmTokens`, sends FCM notifications, and updates the linked `notification_requests` record with `sent` status and counts.

---

## 2026-06-19 — Remove role label under Sale Siren in sidebar

Removed Owner/Admin subtitle from the sidebar brand mark on dashboard and all shell views.

---

## 2026-06-18 — Brand Topic Field for Future Subscriptions

Added a future-ready brand `topic` field and generation path so brand topic subscriptions can be introduced later without changing the current app flow.

---

## 2026-06-18 — Offer Publish Category Topics

Updated offer notification request creation so selected offer categories resolve to their seeded category topics for mobile-app topic subscribers.

---

## 2026-06-18 — Category Topic Seed Field

Added a short unique category `topic` value generated during category seeding from the category name plus a short unique suffix.

---

## 2026-06-19 — Manager can add brand but not register brand

Managers can create brands via New brand; Register brand (with login account) remains owner-only.

---

## 2026-06-19 — Admin profile view for owner, manager, and brand admin

Added a My Profile screen with prefilled account details and editable contact/preferences; profile menu opens it instead of Settings.

---

## 2026-06-19 — Restrict master data seeding to owners

Managers and brand admins can no longer seed cities, categories, brands, or roles from Settings.

---

## 2026-06-19 — User registration waits for seeded roles

Removed hardcoded fallback roles from user registration; role chips appear only after the owner seeds roles in Settings.

---

## 2026-06-19 — User catalog preferences on registration and edit

Users can be assigned `categoryIds`, `cityIds`, and `brandIds` at registration and updated later from the user edit screen.

---

## 2026-06-19 — Auto-generated role document IDs on seed

Role seeding now upserts by `slug` and assigns Firestore auto-generated document IDs; the stored `id` field matches the document ID. User assignment still uses role slugs for auth.

---

## 2026-06-19 — Firestore rules owner role only

Removed legacy `user_owner` and `super_admin` role slugs from Firestore rules; owner checks use `owner` only.

---

## 2026-06-19 — Rename User Owner role to Owner

Renamed `user_owner` role slug, labels, providers, and Firestore rules to `owner` / Owner across admin panel and mobile app rules. Legacy `user_owner` and `super_admin` values still accepted for existing data.

---

## 2026-06-18 — Rename Super Admin role to User Owner

Renamed `super_admin` role slug, labels, providers, and Firestore rules to `user_owner` / User Owner across admin panel and mobile app rules. Legacy `super_admin` values still accepted for existing data.

---

## 2026-06-18 — Mobile app open signup and sign-in Firestore rules

Allow any authenticated mobile user to create their own `users/{uid}` profile on signup (mobile_user only) and read/update their own profile. Synced rules to the mobile app copy.

---

## 2026-06-18 — Managers see users except super admins

Managers can list and view non–super-admin users only. Super-admin profiles are hidden in the users provider and blocked by Firestore read rules for managers.

---

## 2026-06-18 — Super admins in users table; admins as id/role reference

Super admins are stored in `users` with full profile. On register, email is checked against `users` before creating Auth. When role includes `super_admin`, a matching `admins/{uid}` reference doc is written with only `id` and `role`. User edit/delete keeps the reference in sync.

---

## 2026-06-18 — First-login temporary password change prompt

Users registered with a temporary password are prompted to set a new password on first sign-in. They can skip with a security warning and will be prompted again on the next login until the password is changed.

---

## 2026-06-18 — Super-admin-only user management; managers view-only

Restricted user create, edit, delete, and profile mutations to super admins. Managers can open the Users list and view details only. Updated router, nav, UI, providers, and Firestore rules.

---

## 2026-06-18 — User admin/mobile access flags and login gate

Added `isAdminEnabled` and `isMobileAppEnabled` on user profiles. Admin login and routing now require `isAdminEnabled` (super admins always allowed). User create/edit screens expose both toggles; mobile-only users cannot enable admin access; managers default to admin disabled.

---

## 2026-06-18 — Public mobile offer feed reads (published + verified, not expired)

Updated Firestore `offers` get/list rules so anyone using the mobile app can read offers that are published, verified, and not expired (no `mobile_user` role required). Unpublished, unverified, and expired offers remain hidden. Admin/brand/manager and offer-owner access unchanged.

---

## 2026-06-18 — Merge mobile app saved_offers rule into admin Firestore rules

Added the `users/{userId}/saved_offers/{offerId}` subcollection rule from the mobile app `firestore.rules` into the admin panel `firestore.rules` so a single ruleset can be pasted into the Firebase console. Existing admin/brand rules unchanged; the catalog/offer/report/user reads required by the mobile app are already covered by the current rules.

---

## 2026-06-17 — Notification Request Status Pill and Publish Selector

Restored notification request status visibility with Pending Review/Published labels and added a status selector for pending requests. Published requests are read-only with only the status pill and view action.

---

## 2026-06-18 — Mobile user offer visibility and save/share rule access

Updated Firestore rules so `mobile_user` can read published offers and perform restricted save/share counter updates on published offers.

---

## 2026-06-17 — Offer discount types + integer-only value input

Added `Up to percentage` and `Up to amount` discount types, removed the temporary discount category selector, and made discount value input integer-only for custom percentage/flat/up-to values.

---

## 2026-06-17 — Offer create up-to discount category selector

Added an "Up to %" discount category selector on the offer form to quickly set percentage-based discount text/value during offer creation.

---

## 2026-06-17 — Animated login right-panel logo

Added a subtle fade + scale reveal animation for the combined logo shown above the right-side login card.

---

## 2026-06-17 — Right login logo moved outside card

Moved the combined Sale Siren logo outside the login card container so it appears above the login section.

---

## 2026-06-17 — Right login panel combined logo

Added the provided combined Sale Siren logo to the top of the right-side login section.

---

## 2026-06-17 — Login panel logos removed

Removed both parrot and tagline logos from the login left panel, keeping text-only animated branding content.

---

## 2026-06-17 — Animated login left-panel text and intro chime

Added animated visibility for login left-panel marketing text and a short built-in chime sequence when the panel appears.

---

## 2026-06-17 — Login left-panel combined branding

Updated login left-panel branding to show the combined Sale Siren mark (parrot over tagline) and removed the old top-left heading/logo row.

---

## 2026-06-17 — Unified Sale Siren logo and browser title

Fixed clipped panel logo rendering, reused the same parrot logo on login, applied the same logo for Chrome tab icons, and updated browser/app display name to `Sale Siren`.

---

## 2026-06-17 — Admin panel logo updated to parrot asset

Updated the admin panel brand mark to use the provided Salesiren parrot image asset.

---

## 2026-06-17 — Offer Lifecycle Alignment and Notification Status Cleanup

Moved the offer lifecycle selector next to Verification in the offer form, and temporarily hid notification request status pill/status-change controls from the listing.

---

## 2026-06-17 — Offer Form Status Row Alignment

Aligned the Verified/Unverified selector with the offer Status selector in the offer create/edit form.

---

## 2026-06-17 — Offer Form Verification and Lifecycle Selectors

Added selector-based controls on the offer form for verified/unverified state and offer lifecycle state: Active, Ending Soon, or Expired.

---

## 2026-06-17 — Offer and Notification Status Selectors

Added selector-based controls for offer verification state and notification request status changes.

---

## 2026-06-17 — Offer Expire Action

Added an offer expire action so a published offer can be retired before creating a replacement offer.

---

## Batch Update 12 — Manager Profile Routing, Offer Permissions, Notification Edit/Delete (2026-06-17)

### 1 — Manager profile/settings routing
Updated manager profile menu behavior so profile/settings opens the settings page instead of brands.

### 2 — Manager offer save/update permissions
Adjusted Firestore rules so manager can create/update offers with full access expectations.

### 3 — Notification request edit/delete for non-published offers
Added notification request actions to allow editing/deleting requests when the related offer is not published.

---

## Batch Update 11 — Offer Visibility and Notification Request Coverage (2026-06-17)

### 1 — Users see only self-created offers
Updated offers visibility for non-super-admin users so the offers list returns only records created by the signed-in user.

### 2 — Notification requests remain generated for all offers
Kept notification request creation flow applicable to offers regardless of publish state, so both published and unpublished offers are represented in notification requests.

---

## Batch Update 10 — Manager Role: No Brand Binding + Unrestricted Operations (2026-06-17)

### 1 — Manager registration and permissions adjustment
Updated manager behavior so brand is not required/visible during user registration, and managers can create unlimited offers across categories and manage cities, brands, and categories without subscription/package constraints.

---

## Batch Update 9 — Manager Role (Brand Admin Access Without Subscription) (2026-06-17)

### 1 — New manager role and access behavior
Added a new `manager` role that follows brand-admin style operational access (brand-scoped offers/cities/categories/notifications) but is excluded from subscription/package flows, plan UI, and subscription-gating requirements.

---

## Batch Update 8 — Users: Super Admin Role-Based Registration (2026-06-17)

### 1 — Register user action in Users module
Added a super-admin-only user registration flow from the Users section, including role-based account creation with Firebase Auth user provisioning and `users/{uid}` profile creation.

---

## Batch Update 7 — Offer Create: Admin Brand Selection Input (2026-06-17)

### 1 — Searchable brand selector on create/edit offer (admin/super admin)
In `OfferFormScreen`, the non-brand-admin brand field is updated from a basic dropdown to a searchable selector input so admins can quickly find and select any available brand while creating offers.

---

## Batch Update 6 — Design System: Reusable Widgets, Color Palette, Dark Theme, Doodle Background (2026-06-16)

### 1 — AppColors (centralized color palette)
New file `lib/core/theme/app_colors.dart` defines every color used in the app.  
Raw `Colors.*` values must never appear outside of `app_colors.dart`.  
Includes light/dark variants for all semantic roles (background, surface, border, text, muted text).

### 2 — AppTheme dark mode
`AppTheme.dark()` added. Both light and dark `ThemeData` are registered in `MaterialApp.router`.  
`AppTheme` color aliases now point to `AppColors` so existing call-sites keep working.

### 3 — themeModeProvider
`lib/core/theme/theme_providers.dart` exposes a `StateProvider<ThemeMode>` used by `MaterialApp`.  
A light/dark toggle `IconButton` is added to the desktop header (`_DesktopHeader`) and mobile app bar (`_TopBar`).

### 4 — AppTextView (reusable text widget)
`lib/core/widgets/app_text_view.dart` provides a standardised, theme-aware text widget with semantic style names (`AppTextStyle`).  
Named constructors: `.display()`, `.heading()`, `.title()`, `.body()`, `.label()`.  
All styles resolve through `ThemeData.textTheme` so they automatically adapt to light/dark and font changes.

### 5 — AppBackground (doodle background)
`lib/core/widgets/app_background.dart` renders a subtle `CustomPainter` doodle layer (scattered hollow circles, dots, arcs, crosshairs, hexagon outlines, corner accents).  
Applied to the content area of `AppShell` for both desktop and mobile layouts.  
Doodle color auto-adjusts between light and dark themes at very low opacity so it never distracts from content.

### 6 — app_shell dark-mode compatibility
All hardcoded `Colors.white`, `Colors.black54`, `Colors.black38` etc. in `app_shell.dart` replaced with theme-aware expressions using `AppColors` helpers and `ThemeData.colorScheme`.

---

## Batch Update 3 — Profile, Register Brand, Company Info (2026-06-16)

### 1 — Hide Firebase UID field in Register Brand
The "Existing Firebase UID" input field is no longer shown in the Register Brand form. The underlying controller remains so the `register()` call still passes an empty string (creating a fresh Auth user). This reduces confusion for admins.

### 2 — Brand ID visible to brand admin in profile menu
`_ProfileMenu` now reads `currentUserProvider` and shows the brand admin's `brandId` below their email with a copy-to-clipboard button. This lets brand admins quickly retrieve their ID when contacting support.

### 3 — Byte Cinch company info + logo
- Logo copied to `assets/images/bytecinch_logo.png` and declared in `pubspec.yaml`.
- Company constants (`byteCinchName`, `byteCinchWebsite`, `byteCinchEmail`, `byteCinchPhone`) added to `AppConstants`.
- `_CompanyInfoCard` widget added to `SettingsSeedScreen` (visible to super admin only) showing the full Byte Cinch contact card with logo, links, and phone.
- "Developed by Byte Cinch" attribution added to sidebar footer with logo.

---

## Batch Update 2 — Brand/Subscription/User/Seed UX (2026-06-16)

### 1 — Assign plan: only registered brands
`BrandSubscriptionFormScreen` now uses `registeredBrandsProvider` (new) which filters to brands with `ownerUserIds.isNotEmpty`. Unregistered brands no longer appear in the dropdown.

### 2 — Bell icon: popup with pending items
`_BellButton` in `app_shell.dart` replaced with `_BellPopup` — tapping the bell opens a `PopupMenuButton` listing each pending item with title, subtitle, and a navigate-to action. Super admin sees pending subscription requests + pending notification requests. Brand admin sees approved subscription requests.

### 3 — Firebase/Brand ID field readonly in register brand
A readonly "Brand ID (Firestore)" text field now appears below the brand name field when an existing brand is selected. It cannot be edited or cleared.

### 4 — Brand not found: must add brand first
If the user has typed a name with no matching existing brand and clicks Submit, the form shows an error with a "New Brand" action link. The suggestion area also shows a "Not found — add new brand" message when the query returns no matches.

### 5 — Users list: detail view icon
Each row in `UsersListScreen` now has an eye icon button that opens a modal bottom sheet with all user details (id, email, role, brandId, phone, isActive).

### 6 — Seed data: brand website/logo URLs + show logo in lists
`master_seed_data.dart` updated with `websiteUrl` and `logoUrl` (Clearbit CDN) for major international/national brands. Seed function writes these without overwriting existing non-empty values. `BrandsListScreen` leading avatar now shows the brand logo when `logoUrl` is non-empty.

---

## Batch Update — UX, Notifications, Payments & Real-time (2026-06-16)

### T1 — Subscription request form spacing
`SubscriptionRequestFormScreen` Column had no `SizedBox` gaps between form fields, causing visual overlapping. Added `14px` spacing between all fields.

### T2 — Offer form immediate loader
Submit button used `actionState.isLoading` which only becomes true after entering `AsyncValue.guard`. Added local `_isSubmitting` bool so the button disables and shows a spinner the instant the user taps.

### T3 — User activate/deactivate + inactive login block
- `LoginController.signIn` now reads the user document after Firebase login. If `isActive == false` it signs out immediately and throws `AppException` with a friendly deactivated message.
- `app_shell.dart` `_AccessContent` distinguishes inactive users from unconfigured admins and shows `_InactiveAccountView`.

### T4 — Bell icon (in-app notifications)
Added a bell `IconButton` with `Badge` to both `_DesktopHeader` (desktop) and `_TopBar` (mobile).
- Super admin: badge = count of pending `subscription_requests` + pending `notification_requests`.
- Brand admin: badge = count of their `approved` subscription requests (newly actioned items).
Tapping navigates to the relevant list screen.

### T5 / T11 — Approve plan request + real-time brand admin update
`SubscriptionActionsController.approveSubscriptionRequest` now:
1. Marks the request `approved` in Firestore.
2. Reads the requested pricing plan.
3. Creates or updates the brand's `brand_subscriptions` document with the new plan.
Because `activeBrandSubscriptionProvider` / `brandSubscriptionsProvider` use `StreamProvider`, the brand admin's screen updates automatically in real time.

### T6 — Scalable database structure
Added `schemaVersion` field guidance and `updatedAt` versioning notes to `docs/firestore-schema.md`. All future collection changes must include an `updatedAt` server timestamp so history is traceable.

### T7 — Payment submission with proof upload
- New `BrandPaymentFormScreen`: brand admins submit payment details (method, amount, reference, optional proof screenshot).
- Proof uploaded to `brand_payments/{brandId}/{timestamp}_{file}` in Firebase Storage.
- Storage rules updated to allow signed-in users to upload to `brand_payments/`.
- Route `/subscriptions/payments/new` added to router and brand admin allowed routes.
- `BrandPaymentsListScreen` shows "Submit Payment" FAB for brand admins.

### T8 — Lock verified payment deletion
`firestore.rules` `allow delete` for `brand_payments` now requires `paymentStatus != 'verified'`. Super admin delete button hidden from verified payments in the UI.

### T9 — Cancel unverified payments
`SubscriptionActionsController.cancelPayment` sets `paymentStatus = 'cancelled'`. Repository `cancelBrandPayment` method added. Super admin sees "Cancel" action for non-verified payments in the detail screen.

### T10 — Payment detail view (all statuses, both roles)
`BrandPaymentsListScreen` now shows a "view" icon for every payment regardless of status. `BrandPaymentVerifyScreen` (renamed logically to detail screen) shows: full payment info, proof image preview, and the verify/cancel form for super admin (hidden for brand admin or verified payments).

---

## Smooth Animations and Mobile Responsive UI (2026-06-15)

**Scope:** All screens — both Super Admin and Brand Admin.

**Animations:**
- `lib/core/widgets/animated_content.dart` (NEW): `AnimatedContent` wraps `.when()` results in `AnimatedSwitcher` with fade + subtle rise — eliminates the hard jump when data loads. `FadeIn` stagger-animates list items on first render.
- `lib/core/routing/app_router.dart`: All routes now use `CustomTransitionPage` with a 220ms fade transition — eliminates hard page cuts.
- All list screens' `.when()` blocks wrapped in `AnimatedContent`; `itemBuilder` entries wrapped in `FadeIn`.
- `MySubscriptionScreen`: usage limits now show animated `LinearProgressIndicator` bars with colour coding (green/orange/red).

**Mobile responsive layout:**
- `lib/core/widgets/screen_layout.dart` (NEW): `ScreenHeader` — responsive title + action bar (actions wrap below title on `< 600px` viewports). `ScreenScaffold` — standard responsive padding wrapper. `screenPadding()` — returns `14/16` (mobile), `18/20` (tablet), `24` (desktop).
- All 16 list screens migrated from `Padding(all:24) + Row(title, button)` to `ScreenScaffold + ScreenHeader`.
- All 11 form/detail screens: `const EdgeInsets.all(24)` replaced with `screenPadding(context)`.
- Dashboard `SliverPadding` uses `screenPadding(context)`.

---

## Pricing and Subscription Module (2026-06-15)

- Add pricing plans, brand subscriptions, usage tracking, manual payments, and subscription requests.
- Super Admin: manage plans, assign subscriptions, verify payments, view usage and requests.
- Brand Admin: view own subscription/usage/payments; request upgrade/renewal; limit enforcement on offers and notifications.
- `pricing_plans`, `brand_subscriptions`, `brand_usage`, `brand_payments`, `subscription_requests`
- Idempotent seed for free_trial, starter, growth, pro, enterprise plans.
- Manual payment flow only; no payment gateway.

---

## Documentation Consolidation (2026-06-15)

- Combined 20 scattered markdown files into `instructions.md`, this file, and `docs/bug-fixes.md`.
- Kept reference docs: `docs/firestore-schema.md`, `docs/firebase-setup.md`, `docs/logging.md`, `docs/BUILD_AND_RUN.md`.

---

## Initial MVP Build

- Flutter Web admin panel with Riverpod, Firebase Auth, Firestore, Storage, GoRouter, image picker.
- Material 3 admin theme (green primary, coral/saffron accents, Inter typography).
- Auth-guarded routing: login, dashboard, brands, offers, reports, cities, categories.
- Responsive shell: desktop sidebar, mobile drawer, top bar, logout.
- Clean Architecture for auth, cities, categories, brands, offers, reports, notifications.
- Firebase repositories for all MVP entities plus offer image upload and offer reports.
- Brand CRUD, Offer CRUD (filters, publish/verify/feature, image upload), Offer Reports.
- Cities CRUD and Categories CRUD with sidebar navigation.
- App-wide logging via `package:logging` and `AppLogger`.
- User-facing error mapping for Firebase/Firestore errors.
- Loading UX: delayed fade-in, `skipLoadingOnRefresh`, immediate empty lists for empty collections.
- Firestore and Storage security rule drafts; Firebase hosting config for web.

---

## Role-Aware Admin Panel

- Super admin, admin, and brand admin roles via `users/{uid}` and legacy `admins/{uid}`.
- Brand registration flow linking Auth users to master brand records.
- Brand-scoped Firestore access: brand admins see only their brand offers, assigned cities/categories, and categories they created.
- Owner/user metadata on brands, offers, cities, and categories.
- Users list screen and Settings master-data seed screen.
- Dashboard analytics widgets.
- Notification requests screen for brand-admin publish workflow.

---

## Brand Admin Offer and Notification Flow

- Offers support multiple `categoryIds` / `categoryNames` and `cityIds` / `cityNames` (primary `cityId` / `categoryId` kept for compatibility).
- Brand admins: brand field locked; offers stay pending/unpublished on create/edit.
- Publishing only through Notification Requests with confirmation and offer preview.
- Notification requests auto-created after offer creation; target selected city IDs.
- Brand admins query only their own notification requests.
- Published offers locked (view-only) for brand admins.
- Brand-admin category create; edit/delete only for categories they created.
- City list read-only for brand admins, filtered to brand-assigned cities.
- Brand selector hidden on offers page for brand admins.

---

## UI and Navigation Updates

- Removed MVP sidebar pill; role-specific subtitle (`Super Admin` / `Admin`).
- Removed dashboard quick actions and brand count card for brand admins.
- Brand profile moved to top profile menu; logout in profile menu with storage cleared on logout.
- Brand profile active status shown as read-only badge (not a switch).
- Brand admins cannot delete brand records.
- Offer form shows pending/published status clearly.

---

## Intentional Boundaries (Not Yet Built)

- FCM broadcast campaigns (`notification_campaigns` tooling).
- Mobile app, website, AI extraction, retailer dashboard.
- Payments, wallet, cashback, scraping, advanced recommendations.

---

## Next Recommended Tasks

1. Run `flutterfire configure` if still using placeholder Firebase config.
2. Seed cities/categories via Settings → Seed Master Data or Firebase Console.
3. Create admin user with `admins/{uid}` and matching `users/{uid}` profile.
4. Deploy `firestore.rules` and `storage.rules`.
5. Verify brand registration, notification-request publish, and role-scoped filtering on Chrome.

---

## Main File Map

| Area | Path |
|------|------|
| Bootstrap | `lib/main.dart`, `lib/firebase_options.dart` |
| Routing | `lib/core/routing/app_router.dart` |
| Shell | `lib/core/widgets/app_shell.dart` |
| Auth | `lib/features/auth/` |
| Brands | `lib/features/brands/` |
| Cities | `lib/features/cities/` |
| Categories | `lib/features/categories/` |
| Offers | `lib/features/offers/` |
| Reports | `lib/features/reports/` |
| Notifications | `lib/features/notifications/` |
| Users | `lib/features/users/` |
| Settings / seed | `lib/features/settings/` |
| Dashboard | `lib/features/dashboard/` |
| Rules | `firestore.rules`, `storage.rules` |

---

## Theme Notes

- Dense left navigation for repeated operations.
- White cards on soft workspace background.
- Rounded corners capped at 8px.
- Accent colors for status and priority only.
- No marketing hero layout inside admin screens.
