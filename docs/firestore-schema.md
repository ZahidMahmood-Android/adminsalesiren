# Firestore Schema

## Collections

- `admins`
- `cities`
- `categories`
- `brands`
- `offers`
- `offer_reports`
- `notification_campaigns`
- `users`

## Admins

```json
{
  "email": "admin@salesiren.pk",
  "name": "Salesiren Admin",
  "role": "owner",
  "createdAt": "Timestamp"
}
```

## Cities

```json
{
  "id": "lahore",
  "name": "Lahore",
  "country": "Pakistan",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Categories

```json
{
  "id": "clothing",
  "name": "Clothing",
  "iconName": "checkroom",
  "isActive": true,
  "sortOrder": 1,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Brands

```json
{
  "id": "autoId",
  "name": "Khaadi",
  "logoUrl": "",
  "websiteUrl": "",
  "instagramUrl": "",
  "facebookUrl": "",
  "categoryIds": ["clothing"],
  "cityIds": ["lahore"],
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Offers

```json
{
  "id": "autoId",
  "title": "Flat 50% Off on Clothing",
  "description": "Flat 50% off on selected items.",
  "brandId": "",
  "brandName": "Khaadi",
  "categoryId": "clothing",
  "categoryName": "Clothing",
  "cityId": "lahore",
  "cityName": "Lahore",
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
  "aiConfidence": null,
  "createdBy": "FirebaseAuth uid",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## Offer Reports

```json
{
  "id": "autoId",
  "offerId": "",
  "userId": "",
  "reason": "Expired offer",
  "description": "",
  "status": "pending",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```
