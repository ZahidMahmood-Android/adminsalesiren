import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../domain/entities/brand.dart';
import '../providers/brand_providers.dart';
import '../providers/brand_registration_providers.dart';
import '../widgets/selection_block.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class RegisterBrandScreen extends ConsumerStatefulWidget {
  const RegisterBrandScreen({super.key});

  @override
  ConsumerState<RegisterBrandScreen> createState() =>
      _RegisterBrandScreenState();
}

class _RegisterBrandScreenState extends ConsumerState<RegisterBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  final _marketingEmail = TextEditingController();
  final _loginUserId = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _loginName = TextEditingController();
  final _loginPhone = TextEditingController();
  final _notes = TextEditingController();
  final _categoryIds = <String>{};
  final _cityIds = <String>{};
  Brand? _selectedBrand;
  var _type = 'brand';
  var _primaryCategoryId = '';

  @override
  void dispose() {
    _name.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _marketingEmail.dispose();
    _loginUserId.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _loginName.dispose();
    _loginPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBrand == null) {
      if (mounted) {
        showAppError(
          context,
          null,
          title: 'Select an Existing Brand',
          message:
              'Please search for and select the brand from the suggestion list. '
              'If the brand is not listed yet, add it as a new brand first, '
              'then return here to register it.',
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_categoryIds.isEmpty ||
        _cityIds.isEmpty ||
        _primaryCategoryId.isEmpty) {
      if (mounted) {
        showAppError(
          context,
          null,
          message:
              'Please select at least one city, category, and primary category.',
        );
      }
      return;
    }
    await ref
        .read(brandRegistrationProvider.notifier)
        .register(
          existingBrandId: _selectedBrand?.id,
          brandName: _name.text.trim(),
          brandType: _type,
          primaryCategoryId: _primaryCategoryId,
          categoryIds: _categoryIds.toList(),
          cityIds: _cityIds.toList(),
          businessContactName: _contactName.text.trim(),
          businessContactPhone: _contactPhone.text.trim(),
          businessContactEmail: _contactEmail.text.trim(),
          marketingEmail: _marketingEmail.text.trim(),
          loginUserId: _loginUserId.text.trim(),
          loginEmail: _loginEmail.text.trim(),
          loginPassword: _loginPassword.text,
          loginFullName: _loginName.text.trim(),
          loginPhone: _loginPhone.text.trim(),
          notes: _notes.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final cities = ref.watch(citiesProvider);
    final brands = ref.watch(brandsProvider).value ?? const <Brand>[];
    final state = ref.watch(brandRegistrationProvider);
    final query = _name.text.trim().toLowerCase();
    final matches = query.isEmpty || _selectedBrand != null
        ? const <Brand>[]
        : brands
              .where(
                (brand) =>
                    brand.name.toLowerCase().contains(query) ||
                    brand.id.toLowerCase().contains(query) ||
                    brand.searchKeywords.any((item) => item.contains(query)),
              )
              .take(6)
              .toList();

    ref.listen(brandRegistrationProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        showAppSuccess(context, next.value!);
        context.go('/brands');
      }
      if (next.hasError) {
        showAppError(context, next.error, title: 'Registration Failed');
      }
    });

    final isManager = ref.watch(isManagerProvider);
    if (isManager) {
      return Center(
        child: AppCard(
          child: Text(
            'Managers can add brands from Brands → New brand, but cannot '
            'register a brand with a login account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return AppLoadingOverlay(
      isLoading: state.isLoading,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register brand',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: 'Brand name',
                        helperText: _selectedBrand == null
                            ? 'Search and select an existing brand to register.'
                            : null,
                        suffixIcon: _selectedBrand == null
                            ? null
                            : IconButton(
                                tooltip: 'Clear selected brand',
                                onPressed: () => setState(() {
                                  _selectedBrand = null;
                                  _name.clear();
                                }),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      readOnly: _selectedBrand != null,
                      onChanged: (_) => setState(() {
                        _selectedBrand = null;
                      }),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Brand name is required'
                          : null,
                    ),
                    // Readonly brand ID field — shown only when a brand is selected.
                    if (_selectedBrand != null) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _selectedBrand!.id,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Brand ID',
                          prefixIcon: Icon(Icons.lock_outline, size: 18),
                          helperText:
                              'Auto-filled from the selected brand. Cannot be changed.',
                        ),
                      ),
                    ],
                    // Matching suggestions or "not found" message.
                    if (matches.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: matches.map((brand) {
                            return AppListTileMaterial(
                              child: ListTile(
                                dense: true,
                                leading: AppAvatar(
                                  name: brand.name,
                                  imageUrl: brand.logoUrl,
                                  radius: 14,
                                ),
                                title: Text(brand.name),
                                subtitle: Text('ID: ${brand.id}'),
                                onTap: () => setState(() {
                                  _selectedBrand = brand;
                                  _name.text = brand.name;
                                  _type = brand.type;
                                  _primaryCategoryId = brand.primaryCategoryId;
                                  _categoryIds
                                    ..clear()
                                    ..addAll(brand.categoryIds);
                                  _cityIds
                                    ..clear()
                                    ..addAll(brand.cityIds);
                                  _contactName.text = brand.businessContactName;
                                  _contactPhone.text =
                                      brand.businessContactPhone;
                                  _contactEmail.text =
                                      brand.businessContactEmail;
                                  _marketingEmail.text = brand.marketingEmail;
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else if (query.isNotEmpty && _selectedBrand == null) ...[
                      // No matches — guide admin to add the brand first.
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          border: Border.all(color: const Color(0xFFFFCA28)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFFF57F17),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No brand found matching "$query".\n'
                                  'Add it as a new brand first, then come back to register.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context.go('/brands/new'),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New Brand'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF57F17),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Brand type',
                      ),
                      items:
                          const [
                                'brand',
                                'store',
                                'mall',
                                'restaurant',
                                'marketplace',
                                'bank',
                                'electronics',
                                'pharmacy',
                                'travel',
                                'other',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _type = value ?? 'brand'),
                    ),
                    const SizedBox(height: 12),
                    SelectionBlock(
                      title: 'Cities',
                      items: cities,
                      selectedIds: _cityIds,
                      idOf: (city) => city.id,
                      labelOf: (city) => city.name,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SelectionBlock(
                      title: 'Categories',
                      items: categories,
                      selectedIds: _categoryIds,
                      idOf: (category) => category.id,
                      labelOf: (category) => category.name,
                      onChanged: () => setState(() {
                        _primaryCategoryId = _categoryIds.isEmpty
                            ? ''
                            : _categoryIds.first;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _requiredField(
                            _contactName,
                            'Business contact name',
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _phoneField(
                            _contactPhone,
                            'Business contact phone',
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _emailField(
                            _contactEmail,
                            'Business contact email',
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _emailField(
                            _marketingEmail,
                            'Marketing email',
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _emailField(_loginEmail, 'Login email'),
                        ),
                        SizedBox(width: 280, child: _passwordField()),
                        SizedBox(
                          width: 280,
                          child: _requiredField(
                            _loginName,
                            'Login user full name',
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _phoneField(_loginPhone, 'Login user phone'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go('/brands'),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: state.isLoading ? null : _submit,
                          icon: AppAsyncButtonIcon(
                            isLoading: state.isLoading,
                            icon: Icons.storefront_outlined,
                          ),
                          label: const Text('Register brand'),
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
      controller: _loginPassword,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Temporary password',
        helperText: 'Stored only in Firebase Auth, not in Firestore.',
      ),
      validator: (value) {
        final text = value ?? '';
        if (_loginUserId.text.trim().isNotEmpty && text.isEmpty) {
          return null;
        }
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
