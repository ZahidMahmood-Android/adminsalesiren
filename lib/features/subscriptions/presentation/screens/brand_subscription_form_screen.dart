import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_inline_error.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../brands/presentation/providers/brand_providers.dart'
    show registeredBrandsProvider;
import '../providers/subscription_providers.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class BrandSubscriptionFormScreen extends ConsumerStatefulWidget {
  const BrandSubscriptionFormScreen({super.key});

  @override
  ConsumerState<BrandSubscriptionFormScreen> createState() =>
      _BrandSubscriptionFormScreenState();
}

class _BrandSubscriptionFormScreenState
    extends ConsumerState<BrandSubscriptionFormScreen> {
  String? _brandId;
  String? _planId;
  var _autoRenew = false;
  var _paymentStatus = 'paid';
  final _discountController = TextEditingController(text: '0');
  final _discountNotesController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    _discountNotesController.dispose();
    super.dispose();
  }

  num get _discountPercent =>
      num.tryParse(_discountController.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (_brandId == null || _planId == null) {
      showAppError(
        context,
        null,
        message: 'Please select both a brand and a pricing plan.',
      );
      return;
    }
    final discount = _discountPercent;
    if (discount < 0 || discount > 100) {
      showAppError(
        context,
        null,
        message: 'Discount must be between 0 and 100.',
      );
      return;
    }
    await ref
        .read(subscriptionActionsProvider.notifier)
        .assignSubscription(
          brandId: _brandId!,
          planId: _planId!,
          paymentStatus: _paymentStatus,
          autoRenew: _autoRenew,
          discountPercent: discount,
          discountNotes: _discountNotesController.text.trim(),
        );
    final state = ref.read(subscriptionActionsProvider);
    if (state.hasError) {
      if (mounted) {
        if (mounted) {
          await showAppError(
            context,
            state.error,
            title: 'Could Not Assign Plan',
          );
        }
      }
      return;
    }
    if (mounted) {
      context.go('/subscriptions/brand-subscriptions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(registeredBrandsProvider);
    final plans = ref.watch(pricingPlansProvider);
    final actionState = ref.watch(subscriptionActionsProvider);

    return AppLoadingOverlay(
      isLoading: actionState.isLoading,
      child: Padding(
        padding: screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign subscription',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  brands.when(
                    data: (items) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        helperText:
                            'Only registered brands (with brand-admin accounts) are listed.',
                      ),
                      items: items
                          .map(
                            (brand) => DropdownMenuItem(
                              value: brand.id,
                              child: Text(brand.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _brandId = value),
                    ),
                    loading: () =>
                        const SizedBox(height: 72, child: AppLoader(size: 56)),
                    error: (error, _) => AppInlineError(error),
                  ),
                  const SizedBox(height: 12),
                  plans.when(
                    data: (items) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Pricing plan',
                      ),
                      items: items
                          .map(
                            (plan) => DropdownMenuItem(
                              value: plan.id,
                              child: Text(
                                '${plan.name} (${plan.currency} ${plan.monthlyPrice})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _planId = value),
                    ),
                    loading: () =>
                        const SizedBox(height: 72, child: AppLoader(size: 56)),
                    error: (error, _) => AppInlineError(error),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'trial', child: Text('Trial')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Discount section
                  _DiscountPreview(
                    plans: plans,
                    planId: _planId,
                    discountController: _discountController,
                    onDiscountChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _discountNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Discount reason (optional)',
                      hintText: 'e.g. Promotional offer, loyalty discount…',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const Divider(),
                  const SizedBox(height: 4),
                  AppListTileMaterial(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto renew'),
                      value: _autoRenew,
                      onChanged: (value) => setState(() => _autoRenew = value),
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            context.go('/subscriptions/brand-subscriptions'),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: actionState.isLoading ? null : _submit,
                        child: const Text('Assign'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline discount input + live price preview for the assign-subscription form.
class _DiscountPreview extends StatelessWidget {
  const _DiscountPreview({
    required this.plans,
    required this.planId,
    required this.discountController,
    required this.onDiscountChanged,
  });

  final AsyncValue<dynamic> plans;
  final String? planId;
  final TextEditingController discountController;
  final VoidCallback onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final planPrice = plans.maybeWhen(
      data: (items) {
        final matched = (items as List).cast<dynamic>().firstWhere(
          (p) => p.id == planId,
          orElse: () => null,
        );
        return matched?.monthlyPrice as num?;
      },
      orElse: () => null,
    );

    final rawDiscount = num.tryParse(discountController.text.trim()) ?? 0;
    final clamped = rawDiscount.clamp(0, 100);
    final discountedPrice = planPrice != null && clamped > 0
        ? planPrice * (1 - clamped / 100)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount (optional)',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                  hintText: '0',
                  suffixText: '%',
                  prefixIcon: Icon(Icons.discount_outlined),
                  helperText: '0 = no discount, 100 = free',
                ),
                onChanged: (_) => onDiscountChanged(),
              ),
            ),
            if (planPrice != null) ...[
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (discountedPrice != null)
                    Text(
                      'PKR ${discountedPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade700,
                      ),
                    ),
                  Text(
                    discountedPrice != null
                        ? 'was PKR ${planPrice.toStringAsFixed(0)}'
                        : 'PKR ${planPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      decoration: discountedPrice != null
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
