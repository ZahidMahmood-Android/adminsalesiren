import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_info_row.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../roles/domain/entities/app_role.dart';
import '../../../roles/presentation/providers/role_providers.dart';
import '../../../users/presentation/widgets/user_catalog_preferences_field.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _categoryIds = <String>{};
  final _cityIds = <String>{};
  final _brandIds = <String>{};
  var _notificationEnabled = true;
  var _hydrated = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _hydrate(AppUser user) {
    if (_hydrated) {
      return;
    }
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phoneNumber;
    _categoryIds
      ..clear()
      ..addAll(user.categoryIds);
    _cityIds
      ..clear()
      ..addAll(user.cityIds);
    _brandIds
      ..clear()
      ..addAll(user.brandIds);
    _notificationEnabled = user.notificationEnabled;
    _hydrated = true;
  }

  Future<void> _submit(AppUser user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = user.copyWith(
      fullName: _fullNameController.text.trim(),
      displayName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      categoryIds: _categoryIds.toList(),
      cityIds: _cityIds.toList(),
      brandIds: _resolvedBrandIds(user),
      notificationEnabled: _notificationEnabled,
    );

    await ref.read(profileUpdateProvider.notifier).save(updated);

    final error = ref.read(profileUpdateProvider).error;
    if (error != null && mounted) {
      await showAppError(context, error, title: 'Could Not Save Profile');
      return;
    }

    if (mounted) {
      showAppSuccess(context, 'Profile updated successfully.');
      setState(() => _hydrated = false);
    }
  }

  List<String> _resolvedBrandIds(AppUser user) {
    final ids = {..._brandIds};
    if (user.brandId.isNotEmpty) {
      ids.add(user.brandId);
    }
    return ids.toList();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final saveState = ref.watch(profileUpdateProvider);
    final rolesCatalog = ref.watch(assignableRolesProvider);
    final brands = ref.watch(activeBrandsProvider).value ?? const <Brand>[];

    return profileAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => Center(child: AppErrorView(error: error)),
      data: (user) {
        if (user == null) {
          return const Center(
            child: AppErrorView(message: 'We could not load your profile.'),
          );
        }

        _hydrate(user);

        final roleLabels = _roleLabels(user.roles, rolesCatalog);
        final assignedBrand = _findBrand(brands, user.brandId);
        final displayName = user.fullName.isNotEmpty
            ? user.fullName
            : user.displayName.isNotEmpty
            ? user.displayName
            : user.email;

        return AppLoadingOverlay(
          isLoading: saveState.isLoading,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                AppAvatar(name: displayName, radius: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                AppStatusChip(
                                  status: user.isActive ? 'active' : 'inactive',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const AppInfoRow.divider(),
                            AppInfoRow(label: 'User ID', value: user.id),
                            AppInfoRow(
                              label: 'Roles',
                              valueWidget: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: roleLabels
                                    .map((label) => Chip(label: Text(label)))
                                    .toList(),
                              ),
                            ),
                            if (UserRoleUtils.requiresBrand(user.roles))
                              AppInfoRow(
                                label: 'Assigned brand',
                                value: assignedBrand?.name ?? user.brandId,
                              ),
                            AppInfoRow(
                              label: 'Admin access',
                              value: user.effectiveIsAdminEnabled
                                  ? 'Yes'
                                  : 'No',
                            ),
                            AppInfoRow(
                              label: 'Mobile access',
                              value: user.effectiveIsMobileAppEnabled
                                  ? 'Yes'
                                  : 'No',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact details',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: user.email,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Full name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppListTileMaterial(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Notifications enabled'),
                                subtitle: const Text(
                                  'Receive sale alerts and notification updates.',
                                ),
                                value: _notificationEnabled,
                                onChanged: (value) => setState(
                                  () => _notificationEnabled = value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: UserCatalogPreferencesField(
                          selectedCategoryIds: _categoryIds,
                          selectedCityIds: _cityIds,
                          selectedBrandIds: _brandIds,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: saveState.isLoading
                              ? null
                              : () => _submit(user),
                          icon: AppAsyncButtonIcon(
                            isLoading: saveState.isLoading,
                            icon: Icons.save_outlined,
                          ),
                          label: const Text('Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _roleLabels(List<String> roleSlugs, List<AppRole> catalog) {
    final labels = <String>[];
    for (final slug in UserRoleUtils.normalizeRoles(roleSlugs)) {
      final match = catalog.where((role) => role.id == slug);
      if (match.isNotEmpty) {
        labels.add(match.first.name);
        continue;
      }
      labels.add(DisplayLabelUtils.slug(slug));
    }
    return labels;
  }

  Brand? _findBrand(List<Brand> brands, String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final brand in brands) {
      if (brand.id == id) {
        return brand;
      }
    }
    return null;
  }
}
