import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/subscription_request.dart';
import '../providers/subscription_providers.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class SubscriptionRequestFormScreen extends ConsumerStatefulWidget {
  const SubscriptionRequestFormScreen({super.key});

  @override
  ConsumerState<SubscriptionRequestFormScreen> createState() =>
      _SubscriptionRequestFormScreenState();
}

class _SubscriptionRequestFormScreenState
    extends ConsumerState<SubscriptionRequestFormScreen> {
  final _messageController = TextEditingController();
  var _type = 'upgrade';
  String? _requestedPlanId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.brandId.isEmpty) {
      return;
    }
    if (_requestedPlanId == null) {
      showAppError(context, null, message: 'Please select a pricing plan.');
      return;
    }
    final subscription = await ref
        .read(subscriptionsRepositoryProvider)
        .getActiveSubscriptionForBrand(user.brandId);
    final now = DateTime.now();
    final request = SubscriptionRequest(
      id: '',
      brandId: user.brandId,
      currentPlanId: subscription?.planId ?? '',
      requestedPlanId: _requestedPlanId!,
      type: _type,
      message: _messageController.text.trim(),
      status: 'pending',
      adminNotes: '',
      createdAt: now,
      updatedAt: now,
    );
    await ref
        .read(subscriptionActionsProvider.notifier)
        .createSubscriptionRequest(request);
    final state = ref.read(subscriptionActionsProvider);
    if (state.hasError) {
      if (mounted) {
        if (mounted)
          await showAppError(
            context,
            state.error,
            title: 'Could Not Submit Request',
          );
      }
      return;
    }
    if (mounted) {
      context.go('/subscriptions/my');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(publicPricingPlansProvider);
    final actionState = ref.watch(subscriptionActionsProvider);

    return Padding(
      padding: screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upgrade / Renew Request',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Request type'),
                  items: const [
                    DropdownMenuItem(value: 'upgrade', child: Text('Upgrade')),
                    DropdownMenuItem(value: 'renew', child: Text('Renew')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                plans.when(
                  data: (items) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Requested plan',
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
                    onChanged: (value) =>
                        setState(() => _requestedPlanId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(error.toString()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message to admin (optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/subscriptions/my'),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: actionState.isLoading ? null : _submit,
                      child: actionState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit request'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
