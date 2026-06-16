import '../entities/brand_subscription.dart';
import '../entities/brand_usage.dart';

class SubscriptionLimitChecker {
  const SubscriptionLimitChecker._();

  static const _upgradeHint =
      'Request an upgrade or renewal from My Subscription.';

  static String? offerCreationBlockReason({
    required BrandSubscription? subscription,
    required BrandUsage? usage,
    required int activeOfferCount,
  }) {
    if (subscription == null || !subscription.isUsable) {
      return 'No active subscription. $_upgradeHint';
    }
    if (usage != null &&
        usage.offersCreated >= subscription.offerLimitPerMonth) {
      return 'Monthly offer limit reached (${subscription.offerLimitPerMonth}). $_upgradeHint';
    }
    if (activeOfferCount >= subscription.activeOfferLimit) {
      return 'Active offer limit reached (${subscription.activeOfferLimit}). $_upgradeHint';
    }
    return null;
  }

  static String? pushNotificationBlockReason({
    required BrandSubscription? subscription,
    required BrandUsage? usage,
  }) {
    if (subscription == null || !subscription.isUsable) {
      return 'No active subscription. $_upgradeHint';
    }
    if (!subscription.canRequestPushNotifications) {
      return 'Push notifications are not included in your plan. $_upgradeHint';
    }
    if (usage != null &&
        usage.pushNotificationsRequested >=
            subscription.pushNotificationLimitPerMonth) {
      return 'Monthly push notification limit reached (${subscription.pushNotificationLimitPerMonth}). $_upgradeHint';
    }
    return null;
  }

  static String? featuredOfferBlockReason({
    required BrandSubscription? subscription,
    required BrandUsage? usage,
  }) {
    if (subscription == null || !subscription.isUsable) {
      return 'No active subscription. $_upgradeHint';
    }
    if (!subscription.canUseFeaturedOffers) {
      return 'Featured offers are not included in your plan. $_upgradeHint';
    }
    if (usage != null &&
        usage.featuredOffersUsed >= subscription.featuredOfferLimitPerMonth) {
      return 'Monthly featured offer limit reached (${subscription.featuredOfferLimitPerMonth}). $_upgradeHint';
    }
    return null;
  }
}
