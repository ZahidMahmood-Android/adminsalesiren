import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../providers/brand_providers.dart';

class BrandsListScreen extends ConsumerWidget {
  const BrandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Brands',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/brands/new'),
                icon: const Icon(Icons.add),
                label: const Text('New brand'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: brands.when(
              skipLoadingOnRefresh: true,
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No brands yet',
                    message:
                        'Create the first brand to start entering offers.',
                    action: FilledButton.icon(
                      onPressed: () => context.go('/brands/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New brand'),
                    ),
                  );
                }

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final brand = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.paper,
                          backgroundImage: brand.logoUrl.isEmpty
                              ? null
                              : NetworkImage(brand.logoUrl),
                          child: brand.logoUrl.isEmpty
                              ? const Icon(Icons.storefront_outlined)
                              : null,
                        ),
                        title: Text(
                          brand.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${brand.categoryIds.length} categories · ${brand.cityIds.length} cities',
                        ),
                        trailing: Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppBadge(
                              label: brand.isActive ? 'Active' : 'Inactive',
                              color: brand.isActive
                                  ? AppTheme.deepGreen
                                  : Colors.black45,
                            ),
                            IconButton(
                              tooltip: 'Edit brand',
                              onPressed: () =>
                                  context.go('/brands/${brand.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete brand',
                              onPressed: () async {
                                final confirmed =
                                    await showSweetConfirmationDialog(
                                  context: context,
                                  title: 'Delete brand?',
                                  message:
                                      'This will remove ${brand.name} permanently.',
                                  confirmLabel: 'Delete',
                                );
                                if (!confirmed || !context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(brandActionsProvider.notifier)
                                    .delete(brand.id);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AppLoadingView(label: 'Loading brands'),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(brandsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
