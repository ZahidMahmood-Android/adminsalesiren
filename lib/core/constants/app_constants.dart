class AppConstants {
  const AppConstants._();

  static const appName = 'Sale Siren';
  static const appLogoAsset = 'assets/images/salesiren_parrot_logo.png';
  static const appTaglineLogoAsset =
      'assets/images/salesiren_text_tagline_logo.png';
  static const defaultCityId = 'lahore';
  static const defaultCityName = 'City';
  static const supportEmail = 'admin@salesiren.pk';

  // Manual payment bank account details (update before going live).
  static const bankName = 'HBL – Habib Bank Limited';
  static const bankAccountTitle = 'Salesiren Technologies (Pvt) Ltd';
  static const bankAccountNumber = '0123-4567890-01';
  static const bankIban = 'PK00HABB0000000000000000';
  static const easypaisaAccount = '03XX-XXXXXXX';
  static const jazzcashAccount = '03XX-XXXXXXX';

  // Byte Cinch — company that developed this platform.
  static const byteCinchName = 'Byte Cinch';
  static const byteCinchWebsite = 'https://bytecinch.com';
  static const byteCinchEmail = 'zahid@bytecinch.com';
  static const byteCinchPhone = '+923260766794';
  static const byteCinchLogoAsset = 'assets/images/bytecinch_logo.png';

  static const offerShareBaseUrl = 'https://salesiren.bytecinch.com/o';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bytecinch.salesiren';

  static String offerShareUrl(String offerId) => '$offerShareBaseUrl/$offerId';
}
