import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../access/presentation/widgets/user_features_field.dart';
import '../providers/user_management_providers.dart';
import '../widgets/user_access_toggles.dart';
import '../widgets/user_catalog_preferences_field.dart';
import '../widgets/user_roles_field.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  const UserEditScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedRoleIds = <String>{};
  final _selectedFeatureIds = <String>{};
  String _brandId = '';
  final _categoryIds = <String>{};
  final _cityIds = <String>{};
  final _brandIds = <String>{};
  var _isActive = true;
  var _notificationEnabled = true;
  var _isAdminEnabled = false;
  var _isMobileAppEnabled = true;
  var _hydrated = false;
  AppUser? _loadedUser;

  void _onRolesChanged(Set<String> roles) {
    setState(() {
      _selectedRoleIds
        ..clear()
        ..addAll(roles);
      if (!UserRoleUtils.requiresBrand(_selectedRoleIds.toList())) {
        _brandId = '';
      }
      syncUserAccessFlagsWithRoles(
        selectedRoleIds: _selectedRoleIds,
        currentIsAdminEnabled: _isAdminEnabled,
        currentIsMobileAppEnabled: _isMobileAppEnabled,
        apply: (isAdminEnabled, isMobileAppEnabled) {
          _isAdminEnabled = isAdminEnabled;
          _isMobileAppEnabled = isMobileAppEnabled;
        },
      );
    });
  }

  void _onFeaturesChanged(Set<String> features) {
    setState(() {
      _selectedFeatureIds
        ..clear()
        ..addAll(features);
    });
  }

  void _applyRoleDefaultFeatures() {
    setState(() {
      _selectedFeatureIds
        ..clear()
        ..addAll(
          FeatureAccessUtils.defaultFeatureIdsForRoles(_selectedRoleIds),
        );
    });
  }

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
    _loadedUser = user;
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phoneNumber;
    _selectedRoleIds
      ..clear()
      ..addAll(UserRoleUtils.normalizeRoles(user.roles));
    _selectedFeatureIds
      ..clear()
      ..addAll(
        UserRoleUtils.isMobileUserOnly(user.roles)
            ? AppFeatureIds.allMobile
            : user.featureIds.isNotEmpty
            ? user.featureIds
            : FeatureAccessUtils.defaultFeatureIdsForRoles(user.roles),
      );
    _brandId = user.brandId;
    _categoryIds
      ..clear()
      ..addAll(user.categoryIds);
    _cityIds
      ..clear()
      ..addAll(user.cityIds);
    _brandIds
      ..clear()
      ..addAll(user.brandIds);
    _isActive = user.isActive;
    _notificationEnabled = user.notificationEnabled;
    _isAdminEnabled = user.isAdminEnabled;
    _isMobileAppEnabled = user.isMobileAppEnabled;
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRoleIds.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Select at least one role.');
      }
      return;
    }
    if (UserRoleUtils.requiresBrand(_selectedRoleIds.toList()) &&
        _brandId.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Please select a brand.');
      }
      return;
    }

    if (_selectedFeatureIds.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Select at least one feature.');
      }
      return;
    }

    final fullName = _fullNameController.text.trim();
    await ref
        .read(userManagementActionsProvider.notifier)
        .updateUser(
          (_loadedUser ??
                  AppUser(id: widget.userId, email: '', displayName: fullName))
              .copyWith(
                fullName: fullName,
                displayName: fullName,
                phoneNumber: _phoneController.text.trim(),
                roles: _selectedRoleIds.toList(),
                brandId: UserRoleUtils.requiresBrand(_selectedRoleIds.toList())
                    ? _brandId
                    : '',
                categoryIds: _categoryIds.toList(),
                cityIds: _cityIds.toList(),
                brandIds: _resolvedBrandIds(),
                isActive: _isActive,
                notificationEnabled: _notificationEnabled,
                isAdminEnabled: _isAdminEnabled,
                isMobileAppEnabled: _isMobileAppEnabled,
                featureIds: _selectedFeatureIds.toList(),
              ),
        );

    final actionState = ref.read(userManagementActionsProvider);
    if (actionState.hasError && mounted) {
      await showAppError(
        context,
        actionState.error,
        title: 'Could Not Save User',
      );
      return;
    }
    if (mounted) {
      context.go('/users');
    }
  }

  List<String> _resolvedBrandIds() {
    final ids = {..._brandIds};
    if (_brandId.isNotEmpty) {
      ids.add(_brandId);
    }
    return ids.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isOwnerProvider);
    final userAsync = ref.watch(managedUserByIdProvider(widget.userId));
    final brands = ref.watch(activeBrandsProvider).value ?? const <Brand>[];
    final actionState = ref.watch(userManagementActionsProvider);

    ref.listen(userManagementActionsProvider, (previous, next) {
      if (next.hasError && context.mounted) {
        showAppError(context, next.error, title: 'Could Not Save User');
      }
    });

    if (!isOwner) {
      return const Center(
        child: AppErrorView(message: 'Only owners can edit users.'),
      );
    }

    return userAsync.when(
      loading: () => const AppLoader(),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(managedUserByIdProvider(widget.userId)),
      ),
      data: (user) {
        if (user == null) {
          return AppErrorView(
            message: 'User not found.',
            onRetry: () => context.go('/users'),
          );
        }

        _hydrate(user);

        return AppLoadingOverlay(
          isLoading: actionState.isLoading,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit user',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          initialValue: user.email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 360,
                              child: TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                ),
                                validator: (value) =>
                                    (value ?? '').trim().isEmpty
                                    ? 'Full name is required'
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: 360,
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        UserRolesField(
                          selectedRoleIds: _selectedRoleIds,
                          onChanged: _onRolesChanged,
                        ),
                        const SizedBox(height: 16),
                        UserFeaturesField(
                          selectedFeatureIds: _selectedFeatureIds,
                          onChanged: _onFeaturesChanged,
                          onApplyRoleDefaults: _applyRoleDefaultFeatures,
                        ),
                        if (UserRoleUtils.requiresBrand(
                          _selectedRoleIds.toList(),
                        ))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: 360,
                              child: DropdownButtonFormField<String>(
                                initialValue: _brandId.isEmpty
                                    ? null
                                    : _brandId,
                                decoration: const InputDecoration(
                                  labelText: 'Brand',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                                items: brands
                                    .map(
                                      (brand) => DropdownMenuItem(
                                        value: brand.id,
                                        child: Text(brand.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _brandId = value ?? ''),
                                validator: (value) {
                                  if (UserRoleUtils.requiresBrand(
                                        _selectedRoleIds.toList(),
                                      ) &&
                                      (value == null || value.isEmpty)) {
                                    return 'Brand is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        UserCatalogPreferencesField(
                          selectedCategoryIds: _categoryIds,
                          selectedCityIds: _cityIds,
                          selectedBrandIds: _brandIds,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        UserAccessToggles(
                          selectedRoleIds: _selectedRoleIds,
                          isAdminEnabled: _isAdminEnabled,
                          isMobileAppEnabled: _isMobileAppEnabled,
                          onAdminChanged: (value) =>
                              setState(() => _isAdminEnabled = value),
                          onMobileChanged: (value) =>
                              setState(() => _isMobileAppEnabled = value),
                        ),
                        AppListTileMaterial(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Account active'),
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                        ),
                        AppListTileMaterial(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Notifications enabled'),
                            subtitle: const Text(
                              'Updates notificationEnabled in Firestore.',
                            ),
                            value: _notificationEnabled,
                            onChanged: (value) =>
                                setState(() => _notificationEnabled = value),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/users'),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: actionState.isLoading ? null : _submit,
                              icon: AppAsyncButtonIcon(
                                isLoading: actionState.isLoading,
                                icon: Icons.save_outlined,
                              ),
                              label: const Text('Save User'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
