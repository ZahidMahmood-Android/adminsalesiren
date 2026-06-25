import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/brand_payment.dart';
import '../providers/subscription_providers.dart';

class BrandPaymentVerifyScreen extends ConsumerWidget {
  const BrandPaymentVerifyScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(brandPaymentProvider(paymentId));
    return paymentAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (error, _) => Scaffold(body: AppErrorView(error: error)),
      data: (payment) {
        if (payment == null) {
          return const Scaffold(
            body: AppErrorView(message: 'Payment record not found.'),
          );
        }
        return _PaymentDetailView(paymentId: paymentId, payment: payment);
      },
    );
  }
}

class _PaymentDetailView extends ConsumerStatefulWidget {
  const _PaymentDetailView({required this.paymentId, required this.payment});

  final String paymentId;
  final BrandPayment payment;

  @override
  ConsumerState<_PaymentDetailView> createState() => _PaymentDetailViewState();
}

class _PaymentDetailViewState extends ConsumerState<_PaymentDetailView> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.payment.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    await ref
        .read(subscriptionActionsProvider.notifier)
        .verifyPayment(widget.paymentId, notes: _notesController.text.trim());
    final state = ref.read(subscriptionActionsProvider);
    if (state.hasError) {
      if (mounted) {
        await showAppError(
          context,
          state.error,
          title: 'Could Not Verify Payment',
        );
      }
      return;
    }
    if (mounted) context.go('/subscriptions/payments');
  }

  Future<void> _cancel() async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Cancel payment?',
      message:
          'This will mark the payment as cancelled. '
          'The brand admin will see the updated status.',
      confirmLabel: 'Cancel Payment',
      color: Colors.red,
      icon: Icons.cancel_outlined,
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(subscriptionActionsProvider.notifier)
        .cancelPayment(widget.paymentId);
    final state = ref.read(subscriptionActionsProvider);
    if (state.hasError) {
      if (mounted) {
        await showAppError(
          context,
          state.error,
          title: 'Could Not Cancel Payment',
        );
      }
      return;
    }
    if (mounted) context.go('/subscriptions/payments');
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final actionState = ref.watch(subscriptionActionsProvider);
    final isOwner = ref.watch(isOwnerProvider);

    final isVerified = payment.paymentStatus == 'verified';
    final isCancelled = payment.paymentStatus == 'cancelled';
    final canAct = isOwner && !isVerified && !isCancelled;

    final statusColor = isVerified
        ? Colors.green
        : isCancelled
        ? Colors.black38
        : Colors.orange;

    return ScreenScaffold(
      title: 'Payment Details',
      loading: actionState.isLoading,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            AppCard(
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Icons.verified_outlined
                        : isCancelled
                        ? Icons.cancel_outlined
                        : Icons.pending_outlined,
                    color: statusColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppStatusChip(
                          status: payment.paymentStatus,
                          customColor: statusColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${payment.amount}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow('Brand ID', payment.brandId),
                  _InfoRow('Method', _methodLabel(payment.paymentMethod)),
                  _InfoRow('Amount', 'PKR ${payment.amount}'),
                  _InfoRow('Currency', payment.currency),
                  if (payment.transactionReference.isNotEmpty)
                    _InfoRow('Reference', payment.transactionReference),
                  if (payment.subscriptionId.isNotEmpty)
                    _InfoRow('Subscription ID', payment.subscriptionId),
                  _InfoRow(
                    'Submitted on',
                    payment.paidAt != null
                        ? _dateLabel(payment.paidAt!)
                        : _dateLabel(payment.createdAt),
                  ),
                  if (payment.notes.isNotEmpty && !canAct)
                    _InfoRow('Notes', payment.notes),
                  if (isVerified) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      'Verified by',
                      payment.verifiedByAdminId.isNotEmpty
                          ? payment.verifiedByAdminId
                          : '—',
                    ),
                    if (payment.verifiedAt != null)
                      _InfoRow('Verified on', _dateLabel(payment.verifiedAt!)),
                    if (payment.notes.isNotEmpty)
                      _InfoRow('Admin notes', payment.notes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof screenshot
            if (payment.proofImageUrl.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: AppTheme.deepGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Proof Screenshot',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        payment.proofImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Could not load proof image.'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (payment.proofImageUrl.isNotEmpty) const SizedBox(height: 16),

            // Admin action section (owner only, for non-finalised payments)
            if (canAct)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Admin Action',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Admin notes (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: actionState.isLoading ? null : _cancel,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Payment'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: actionState.isLoading ? null : _verify,
                          icon: AppAsyncButtonIcon(
                            isLoading: actionState.isLoading,
                            icon: Icons.verified_outlined,
                          ),
                          label: const Text('Mark Verified'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/subscriptions/payments'),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Back to Payments'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _methodLabel(String method) => DisplayLabelUtils.slug(method);

  String _dateLabel(DateTime dt) {
    return dt.toLocal().toString().split('.').first;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
