import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/platform/browser_platform.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../data/master_seed_data.dart';
import '../providers/app_settings_providers.dart';
import '../providers/master_data_seed_providers.dart';

/// Byte Cinch company contact card — shown in super admin settings only.
class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developed by',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0D2333),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AppConstants.byteCinchLogoAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.business,
                          size: 52,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.byteCinchName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Technology Partner',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                _ContactRow(
                  icon: Icons.language_outlined,
                  label: 'Website',
                  value: AppConstants.byteCinchWebsite,
                  onTap: () => openInNewTab(AppConstants.byteCinchWebsite),
                ),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: AppConstants.byteCinchEmail,
                  onTap: () =>
                      openInNewTab('mailto:${AppConstants.byteCinchEmail}'),
                ),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: AppConstants.byteCinchPhone,
                  onTap: () =>
                      openInNewTab('tel:${AppConstants.byteCinchPhone}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white60),
            const SizedBox(width: 10),
            Text(
              '$label: ',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.lightBlueAccent,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.lightBlueAccent,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the seeded brand catalogue with logos for a quick visual confirmation.
class _BrandSeedPreview extends ConsumerWidget {
  const _BrandSeedPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    final seededIds = MasterSeedData.brands.map((r) => r[0]).toSet();

    return brandsAsync.maybeWhen(
      data: (allBrands) {
        final seeded = allBrands.where((b) => seededIds.contains(b.id)).toList()
          ..sort(
            (a, b) => MasterSeedData.brands
                .indexWhere((r) => r[0] == a.id)
                .compareTo(
                  MasterSeedData.brands.indexWhere((r) => r[0] == b.id),
                ),
          );

        if (seeded.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seeded brands (${seeded.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: seeded.map((brand) {
                final logoUrl = brand.logoUrl;
                return Tooltip(
                  message: brand.name,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.storefront_outlined),
                            )
                          : const Icon(
                              Icons.storefront_outlined,
                              color: Colors.black38,
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

bool _canSubmitBugReport(WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return false;
  }
  return FeatureAccessUtils.canSubmitBugReport(user);
}

class SettingsSeedScreen extends ConsumerWidget {
  const SettingsSeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(masterDataSeedActionsProvider);
    final controller = ref.read(masterDataSeedActionsProvider.notifier);

    return AppLoadingOverlay(
      isLoading: state.isLoading,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seed master data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create or safely update Firestore cities, categories, brands, roles, and app features.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : controller.seedCities,
                      icon: const Icon(Icons.location_city_outlined),
                      label: const Text('Seed Cities'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : controller.seedCategories,
                      icon: const Icon(Icons.category_outlined),
                      label: const Text('Seed Categories'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : controller.seedBrands,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Seed Brands'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : controller.seedRoles,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Seed Roles'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : controller.seedAppFeatures,
                      icon: const Icon(Icons.apps_outlined),
                      label: const Text('Seed App Features'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                state.when(
                  data: (message) => message == null
                      ? const SizedBox.shrink()
                      : Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                  loading: () => const AppLoader(),
                  error: (error, _) => AppErrorView(error: error),
                ),
                if (_canSubmitBugReport(ref)) ...[
                  const SizedBox(height: 28),
                  const _BugReportSettingsCard(),
                ],
                const SizedBox(height: 28),
                const _MobileAdsSettingsCard(),
                const _BrandSeedPreview(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),
                const _CompanyInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BugReportSettingsCard extends StatelessWidget {
  const _BugReportSettingsCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/bug-reports/submit'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.deepGreen.withValues(alpha: 0.14),
                AppColors.coral.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.deepGreen.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report a bug',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Something broken in the admin panel? Send details to the owner team.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.deepGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileAdsSettingsCard extends ConsumerWidget {
  const _MobileAdsSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mobileAdsSettingsProvider);
    final actionState = ref.watch(appSettingsActionsProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: settings.when(
          data: (value) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.ads_click_outlined),
            title: const Text('Mobile app ads'),
            subtitle: Text(
              value.enabled
                  ? 'Ads are enabled for mobile app users.'
                  : 'Ads are disabled for mobile app users.',
            ),
            value: value.enabled,
            onChanged: actionState.isLoading
                ? null
                : (enabled) => ref
                      .read(appSettingsActionsProvider.notifier)
                      .setMobileAdsEnabled(enabled),
          ),
          loading: () => const AppLoader(),
          error: (error, _) => AppErrorView(error: error),
        ),
      ),
    );
  }
}
