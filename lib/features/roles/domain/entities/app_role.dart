class AppRole {
  const AppRole({
    required this.id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final int sortOrder;
  final bool isActive;
}
