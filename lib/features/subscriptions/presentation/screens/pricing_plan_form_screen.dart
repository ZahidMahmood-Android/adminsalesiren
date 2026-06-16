import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../domain/entities/pricing_plan.dart';
import '../providers/subscription_providers.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/screen_layout.dart';

class PricingPlanFormScreen extends ConsumerStatefulWidget {
  const PricingPlanFormScreen({super.key, this.planId});

  final String? planId;

  @override
  ConsumerState<PricingPlanFormScreen> createState() =>
      _PricingPlanFormScreenState();
}

class _PricingPlanFormScreenState extends ConsumerState<PricingPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _trialDaysController = TextEditingController(text: '0');
  final _offerLimitController = TextEditingController(text: '5');
  final _activeLimitController = TextEditingController(text: '2');
  final _pushLimitController = TextEditingController(text: '0');
  final _featuredLimitController = TextEditingController(text: '0');
  final _cityLimitController = TextEditingController(text: '1');
  final _userLimitController = TextEditingController(text: '1');
  final _sortOrderController = TextEditingController(text: '1');
  var _billingCycle = 'monthly';
  var _analyticsLevel = 'basic';
  var _isActive = true;
  var _isPublic = true;
  var _requiresApproval = true;
  var _canPush = false;
  var _canFeatured = false;
  var _canExport = false;
  var _hydrated = false;

  bool get _isEditing => widget.planId != null;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _trialDaysController.dispose();
    _offerLimitController.dispose();
    _activeLimitController.dispose();
    _pushLimitController.dispose();
    _featuredLimitController.dispose();
    _cityLimitController.dispose();
    _userLimitController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _hydrate(PricingPlan plan) {
    if (_hydrated) {
      return;
    }
    _idController.text = plan.id;
    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _priceController.text = plan.monthlyPrice.toString();
    _trialDaysController.text = plan.trialDays.toString();
    _offerLimitController.text = plan.offerLimitPerMonth.toString();
    _activeLimitController.text = plan.activeOfferLimit.toString();
    _pushLimitController.text = plan.pushNotificationLimitPerMonth.toString();
    _featuredLimitController.text = plan.featuredOfferLimitPerMonth.toString();
    _cityLimitController.text = plan.cityLimit.toString();
    _userLimitController.text = plan.userLimit.toString();
    _sortOrderController.text = plan.sortOrder.toString();
    _billingCycle = plan.billingCycle;
    _analyticsLevel = plan.analyticsLevel;
    _isActive = plan.isActive;
    _isPublic = plan.isPublic;
    _requiresApproval = plan.requiresOfferApproval;
    _canPush = plan.canRequestPushNotifications;
    _canFeatured = plan.canUseFeaturedOffers;
    _canExport = plan.canExportAnalytics;
    _hydrated = true;
  }

  int _readInt(TextEditingController controller, {int fallback = 0}) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final plan = PricingPlan(
      id: _isEditing ? widget.planId! : _idController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      monthlyPrice: num.tryParse(_priceController.text.trim()) ?? 0,
      currency: 'PKR',
      billingCycle: _billingCycle,
      trialDays: _readInt(_trialDaysController),
      offerLimitPerMonth: _readInt(_offerLimitController),
      activeOfferLimit: _readInt(_activeLimitController),
      pushNotificationLimitPerMonth: _readInt(_pushLimitController),
      featuredOfferLimitPerMonth: _readInt(_featuredLimitController),
      cityLimit: _readInt(_cityLimitController, fallback: 1),
      userLimit: _readInt(_userLimitController, fallback: 1),
      analyticsLevel: _analyticsLevel,
      requiresOfferApproval: _requiresApproval,
      canRequestPushNotifications: _canPush,
      canUseFeaturedOffers: _canFeatured,
      canExportAnalytics: _canExport,
      isActive: _isActive,
      isPublic: _isPublic,
      sortOrder: _readInt(_sortOrderController, fallback: 1),
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(subscriptionActionsProvider.notifier).savePricingPlan(plan);
    final state = ref.read(subscriptionActionsProvider);
    if (state.hasError) {
      if (mounted) {
        if (mounted)
          await showAppError(
            context,
            state.error,
            title: 'Could Not Save Plan',
          );
      }
      return;
    }
    if (mounted) {
      context.go('/subscriptions/plans');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      final planAsync = ref.watch(pricingPlanProvider(widget.planId!));
      return planAsync.when(
        loading: () => const Scaffold(body: AppLoadingView()),
        error: (error, _) =>
            Scaffold(body: AppErrorView(message: error.toString())),
        data: (plan) {
          if (plan != null) {
            _hydrate(plan);
          }
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final actionState = ref.watch(subscriptionActionsProvider);
    return Padding(
      padding: screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit pricing plan' : 'New pricing plan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isEditing)
                        TextFormField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'Plan ID',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 2,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly price (PKR)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _offerLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Offers / month',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _activeLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Active offers',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pushLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Push / month',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _featuredLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Featured / month',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        value: _analyticsLevel,
                        decoration: const InputDecoration(
                          labelText: 'Analytics level',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'basic',
                            child: Text('Basic'),
                          ),
                          DropdownMenuItem(
                            value: 'standard',
                            child: Text('Standard'),
                          ),
                          DropdownMenuItem(
                            value: 'advanced',
                            child: Text('Advanced'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _analyticsLevel = value);
                          }
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      SwitchListTile(
                        title: const Text('Public'),
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                      ),
                      SwitchListTile(
                        title: const Text('Can request push notifications'),
                        value: _canPush,
                        onChanged: (value) => setState(() => _canPush = value),
                      ),
                      SwitchListTile(
                        title: const Text('Can use featured offers'),
                        value: _canFeatured,
                        onChanged: (value) =>
                            setState(() => _canFeatured = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/subscriptions/plans'),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: actionState.isLoading ? null : _submit,
                            child: Text(_isEditing ? 'Save' : 'Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
