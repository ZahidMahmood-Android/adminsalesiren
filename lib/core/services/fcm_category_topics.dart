/// FCM topic names for category-based push notifications.
class FcmCategoryTopics {
  const FcmCategoryTopics._();

  static const prefix = 'category_';

  static String forCategoryId(String categoryId) {
    final sanitized = categoryId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-_.~%]'), '_');
    return '$prefix$sanitized';
  }

  static String primaryTopicForCategoryIds(List<String> categoryIds) {
    if (categoryIds.isEmpty) return '';
    return forCategoryId(categoryIds.first);
  }
}
