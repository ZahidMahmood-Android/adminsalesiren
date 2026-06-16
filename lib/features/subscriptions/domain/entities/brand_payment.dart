class BrandPayment {
  const BrandPayment({
    required this.id,
    required this.brandId,
    required this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionReference,
    required this.proofImageUrl,
    required this.paidAt,
    required this.verifiedByAdminId,
    required this.verifiedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandId;
  final String subscriptionId;
  final num amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionReference;
  final String proofImageUrl;
  final DateTime? paidAt;
  final String verifiedByAdminId;
  final DateTime? verifiedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
