class DiscoveredOfferStatuses {
  const DiscoveredOfferStatuses._();

  static const pendingReview = 'pending_review';
  static const converted = 'converted';
  static const rejected = 'rejected';
  static const duplicate = 'duplicate';
  static const sourceError = 'source_error';

  static const all = [
    pendingReview,
    converted,
    rejected,
    duplicate,
    sourceError,
  ];

  static String label(String status) => switch (status) {
    pendingReview => 'Pending Review',
    converted => 'Converted',
    rejected => 'Rejected',
    duplicate => 'Duplicate',
    sourceError => 'Source Error',
    _ => status,
  };
}

class DiscoveredOfferSourceTypes {
  const DiscoveredOfferSourceTypes._();

  static const website = 'website';
  static const instagram = 'instagram';
  static const facebook = 'facebook';

  static String label(String type) => switch (type) {
    website => 'Website',
    instagram => 'Instagram',
    facebook => 'Facebook',
    _ => type,
  };
}
