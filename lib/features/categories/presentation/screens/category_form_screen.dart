import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _iconController = TextEditingController(text: 'local_offer');
  final _sortOrderController = TextEditingController(text: '1');
  var _isActive = true;
  var _hydrated = false;

  bool get _isEditing => widget.categoryId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _iconController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _hydrate(Category category) {
    if (_hydrated) {
      return;
    }
    _nameController.text = category.name;
    _idController.text = category.id;
    _iconController.text = category.iconName;
    _sortOrderController.text = category.sortOrder.toString();
    _isActive = category.isActive;
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final category = Category(
      id: _isEditing ? widget.categoryId! : _idController.text.trim(),
      name: _nameController.text.trim(),
      iconName: _iconController.text.trim(),
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
      createdAt: now,
      updatedAt: now,
    );
    await ref
        .read(categoryActionsProvider.notifier)
        .save(category, isEditing: _isEditing);
    final actionState = ref.read(categoryActionsProvider);
    if (actionState.hasError && mounted) {
      if (mounted)
        await showAppError(
          context,
          actionState.error,
          title: 'Could Not Save Category',
        );
      return;
    }
    if (mounted) {
      context.go('/categories');
    }
  }

  Future<void> _delete() async {
    final id = widget.categoryId;
    if (id == null) {
      return;
    }
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete category?',
      message: 'This category record will be removed permanently.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(categoryActionsProvider.notifier).delete(id);
    if (mounted) {
      context.go('/categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = _isEditing
        ? ref.watch(categoryProvider(widget.categoryId!))
        : const AsyncValue<Category?>.data(null);
    final actionState = ref.watch(categoryActionsProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final currentUser = ref.watch(currentUserProvider);

    return categoryAsync.when(
      skipLoadingOnRefresh: true,
      data: (category) {
        if (_isEditing && category == null) {
          return const AppErrorView(message: 'Category not found.');
        }
        final canManageCategory =
            !isBrandScopedUser ||
            !_isEditing ||
            category?.userId == currentUser?.id;
        if (!canManageCategory) {
          return const AppErrorView(
            message: 'You can only edit categories created by your account.',
          );
        }
        if (category != null) {
          _hydrate(category);
        }
        return SingleChildScrollView(
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
                              _isEditing ? 'Edit category' : 'New category',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (_isEditing && canManageCategory)
                            IconButton(
                              tooltip: 'Delete category',
                              onPressed: actionState.isLoading ? null : _delete,
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Category name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _idController,
                        enabled: !_isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Category ID',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Category ID is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _iconController,
                        decoration: const InputDecoration(
                          labelText: 'Icon name',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sort order',
                          prefixIcon: Icon(Icons.sort),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active category'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/categories'),
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
                            label: const Text('Save category'),
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
      loading: () => const AppLoadingView(label: 'Loading category'),
      error: (error, _) => AppErrorView(message: error.toString()),
    );
  }
}
