# Firestore Schema

Current schema for the admin panel MVP. See `firestore.rules` for access control.

---

## Scalability & Versioning Guidelines (added 2026-06-16)

Rules that keep schema changes backwards-compatible and non-breaking for existing users:

1. **Never remove a field** — mark it deprecated with a comment instead and stop writing it. Old clients silently ignore unknown fields.
2. **Always include `updatedAt`** — every document must carry `updatedAt: serverTimestamp()` so listeners can detect changes without re-reading the whole collection.
3. **Add `schemaVersion: int`** to long-lived documents (e.g. `brand_subscriptions`, `pricing_plans`). Increment on breaking shape changes. Readers check the version before parsing.
4. **Use subcollections for unbounded lists** — e.g. `brand_payments/{paymentId}` instead of arrays in `brand_subscriptions`. Arrays cannot be partially queried.
5. **Feature flags in documents** — add boolean fields (`canUseFeaturedOffers`, `canExportAnalytics`, etc.) to existing plan documents rather than creating new collection types. Default missing flags to `false` in code.
6. **Soft-deletes where history matters** — set `isDeleted: true` instead of `doc.delete()` for payments, subscriptions, or audit-sensitive records.
7. **Avoid deeply nested maps** — keep top-level fields flat for Firestore index efficiency. Nest only for grouped metadata (e.g. `bankDetails: { name, account }`).

---

## Collections

- `admins`
- `users`
- `cities`
- `categories`
- `brands`
- `offers`
- `offer_reports`
- `notification_requests`
- `notification_campaigns` (future broadcast tooling)
- `pricing_plans`
- `brand_subscriptions`
- `brand_usage`
- `brand_payments`
- `subscription_requests`

## Admins

Legacy super-admin marker. A document at `admins/{uid}` grants full admin-panel access together with or in place of a `users/{uid}` profile.

```json
{
  "email": "admin@salesiren.pk",
  "name": "Salesiren Admin",
  "role": "owner",
  "createdAt": "Timestamp"
}
```

## Users

Profile and role metadata for admin-panel and mobile users.

```json
{
  "email": "brand@example.com",
  "displayName": "Brand Admin",
  "fullName": "Brand Admin",
  "phoneNumber": "",
  "role": "super_admin",
  "brandId": "",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

Roles: `super_admin`, `brand_admin`, `mobile_user`. Brand admins must have a non-empty `brandId`.

## Cities

```json
{
  "id": "lahore",
  "name": "Lahore",
  "country": "Pakistan",
  "countryCode": "PK",
  "countryName": "Pakistan",
  "province": "Punjab",
  "slug": "lahore",
  "isActive": true,
  "isComingSoon": false,
  "sortOrder": 1,
  "searchKeywords": ["lahore"],
  "userId": "",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Categories

```json
{
  "id": "clothing",
  "name": "Clothing",
  "slug": "clothing",
  "description": "",
  "iconName": "checkroom",
  "colorHex": "",
  "isActive": true,
  "isFeatured": false,
  "sortOrder": 1,
  "searchKeywords": ["clothing"],
  "userId": "",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

Brand admins may create categories with their own `userId`; only they can edit/delete those records.

## Brands

```json
{
  "id": "autoId",
  "name": "Khaadi",
  "slug": "khaadi",
  "description": "",
  "logoUrl": "",
  "websiteUrl": "",
  "instagramUrl": "",
  "facebookUrl": "",
  "categoryIds": ["clothing"],
  "cityIds": ["lahore"],
  "primaryCategoryId": "clothing",
  "type": "brand",
  "isActive": true,
  "isVerified": true,
  "isFeatured": false,
  "sortOrder": 0,
  "searchKeywords": ["khaadi"],
  "businessContactName": "",
  "businessContactPhone": "",
  "businessContactEmail": "",
  "marketingEmail": "",
  "address": "",
  "approvalStatus": "approved",
  "ownerUserIds": [],
  "createdByAdminId": "",
  "userId": "",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Offers

Primary `cityId` / `categoryId` fields remain for compatibility. Multi-select uses `cityIds`, `cityNames`, `categoryIds`, and `categoryNames`.

```json
{
  "id": "autoId",
  "title": "Flat 50% Off on Clothing",
  "description": "Flat 50% off on selected items.",
  "brandId": "",
  "brandName": "Khaadi",
  "categoryId": "clothing",
  "categoryName": "Clothing",
  "categoryIds": ["clothing"],
  "categoryNames": ["Clothing"],
  "cityId": "lahore",
  "cityName": "Lahore",
  "cityIds": ["lahore"],
  "cityNames": ["Lahore"],
  "discountText": "Flat 50% Off",
  "discountType": "percentage",
  "discountValue": 50,
  "imageUrl": "",
  "sourceUrl": "",
  "onlineUrl": "",
  "startDate": "Timestamp",
  "endDate": "Timestamp",
  "isVerified": true,
  "isPublished": true,
  "isFeatured": false,
  "status": "published",
  "approvalStatus": "approved",
  "approvalNotes": "",
  "approvedBy": "",
  "approvedAt": "Timestamp",
  "aiConfidence": null,
  "createdBy": "FirebaseAuth uid",
  "createdByUserId": "FirebaseAuth uid",
  "createdByRole": "super_admin",
  "viewCount": 0,
  "saveCount": 0,
  "shareCount": 0,
  "clickCount": 0,
  "reportCount": 0,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

Brand-admin created offers typically start with `status: pending_review`, `approvalStatus: pending`, and `isPublished: false`.

## Offer Reports

```json
{
  "id": "autoId",
  "offerId": "",
  "brandId": "",
  "userId": "",
  "reason": "Expired offer",
  "description": "",
  "status": "pending",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Notification Requests

Used when brand admins request publishing an offer to mobile users.

```json
{
  "id": "autoId",
  "title": "New offer from Khaadi",
  "body": "Flat 50% off on selected items.",
  "topic": "",
  "type": "offer_publish",
  "data": {
    "offerId": ""
  },
  "status": "pending",
  "brandId": "",
  "offerId": "",
  "requestedByUserId": "",
  "targetCityIds": ["lahore"],
  "targetCategoryIds": ["clothing"],
  "adminNotes": "",
  "approvedBy": "",
  "approvedAt": "Timestamp",
  "sentAt": "Timestamp",
  "sentCount": 0,
  "openCount": 0,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Notification Campaigns

Reserved for future broadcast tooling. Super admins only.

```json
{
  "id": "autoId",
  "title": "",
  "body": "",
  "topic": "",
  "status": "draft",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```
