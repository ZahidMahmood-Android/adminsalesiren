/// Maps persisted slugs/tags to human-readable labels for admin UI.
class DisplayLabelUtils {
  const DisplayLabelUtils._();

  static const _knownLabels = <String, String>{
    'new_offer': 'New Offer',
    'price_drop': 'Price Drop',
    'ending_soon': 'Ending Soon',
    'update': 'Update',
    'owner': 'Super Admin',
    'super_admin': 'Super Admin',
    'admin': 'Super Admin',
    'brand_admin': 'Brand Admin',
    'manager': 'Manager',
    'mobile_user': 'Mobile User',
    'percentage': 'Percentage',
    'flat': 'Flat Amount',
    'upto_percentage': 'Up to Percentage',
    'upto_amount': 'Up to Amount',
    'bundle': 'Bundle',
    'other': 'Other',
    'upgrade': 'Upgrade',
    'renew': 'Renew',
    'renewal': 'Renewal',
    'bank_transfer': 'Bank Transfer',
    'easypaisa': 'Easypaisa',
    'jazzcash': 'JazzCash',
    'cash': 'Cash',
    'basic': 'Basic',
    'standard': 'Standard',
    'advanced': 'Advanced',
    'store': 'Store',
    'online': 'Online',
    'marketplace': 'Marketplace',
    'pending_review': 'Pending Review',
    'pending': 'Pending',
    'reviewing': 'Reviewing',
    'resolved': 'Resolved',
    'published': 'Published',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'draft': 'Draft',
    'expired': 'Expired',
    'paused': 'Paused',
    'sent': 'Sent',
    'cancelled': 'Cancelled',
    'verified': 'Verified',
    'unverified': 'Unverified',
    'active': 'Active',
    'inactive': 'Inactive',
    'trial': 'Trial',
    'paid': 'Paid',
    'unpaid': 'Unpaid',
    'free_trial': 'Free Trial',
  };

  static String slug(String? value, {String fallback = ''}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return fallback;
    }
    final key = raw.toLowerCase();
    return _knownLabels[key] ?? _titleCaseSlug(raw);
  }

  static String slugs(
    Iterable<String> values, {
    String separator = ', ',
  }) {
    final labels = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(slug)
        .toList();
    if (labels.isEmpty) {
      return fallbackForEmptyList();
    }
    return labels.join(separator);
  }

  static String fallbackForEmptyList() => '—';

  static String _titleCaseSlug(String value) {
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
