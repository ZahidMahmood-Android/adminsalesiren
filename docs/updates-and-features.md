# Updates and New Features

Log all new features, enhancements, and non-bug work here **before** implementing.

---

## 2026-06-17 — Notification Request Status Pill and Publish Selector

Restored notification request status visibility with Pending Review/Published labels and added a status selector for pending requests. Published requests are read-only with only the status pill and view action.

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
