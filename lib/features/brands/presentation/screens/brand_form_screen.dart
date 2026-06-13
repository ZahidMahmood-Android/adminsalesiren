import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/domain/entities/city.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../domain/entities/brand.dart';
import '../providers/brand_providers.dart';

class BrandFormScreen extends ConsumerStatefulWidget {
  const BrandFormScreen({super.key, this.brandId});

  final String? brandId;

  @override
  ConsumerState<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends ConsumerState<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _selectedCategoryIds = <String>{};
  final _selectedCityIds = <String>{};
  var _isActive = true;
  var _hydrated = false;

  bool get _isEditing => widget.brandId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _hydrate(Brand brand) {
    if (_hydrated) {
      return;
    }
    _nameController.text = brand.name;
    _logoController.text = brand.logoUrl;
    _websiteController.text = brand.websiteUrl;
    _instagramController.text = brand.instagramUrl;
    _facebookController.text = brand.facebookUrl;
    _selectedCategoryIds
      ..clear()
      ..addAll(brand.categoryIds);
    _selectedCityIds
      ..clear()
      ..addAll(brand.cityIds);
    _isActive = brand.isActive;
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategoryIds.isEmpty || _selectedCityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one city and category.')),
      );
      return;
    }

    final now = DateTime.now();
    final brand = Brand(
      id: widget.brandId ?? '',
      name: _nameController.text.trim(),
      logoUrl: _logoController.text.trim(),
      websiteUrl: _websiteController.text.trim(),
      instagramUrl: _instagramController.text.trim(),
      facebookUrl: _facebookController.text.trim(),
      categoryIds: _selectedCategoryIds.toList(),
      cityIds: _selectedCityIds.toList(),
      isActive: _isActive,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(brandActionsProvider.notifier).save(brand);
    final actionState = ref.read(brandActionsProvider);
    if (actionState.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.friendly(actionState.error))),
      );
      return;
    }
    if (mounted) {
      context.go('/brands');
    }
  }

  Future<void> _delete() async {
    final id = widget.brandId;
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete brand?'),
        content: const Text('This removes the brand document from Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(brandActionsProvider.notifier).delete(id);
    if (mounted) {
      context.go('/brands');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandAsync = _isEditing
        ? ref.watch(brandProvider(widget.brandId!))
        : const AsyncValue<Brand?>.data(null);
    final categories = ref.watch(categoriesProvider);
    final cities = ref.watch(citiesProvider);
    final actionState = ref.watch(brandActionsProvider);

    return brandAsync.when(
      data: (brand) {
        if (_isEditing && brand == null) {
          return const AppErrorView(message: 'Brand not found.');
        }
        if (brand != null) {
          _hydrate(brand);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEditing ? 'Edit brand' : 'New brand',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (_isEditing)
                            IconButton(
                              tooltip: 'Delete brand',
                              onPressed: actionState.isLoading ? null : _delete,
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Brand name',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Brand name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _logoController,
                        decoration: const InputDecoration(
                          labelText: 'Logo URL',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 280,
                            child: TextFormField(
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                labelText: 'Website URL',
                                prefixIcon: Icon(Icons.language),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextFormField(
                              controller: _instagramController,
                              decoration: const InputDecoration(
                                labelText: 'Instagram URL',
                                prefixIcon: Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextFormField(
                              controller: _facebookController,
                              decoration: const InputDecoration(
                                labelText: 'Facebook URL',
                                prefixIcon: Icon(Icons.facebook),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active brand'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 12),
                      _SelectionBlock<City>(
                        title: 'Cities',
                        items: cities,
                        selectedIds: _selectedCityIds,
                        idOf: (city) => city.id,
                        labelOf: (city) => city.name,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _SelectionBlock<app_category.Category>(
                        title: 'Categories',
                        items: categories,
                        selectedIds: _selectedCategoryIds,
                        idOf: (category) => category.id,
                        labelOf: (category) => category.name,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/brands'),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: actionState.isLoading ? null : _submit,
                            icon: actionState.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save brand'),
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
      },
      loading: () => const AppLoadingView(label: 'Loading brand'),
      error: (error, _) => AppErrorView(message: error.toString()),
    );
  }
}

class _SelectionBlock<T> extends StatelessWidget {
  const _SelectionBlock({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final AsyncValue<List<T>> items;
  final Set<String> selectedIds;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        items.when(
          data: (values) {
            if (values.isEmpty) {
              return const Text('No active records found.');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((item) {
                final id = idOf(item);
                final selected = selectedIds.contains(id);
                return FilterChip(
                  label: Text(labelOf(item)),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                    }
                    onChanged();
                  },
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(error.toString()),
        ),
      ],
    );
  }
}
