import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../domain/entities/city.dart';
import '../providers/city_providers.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class CityFormScreen extends ConsumerStatefulWidget {
  const CityFormScreen({super.key, this.cityId});

  final String? cityId;

  @override
  ConsumerState<CityFormScreen> createState() => _CityFormScreenState();
}

class _CityFormScreenState extends ConsumerState<CityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController(text: 'Pakistan');
  var _isActive = true;
  var _hydrated = false;

  bool get _isEditing => widget.cityId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _hydrate(City city) {
    if (_hydrated) {
      return;
    }
    _nameController.text = city.name;
    _countryController.text = city.country;
    _isActive = city.isActive;
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final city = City(
      id: _isEditing ? widget.cityId! : '',
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      isActive: _isActive,
      createdAt: now,
      updatedAt: now,
    );
    await ref
        .read(cityActionsProvider.notifier)
        .save(city, isEditing: _isEditing);
    final actionState = ref.read(cityActionsProvider);
    if (actionState.hasError && mounted) {
      if (mounted) {
        await showAppError(
          context,
          actionState.error,
          title: 'Could Not Save City',
        );
      }
      return;
    }
    if (mounted) {
      context.go('/cities');
    }
  }

  Future<void> _delete() async {
    final id = widget.cityId;
    if (id == null) {
      return;
    }
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete city?',
      message: 'This city record will be removed permanently.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(cityActionsProvider.notifier).delete(id);
    if (mounted) {
      context.go('/cities');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityAsync = _isEditing
        ? ref.watch(cityProvider(widget.cityId!))
        : const AsyncValue<City?>.data(null);
    final actionState = ref.watch(cityActionsProvider);

    return cityAsync.when(
      skipLoadingOnRefresh: true,
      data: (city) {
        if (_isEditing && city == null) {
          return const AppErrorView(message: 'City not found.');
        }
        if (city != null) {
          _hydrate(city);
        }
        return AppLoadingOverlay(
          isLoading: actionState.isLoading,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isEditing ? 'Edit city' : 'New city',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (_isEditing)
                              IconButton(
                                tooltip: 'Delete city',
                                onPressed: actionState.isLoading
                                    ? null
                                    : _delete,
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'City name',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'City name is required'
                              : null,
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: widget.cityId,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'City ID',
                              prefixIcon: Icon(Icons.key_outlined),
                              helperText: 'Assigned by Firebase when created',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.public),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Country is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppListTileMaterial(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Active city'),
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/cities'),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: actionState.isLoading ? null : _submit,
                              icon: AppAsyncButtonIcon(
                                isLoading: actionState.isLoading,
                                icon: Icons.save_outlined,
                              ),
                              label: const Text('Save city'),
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
      loading: () => const AppLoader(),
      error: (error, _) => AppErrorView(error: error),
    );
  }
}
