import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../access/presentation/widgets/user_features_field.dart';
import '../providers/user_registration_providers.dart';
import '../widgets/user_roles_field.dart';

class UserRegistrationScreen extends ConsumerStatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  ConsumerState<UserRegistrationScreen> createState() =>
      _UserRegistrationScreenState();
}

class _UserRegistrationScreenState
    extends ConsumerState<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedRoleIds = {UserRoles.mobileUser};
  final _selectedFeatureIds = <String>{
    ...AppFeatureSeedData.defaultFeaturesByRole[UserRoles.mobileUser]!,
  };
  String _brandId = '';
  var _notificationEnabled = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    await ref
        .read(userRegistrationProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          roles: _selectedRoleIds.toList(),
          brandId: _brandId,
          categoryIds: const [],
          cityIds: const [],
          brandIds: _brandId.isEmpty ? const [] : [_brandId],
          notificationEnabled: _notificationEnabled,
          isAdminEnabled: !UserRoleUtils.isMobileUserOnly(
            _selectedRoleIds.toList(),
          ),
          isMobileAppEnabled: true,
          featureIds: _selectedFeatureIds.toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final brands = ref.watch(activeBrandsProvider).value ?? const <Brand>[];
    final state = ref.watch(userRegistrationProvider);

    ref.listen(userRegistrationProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        showAppSuccess(context, next.value!);
        context.go('/users');
      }
      if (next.hasError) {
        showAppError(context, next.error, title: 'Registration Failed');
      }
    });

    if (!isSuperAdmin) {
      return const Center(
        child: AppCard(child: Text('Only super admins can register users.')),
      );
    }

    return SingleChildScrollView(
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
                    'Register user',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _requiredField(_fullNameController, 'Full name'),
                      ),
                      SizedBox(
                        width: 360,
                        child: _emailField(_emailController, 'Email'),
                      ),
                      SizedBox(
                        width: 360,
                        child: _phoneField(_phoneController, 'Phone number'),
                      ),
                      SizedBox(width: 360, child: _passwordField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  UserRolesField(
                    selectedRoleIds: _selectedRoleIds,
                    onChanged: (roles) => setState(() {
                      _selectedRoleIds
                        ..clear()
                        ..addAll(roles);
                      if (!UserRoleUtils.requiresBrand(
                        _selectedRoleIds.toList(),
                      )) {
                        _brandId = '';
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  UserFeaturesField(
                    selectedFeatureIds: _selectedFeatureIds,
                    onChanged: (features) => setState(
                      () => _selectedFeatureIds
                        ..clear()
                        ..addAll(features),
                    ),
                    onApplyRoleDefaults: () => setState(() {
                      _selectedFeatureIds
                        ..clear()
                        ..addAll(
                          FeatureAccessUtils.defaultFeatureIdsForRoles(
                            _selectedRoleIds,
                          ),
                        );
                    }),
                  ),
                  if (UserRoleUtils.requiresBrand(_selectedRoleIds.toList()))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: 360,
                        child: DropdownButtonFormField<String>(
                          initialValue: _brandId.isEmpty ? null : _brandId,
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
                  const SizedBox(height: 8),
                  AppListTileMaterial(
                    child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifications enabled'),
                    subtitle: const Text(
                      'Controls whether this user receives sale alerts.',
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
                        onPressed: state.isLoading ? null : _submit,
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Register User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _requiredField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? '$label is required' : null,
    );
  }

  TextFormField _emailField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) {
          return '$label is required';
        }
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  TextFormField _phoneField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) {
          return '$label is required';
        }
        if (text.length < 7) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  TextFormField _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Temporary password',
        helperText: 'Stored in Firebase Auth, not in Firestore.',
      ),
      validator: (value) {
        final text = value ?? '';
        if (text.length < 8) {
          return 'Use at least 8 characters';
        }
        if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
            !RegExp(r'[0-9]').hasMatch(text)) {
          return 'Use letters and numbers';
        }
        return null;
      },
    );
  }
}
