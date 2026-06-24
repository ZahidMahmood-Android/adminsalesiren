class AppFeature {
  const AppFeature({
    required this.id,
    required this.name,
    required this.platform,
    this.description = '',
    this.route = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String platform;
  final String description;
  final String route;
  final int sortOrder;
  final bool isActive;

  bool get isAdminPanel => platform == AppFeaturePlatforms.adminPanel;
  bool get isMobileApp => platform == AppFeaturePlatforms.mobileApp;
}

class AppFeaturePlatforms {
  const AppFeaturePlatforms._();

  static const adminPanel = 'admin_panel';
  static const mobileApp = 'mobile_app';
}
