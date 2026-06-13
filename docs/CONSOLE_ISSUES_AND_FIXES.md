# Console Issues Found and Fixed

## Issues Identified

### 1. **CRITICAL: Dashboard `.value` Property Error** ❌ FIXED
**File:** [lib/features/dashboard/presentation/screens/dashboard_screen.dart](../lib/features/dashboard/presentation/screens/dashboard_screen.dart)

**Problem:**
The dashboard was using `.value` property on `AsyncValue<List<City>>` and `AsyncValue<List<Category>>`, but `AsyncValue` does not have a `.value` property. This would cause a runtime error like:
```
NoSuchMethodError: The getter 'value' was called on null
```

**Original Code:**
```dart
value: '${cities.value?.length ?? '-'} / ${categories.value?.length ?? '-'}',
```

**Fixed Code:**
Now properly uses `.when()` pattern:
```dart
value: cities.when(
  data: (citiesList) => categories.when(
    data: (categoriesList) => '${citiesList.length} / ${categoriesList.length}',
    loading: () => '-',
    error: (_, _) => '!',
  ),
  loading: () => '-',
  error: (_, _) => '!',
),
```

### 2. **Missing Error Messages on Dashboard Cards** ⚠️ IMPROVED
**File:** [lib/features/dashboard/presentation/screens/dashboard_screen.dart](../lib/features/dashboard/presentation/screens/dashboard_screen.dart)

**Problem:**
Metric cards displayed '!' on error but showed no error message. Users couldn't debug issues like:
- Firestore permission denied
- Network errors
- Missing admin document
- Composite index required

**Solution:**
Added tooltip support to `_MetricCard` to display error messages on hover:
```dart
_MetricCard(
  // ... other parameters
  errorMessage: brands.when(
    error: (error, _) => error.toString(),
    data: (_) => null,
    loading: () => null,
  ),
),
```

## Potential Runtime Issues After Login

### Issue 1: Admin Access Check
**Location:** [lib/core/widgets/app_shell.dart](../lib/core/widgets/app_shell.dart)

If user logs in but no admin document exists in Firestore, the app shows:
```
"Admin access is not configured"
```

**Resolution:**
Create a Firestore document at `admins/{userId}` for your admin user. See [Firebase Setup Guide](./firebase-setup.md#create-admin-document).

### Issue 2: Firestore Composite Indexes
**Location:** [lib/features/offers/data/repositories/firebase_offers_repository.dart](../lib/features/offers/data/repositories/firebase_offers_repository.dart)

When applying filters to offers (city, category, brand), Firestore requires composite indexes:

**Error Message:**
```
PlatformException(Error performing query, 
The query requires a composite index, ...)
```

**Resolution:**
When you first try to filter offers, Firestore will provide a direct link to create the needed composite index in Firebase Console. Click that link and follow the steps.

### Issue 3: Security Rules
**Location:** [firestore.rules](../firestore.rules)

Current rules require:
- User must be signed in to read/write offer reports
- Only admins can create/read brands, cities, categories
- Only admins can read unpublished offers

**If you see permission errors:**
- Verify admin document exists: `admins/{userId}`
- Check Firebase security rules are deployed

## Testing After Login

When you log in successfully, the dashboard should:
1. ✅ Display metric cards with counts (Brands, Published Offers, Pending Reports, Cities/Categories)
2. ✅ Show recent offers in a list
3. ✅ Display quick action buttons
4. ✅ All provider streams should be listening for real-time updates

**If you see errors on any metric:**
- Hover over the card to see the error tooltip
- Check Firebase Console for permission/index errors
- Check browser DevTools (F12) → Console tab for detailed error logs

## How to Debug Further

### 1. Browser Console (F12)
Shows real-time logs from Dart app:
```
[Bootstrap] Initializing Firebase
[Bootstrap] Firebase initialized
[LoginController] Login action submitted
[LoginController] Login action completed
[DashboardScreen] Watching brands
```

### 2. Firebase Console
- Check collection exists: `brands`, `offers`, `cities`, `categories`, `offer_reports`
- Check admin document exists at: `admins/{your-uid}`
- Check security rules are deployed

### 3. Flutter DevTools
Run:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Then in another terminal:
```bash
flutter run -d chrome --debug
```

## Configuration Checklist

Before deploying, ensure:
- [ ] Firebase project created
- [ ] Firebase Web SDK configured
- [ ] Admin user document created in `admins` collection
- [ ] Firestore collections exist (cities, categories, brands, offers, offer_reports)
- [ ] Firestore security rules deployed
- [ ] Firebase Cloud Messaging enabled (for notifications later)

## Related Documentation

- [Firebase Setup Guide](./firebase-setup.md)
- [Firestore Schema](./firestore-schema.md)
- [Architecture Notes](../AGENTS.md)
