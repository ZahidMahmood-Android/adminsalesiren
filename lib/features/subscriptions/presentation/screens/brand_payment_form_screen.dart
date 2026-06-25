import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/brand_payment.dart';
import '../providers/subscription_providers.dart';

class BrandPaymentFormScreen extends ConsumerStatefulWidget {
  const BrandPaymentFormScreen({super.key});

  @override
  ConsumerState<BrandPaymentFormScreen> createState() =>
      _BrandPaymentFormScreenState();
}

class _BrandPaymentFormScreenState
    extends ConsumerState<BrandPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  String _method = 'bank_transfer';
  Uint8List? _proofBytes;
  String? _proofFileName;
  bool _uploading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _proofBytes = bytes;
      _proofFileName = image.name;
    });
  }

  Future<String?> _uploadProof(String brandId) async {
    if (_proofBytes == null || _proofFileName == null) return null;
    final storage = ref.read(firebaseStorageProvider);
    final safeFile = _proofFileName!.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final path =
        'brand_payments/$brandId/${DateTime.now().millisecondsSinceEpoch}_$safeFile';
    final ref2 = storage.ref(path);
    final task = await ref2.putData(
      _proofBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null || user.brandId.isEmpty) return;

    if (_proofBytes == null) {
      showAppError(
        context,
        null,
        message: 'Please attach a payment screenshot as proof.',
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final proofUrl = await _uploadProof(user.brandId);
      final now = DateTime.now();
      final payment = BrandPayment(
        id: '',
        brandId: user.brandId,
        subscriptionId: '',
        amount: num.parse(_amountController.text.trim()),
        currency: 'PKR',
        paymentMethod: _method,
        paymentStatus: 'pending',
        transactionReference: _referenceController.text.trim(),
        proofImageUrl: proofUrl ?? '',
        paidAt: now,
        verifiedByAdminId: '',
        verifiedAt: null,
        notes: _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(subscriptionActionsProvider.notifier).savePayment(payment);
      final state = ref.read(subscriptionActionsProvider);
      if (state.hasError) {
        if (mounted) {
          await showAppError(
            context,
            state.error,
            title: 'Could Not Submit Payment',
          );
        }
        return;
      }
      if (mounted) context.go('/subscriptions/payments');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(subscriptionActionsProvider);
    final busy = _uploading || actionState.isLoading;

    return ScreenScaffold(
      title: 'Submit Payment',
      loading: busy,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment method selector
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'bank_transfer',
                          label: Text('Bank Transfer'),
                          icon: Icon(Icons.account_balance_outlined),
                        ),
                        ButtonSegment(
                          value: 'cash',
                          label: Text('Cash'),
                          icon: Icon(Icons.money_outlined),
                        ),
                        ButtonSegment(
                          value: 'easypaisa',
                          label: Text('Easypaisa'),
                          icon: Icon(Icons.phone_android_outlined),
                        ),
                        ButtonSegment(
                          value: 'jazzcash',
                          label: Text('JazzCash'),
                          icon: Icon(Icons.phone_android_outlined),
                        ),
                      ],
                      selected: {_method},
                      onSelectionChanged: (val) =>
                          setState(() => _method = val.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account details card (shown based on method)
              _AccountDetailsCard(method: _method),
              const SizedBox(height: 16),

              // Payment details form
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (PKR)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        if (num.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        labelText: _method == 'cash'
                            ? 'Receipt / Reference number (optional)'
                            : 'Transaction ID / Reference number',
                        prefixIcon: const Icon(Icons.numbers_outlined),
                      ),
                      validator: (v) {
                        if (_method != 'cash' &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Transaction reference is required for '
                              '$_method payments';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note to admin (optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Proof screenshot upload
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payment Screenshot (Proof)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        const Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_proofBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _proofBytes!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _proofFileName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickProof,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(
                        _proofBytes == null
                            ? 'Attach Screenshot'
                            : 'Change Screenshot',
                      ),
                    ),
                    if (_method != 'cash') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Attach a screenshot of the bank/wallet transfer '
                        'confirmation for faster verification.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => context.go('/subscriptions/payments'),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: busy ? null : _submit,
                    icon: AppAsyncButtonIcon(
                      isLoading: busy,
                      icon: Icons.send_outlined,
                    ),
                    label: Text(_uploading ? 'Uploading…' : 'Submit Payment'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    late final String title;
    late final List<_DetailRow> rows;

    switch (method) {
      case 'bank_transfer':
        title = 'Bank Transfer Details';
        rows = [
          _DetailRow('Bank', AppConstants.bankName),
          _DetailRow('Account Title', AppConstants.bankAccountTitle),
          _DetailRow('Account Number', AppConstants.bankAccountNumber),
          _DetailRow('IBAN', AppConstants.bankIban),
        ];
      case 'easypaisa':
        title = 'Easypaisa Account';
        rows = [
          _DetailRow('Account Title', AppConstants.bankAccountTitle),
          _DetailRow('Mobile Number', AppConstants.easypaisaAccount),
        ];
      case 'jazzcash':
        title = 'JazzCash Account';
        rows = [
          _DetailRow('Account Title', AppConstants.bankAccountTitle),
          _DetailRow('Mobile Number', AppConstants.jazzcashAccount),
        ];
      case 'cash':
        title = 'Cash Payment';
        rows = [
          _DetailRow(
            'Instructions',
            'Pay in person at our office. '
                'Bring your receipt. '
                'Contact ${AppConstants.supportEmail} to arrange.',
          ),
        ];
      default:
        return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.deepGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      r.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}
