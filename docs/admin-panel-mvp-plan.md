# Admin Panel MVP Starter Plan

## 1. Recommended Project Folder Structure

```text
lib/
  core/
    constants/
    errors/
    extensions/
    routing/
    services/
    theme/
    utils/
    widgets/
  features/
    auth/
      data/
        datasources/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    dashboard/
      presentation/
        screens/
        widgets/
    cities/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    categories/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    brands/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    offers/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
    reports/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
  firebase_options.dart
  main.dart
```

## 2. Required Pubspec Dependencies

Core dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  firebase_core: ^3.10.0
  firebase_auth: ^5.4.0
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.4.0
  go_router: ^14.6.0
  intl: ^0.20.0
  image_picker: ^1.1.2
  uuid: ^4.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

Version numbers should be checked when the Flutter project is created.

## 3. Firebase Setup Steps

1. Create a Firebase project for Salesiren.
2. Add a Web app inside Firebase project settings.
3. Install and log in to the Firebase CLI.
4. Install FlutterFire CLI if needed.
5. Run `flutterfire configure` from the admin panel project.
6. Enable Firebase Auth email/password sign-in.
7. Create the first admin user manually in Firebase Auth.
8. Create Cloud Firestore in production mode.
9. Create Firebase Storage.
10. Add the Firestore collections needed by the MVP.
11. Deploy Firestore and Storage security rules after review.

## 4. Firestore Security Rules Draft

```text
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn()
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /cities/{cityId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /brands/{brandId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /offers/{offerId} {
      allow read: if resource.data.isPublished == true || isAdmin();
      allow write: if isAdmin();
    }

    match /offer_reports/{reportId} {
      allow create: if isSignedIn();
      allow read, update, delete: if isAdmin();
    }

    match /notification_campaigns/{campaignId} {
      allow read, write: if isAdmin();
    }

    match /users/{userId} {
      allow read, update: if isSignedIn() && request.auth.uid == userId;
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow delete: if isAdmin();
    }

    match /admins/{adminId} {
      allow read: if isSignedIn() && request.auth.uid == adminId;
      allow write: if false;
    }
  }
}
```

Storage draft:

```text
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn()
        && firestore.exists(/databases/(default)/documents/admins/$(request.auth.uid));
    }

    match /offers/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin()
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 5. Initial Models and Entities

`City`

```dart
class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

`Category`

```dart
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String iconName;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

`Brand`

```dart
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.websiteUrl,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.categoryIds,
    required this.cityIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String websiteUrl;
  final String instagramUrl;
  final String facebookUrl;
  final List<String> categoryIds;
  final List<String> cityIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

`Offer`

```dart
class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.cityId,
    required this.cityName,
    required this.discountText,
    required this.discountType,
    required this.discountValue,
    required this.imageUrl,
    required this.sourceUrl,
    required this.onlineUrl,
    required this.startDate,
    required this.endDate,
    required this.isVerified,
    required this.isPublished,
    required this.isFeatured,
    required this.aiConfidence,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String cityId;
  final String cityName;
  final String discountText;
  final String discountType;
  final num? discountValue;
  final String imageUrl;
  final String sourceUrl;
  final String onlineUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isVerified;
  final bool isPublished;
  final bool isFeatured;
  final num? aiConfidence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Data models should extend or map to entities and handle Firestore `Timestamp` conversion.

## 6. Repository Interfaces

```dart
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

abstract class CitiesRepository {
  Stream<List<City>> watchCities();
  Future<List<City>> getCities();
}

abstract class CategoriesRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();
}

abstract class BrandsRepository {
  Stream<List<Brand>> watchBrands();
  Future<Brand?> getBrand(String id);
  Future<String> createBrand(Brand brand);
  Future<void> updateBrand(Brand brand);
  Future<void> deleteBrand(String id);
}

abstract class OffersRepository {
  Stream<List<Offer>> watchOffers(OfferFilters filters);
  Future<Offer?> getOffer(String id);
  Future<String> createOffer(Offer offer);
  Future<void> updateOffer(Offer offer);
  Future<void> deleteOffer(String id);
  Future<void> publishOffer(String id, bool isPublished);
  Future<void> verifyOffer(String id, bool isVerified);
  Future<void> featureOffer(String id, bool isFeatured);
}

abstract class OfferImageRepository {
  Future<String> uploadOfferImage({
    required String offerId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  });
}
```

## 7. Implementation Plan

1. Create Flutter Web project scaffold.
2. Add dependencies and Flutter lints.
3. Configure Firebase with FlutterFire.
4. Add core error, routing, theme, and shared widget structure.
5. Implement auth domain/data/presentation layers.
6. Implement login screen and guarded app shell.
7. Add dashboard shell with sidebar and top bar.
8. Add City and Category read models/providers.
9. Add Brand entity/model/repository/use cases/providers.
10. Build Brands list and form screens.
11. Add Offer entity/model/repository/use cases/providers.
12. Build Offers list, filter controls, form, and details screen.
13. Add Firebase Storage image upload for offers.
14. Add publish, verify, and feature actions.
15. Draft and review Firestore and Storage rules.
16. Run formatting and analysis.
17. Add focused widget/unit tests after first implementation pass.
