import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/brand_providers.dart';

class BrandsListScreen extends ConsumerWidget {
  const BrandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final actionState = ref.watch(brandActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: ScreenHeader(
        title: isBrandScopedUser ? 'My Brand Profile' : 'Brands',
        actions: isBrandScopedUser
            ? []
            : [
                OutlinedButton.icon(
                  onPressed: () => context.go('/brands/register'),
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Register brand'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/brands/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New brand'),
                ),
              ],
      ),
      child: AnimatedContent(
        child: brands.when(
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const ValueKey('brands-empty'),
                icon: Icons.storefront_outlined,
                title: 'No brands yet',
                message: isBrandScopedUser
                    ? 'Your brand profile is not linked yet.'
                    : 'Create the first brand to start entering offers.',
                action: isBrandScopedUser
                    ? null
                    : FilledButton.icon(
                        onPressed: () => context.go('/brands/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New brand'),
                      ),
              );
            }

            return AppCard(
              key: const ValueKey('brands-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final brand = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: AppAvatar(
                        name: brand.name,
                        imageUrl: brand.logoUrl,
                        radius: 22,
                      ),
                      title: AppTextView.title(
                        brand.name,
                        fontWeight: FontWeight.w800,
                      ),
                      subtitle: AppTextView.body(
                        '${brand.categoryIds.length} categories · ${brand.cityIds.length} cities',
                      ),
                      trailing: Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppStatusChip(
                            status: brand.isActive ? 'active' : 'inactive',
                          ),
                          IconButton(
                            tooltip: 'Edit brand',
                            onPressed: () => context.go('/brands/${brand.id}'),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          if (!isBrandScopedUser)
                            IconButton(
                              tooltip: 'Delete brand',
                              onPressed: () async {
                                final confirmed = await showSweetConfirmationDialog(
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
    );
  }
}
