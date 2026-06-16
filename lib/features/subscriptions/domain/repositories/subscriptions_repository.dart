import '../entities/brand_payment.dart';
import '../entities/brand_subscription.dart';
import '../entities/brand_usage.dart';
import '../entities/pricing_plan.dart';
import '../entities/subscription_request.dart';

abstract class SubscriptionsRepository {
  Stream<List<PricingPlan>> watchPricingPlans({bool publicOnly = false});
  Future<PricingPlan?> getPricingPlan(String id);
  Future<void> savePricingPlan(PricingPlan plan);
  Future<void> deletePricingPlan(String id);
  Future<int> seedPricingPlans();

  Stream<List<BrandSubscription>> watchBrandSubscriptions({String? brandId});
  Future<BrandSubscription?> getBrandSubscription(String id);
  Future<BrandSubscription?> getActiveSubscriptionForBrand(String brandId);
  Future<String> saveBrandSubscription(BrandSubscription subscription);

  Stream<List<BrandUsage>> watchBrandUsage({String? brandId});
  Future<BrandUsage> getOrCreateCurrentUsage(String brandId);
  Future<void> incrementUsage(
    String brandId, {
    int offersCreated = 0,
    int pushNotificationsRequested = 0,
    int featuredOffersUsed = 0,
  });

  Stream<List<BrandPayment>> watchBrandPayments({String? brandId});
  Future<BrandPayment?> getBrandPayment(String id);
  Future<String> saveBrandPayment(BrandPayment payment);
  Future<void> verifyBrandPayment(
    String id,
    String adminId, {
    String notes = '',
  });
  Future<void> cancelBrandPayment(String id);

  Stream<List<SubscriptionRequest>> watchSubscriptionRequests({
    String? brandId,
  });
  Future<String> saveSubscriptionRequest(SubscriptionRequest request);
  Future<void> updateSubscriptionRequest(
    String id, {
    required String status,
    String adminNotes = '',
  });

  Future<int> countActiveOffersForBrand(String brandId);

  BrandSubscription subscriptionFromPlan({
    required PricingPlan plan,
    required String brandId,
    required String adminId,
    String status = 'active',
    String paymentStatus = 'paid',
    String paymentMethod = 'manual',
    DateTime? startDate,
    DateTime? endDate,
    bool autoRenew = false,
    num discountPercent = 0,
    String discountNotes = '',
  });
}
