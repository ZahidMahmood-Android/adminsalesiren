import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../access/presentation/widgets/user_features_field.dart';
import '../../data/services/registration_email_verification_service.dart';
import '../providers/registration_email_verification_provider.dart';
import '../providers/user_registration_providers.dart';
import '../widgets/user_roles_field.dart';

class UserRegistrationScreen extends ConsumerStatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  ConsumerState<UserRegistrationScreen> createState() =>
      _UserRegistrationScreenState();
}

class _UserRegistrationScreenState
    extends ConsumerState<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedRoleIds = {UserRoles.mobileUser};
  final _selectedFeatureIds = <String>{
    ...AppFeatureSeedData.defaultFeaturesByRole[UserRoles.mobileUser]!,
  };
  String _brandId = '';
  var _notificationEnabled = true;
  var _verificationBusy = false;
  var _lastVerifiedEmail = '';

  @override
  void dispose() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      ref.read(registrationEmailVerificationServiceProvider).dispose();
    }
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (!_emailFieldKey.currentState!.validate()) {
      return;
    }
    setState(() => _verificationBusy = true);
    try {
      await startRegistrationEmailVerification(
        ref,
        _emailController.text.trim(),
      );
      if (!mounted) return;
      final verified = ref
          .read(registrationEmailVerificationServiceProvider)
          .snapshot
          .isVerified;
      showAppSuccess(
        context,
        verified
            ? 'This email is already verified. Complete the registration form below.'
            : 'Verification email sent. Ask the user to open the link, then continue.',
      );
    } catch (error) {
      if (!mounted) return;
      showAppError(context, error, title: 'Verification Failed');
    } finally {
      if (mounted) {
        setState(() => _verificationBusy = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _verificationBusy = true);
    try {
      await resendRegistrationEmailVerification(ref);
      if (!mounted) return;
      showAppSuccess(context, 'Verification email sent again.');
    } catch (error) {
      if (!mounted) return;
      showAppError(context, error, title: 'Resend Failed');
    } finally {
      if (mounted) {
        setState(() => _verificationBusy = false);
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _verificationBusy = true);
    try {
      await refreshRegistrationEmailVerification(
        ref,
        _emailController.text.trim(),
      );
      if (!mounted) return;
      final verified = ref
          .read(registrationEmailVerificationServiceProvider)
          .snapshot
          .isVerified;
      if (verified) {
        showAppSuccess(
          context,
          'Email verified for ${_emailController.text.trim()}. Complete registration below.',
        );
      } else {
        showAppError(
          context,
          null,
          message:
              'Email is not verified yet. Ask the user to check their inbox.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      showAppError(context, error, title: 'Status Check Failed');
    } finally {
      if (mounted) {
        setState(() => _verificationBusy = false);
      }
    }
  }

  Future<void> _onEmailChanged(String value) async {
    final normalized = value.trim().toLowerCase();
    if (normalized == _lastVerifiedEmail) {
      return;
    }
    _lastVerifiedEmail = '';
    await resetRegistrationEmailVerification(ref);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _useDifferentEmail() async {
    await resetRegistrationEmailVerification(ref);
    _emailController.clear();
    _lastVerifiedEmail = '';
    if (mounted) {
      setState(() {});
    }
  }

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRoleIds.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Select at least one role.');
      }
      return;
    }
    if (UserRoleUtils.requiresBrand(_selectedRoleIds.toList()) &&
        _brandId.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Please select a brand.');
      }
      return;
    }

    if (_selectedFeatureIds.isEmpty) {
      if (mounted) {
        showAppError(context, null, message: 'Select at least one feature.');
      }
      return;
    }

    final verification = ref
        .read(registrationEmailVerificationServiceProvider)
        .snapshot;
    if (!verification.isVerified ||
        !verification.matchesEmail(_emailController.text.trim())) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'Verify the email address before registering this user.',
        );
      }
      return;
    }

    await ref
        .read(userRegistrationProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          roles: _selectedRoleIds.toList(),
          brandId: _brandId,
          categoryIds: const [],
          cityIds: const [],
          brandIds: _brandId.isEmpty ? const [] : [_brandId],
          notificationEnabled: _notificationEnabled,
          isAdminEnabled: !UserRoleUtils.isMobileUserOnly(
            _selectedRoleIds.toList(),
          ),
          isMobileAppEnabled: true,
          featureIds: _selectedFeatureIds.toList(),
          verifiedUserId: verification.uid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final brands = ref.watch(activeBrandsProvider).value ?? const <Brand>[];
    final state = ref.watch(userRegistrationProvider);
    final verification = ref.watch(registrationEmailVerificationProvider);
    final emailVerified =
        verification.isVerified &&
        verification.matchesEmail(_emailController.text.trim());
    if (emailVerified) {
      _lastVerifiedEmail = _emailController.text.trim().toLowerCase();
    }

    ref.listen(userRegistrationProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        showAppSuccess(context, next.value!);
        context.go('/users');
      }
      if (next.hasError) {
        showAppError(context, next.error, title: 'Registration Failed');
      }
    });

    if (!isSuperAdmin) {
      return const Center(
        child: AppCard(child: Text('Only super admins can register users.')),
      );
    }

    final pageLoading = _verificationBusy || state.isLoading;

    return AppLoadingOverlay(
      isLoading: pageLoading,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register user',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _EmailVerificationSection(
                      emailController: _emailController,
                      emailFieldKey: _emailFieldKey,
                      verification: verification,
                      busy: _verificationBusy || state.isLoading,
                      onEmailChanged: _onEmailChanged,
                      onSendVerification: _sendVerificationEmail,
                      onResendVerification: _resendVerificationEmail,
                      onCheckStatus: _checkVerificationStatus,
                      onUseDifferentEmail: _useDifferentEmail,
                    ),
                    const SizedBox(height: 18),
                    if (emailVerified) ...[
                      Text(
                        'Step 2 · Complete registration',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add the remaining details for ${_emailController.text.trim()}, then register the user.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    IgnorePointer(
                      ignoring: !emailVerified,
                      child: Opacity(
                        opacity: emailVerified ? 1 : 0.55,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 360,
                                  child: _requiredField(
                                    _fullNameController,
                                    'Full name',
                                  ),
                                ),
                                SizedBox(
                                  width: 360,
                                  child: _phoneField(
                                    _phoneController,
                                    'Phone number',
                                  ),
                                ),
                                SizedBox(width: 360, child: _passwordField()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            UserRolesField(
                              selectedRoleIds: _selectedRoleIds,
                              onChanged: (roles) => setState(() {
                                _selectedRoleIds
                                  ..clear()
                                  ..addAll(roles);
                                if (!UserRoleUtils.requiresBrand(
                                  _selectedRoleIds.toList(),
                                )) {
                                  _brandId = '';
                                }
                              }),
                            ),
                            const SizedBox(height: 16),
                            UserFeaturesField(
                              selectedFeatureIds: _selectedFeatureIds,
                              onChanged: (features) => setState(
                                () => _selectedFeatureIds
                                  ..clear()
                                  ..addAll(features),
                              ),
                              onApplyRoleDefaults: () => setState(() {
                                _selectedFeatureIds
                                  ..clear()
                                  ..addAll(
                                    FeatureAccessUtils.defaultFeatureIdsForRoles(
                                      _selectedRoleIds,
                                    ),
                                  );
                              }),
                            ),
                            if (UserRoleUtils.requiresBrand(
                              _selectedRoleIds.toList(),
                            ))
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  width: 360,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _brandId.isEmpty
                                        ? null
                                        : _brandId,
                                    decoration: const InputDecoration(
                                      labelText: 'Brand',
                                      prefixIcon: Icon(
                                        Icons.storefront_outlined,
                                      ),
                                    ),
                                    items: brands
                                        .map(
                                          (brand) => DropdownMenuItem(
                                            value: brand.id,
                                            child: Text(brand.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _brandId = value ?? ''),
                                    validator: (value) {
                                      if (UserRoleUtils.requiresBrand(
                                            _selectedRoleIds.toList(),
                                          ) &&
                                          (value == null || value.isEmpty)) {
                                        return 'Brand is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            AppListTileMaterial(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Notifications enabled'),
                                subtitle: const Text(
                                  'Controls whether this user receives sale alerts.',
                                ),
                                value: _notificationEnabled,
                                onChanged: (value) => setState(
                                  () => _notificationEnabled = value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  await cancelRegistrationEmailVerification(
                                    ref,
                                    _emailController.text.trim(),
                                  );
                                  if (context.mounted) {
                                    context.go('/users');
                                  }
                                },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: state.isLoading || !emailVerified
                              ? null
                              : _submit,
                          icon: AppAsyncButtonIcon(
                            isLoading: state.isLoading,
                            icon: Icons.person_add_alt_1_outlined,
                          ),
                          label: const Text('Register User'),
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
  }

  TextFormField _requiredField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? '$label is required' : null,
    );
  }

  TextFormField _phoneField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) {
          return '$label is required';
        }
        if (text.length < 7) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  TextFormField _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Temporary password',
        helperText: 'Stored in Firebase Auth, not in Firestore.',
      ),
      validator: (value) {
        final text = value ?? '';
        if (text.length < 8) {
          return 'Use at least 8 characters';
        }
        if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
            !RegExp(r'[0-9]').hasMatch(text)) {
          return 'Use letters and numbers';
        }
        return null;
      },
    );
  }
}

class _EmailVerificationSection extends StatelessWidget {
  const _EmailVerificationSection({
    required this.emailController,
    required this.emailFieldKey,
    required this.verification,
    required this.busy,
    required this.onEmailChanged,
    required this.onSendVerification,
    required this.onResendVerification,
    required this.onCheckStatus,
    required this.onUseDifferentEmail,
  });

  final TextEditingController emailController;
  final GlobalKey<FormFieldState<String>> emailFieldKey;
  final RegistrationEmailVerificationSnapshot verification;
  final bool busy;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSendVerification;
  final VoidCallback onResendVerification;
  final VoidCallback onCheckStatus;
  final VoidCallback onUseDifferentEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final phase = verification.phase;
    final email = emailController.text.trim();
    final isVerified =
        verification.isVerified && verification.matchesEmail(email);
    final isPending =
        phase == RegistrationEmailVerificationPhase.pending && !isVerified;
    final isSending = phase == RegistrationEmailVerificationPhase.sending;
    final status = _VerificationStatus.from(
      isVerified: isVerified,
      isPending: isPending,
      isSending: isSending,
      colorScheme: colorScheme,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.accent.withValues(alpha: 0.14),
            colorScheme.surfaceContainerHighest,
          ],
        ),
        border: Border.all(
          color: status.accent.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: status.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: status.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    status.headerIcon,
                    color: status.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified
                            ? 'Step 1 · Email verified'
                            : 'Step 1 · Verify email',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                _VerificationBadge(status: status),
              ],
            ),
            const SizedBox(height: 18),
            if (isVerified)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verified email',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This inbox is confirmed. Complete the registration details in Step 2 below.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : onUseDifferentEmail,
                      child: const Text('Change email'),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: emailFieldKey,
                        controller: emailController,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: onEmailChanged,
                        decoration: InputDecoration(
                          labelText: 'Email to verify',
                          hintText: 'user@example.com',
                          prefixIcon: const Icon(Icons.alternate_email),
                          suffixIcon: _EmailSuffixIcon(
                            isVerified: isVerified,
                            isPending: isPending,
                            isSending: isSending,
                            accent: status.accent,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(text)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : (isPending
                                  ? onResendVerification
                                  : onSendVerification),
                        icon: AppAsyncButtonIcon(
                          isLoading: busy,
                          icon: isPending
                              ? Icons.refresh_rounded
                              : Icons.send_rounded,
                        ),
                        label: Text(
                          isSending
                              ? 'Sending…'
                              : isPending
                              ? 'Resend link'
                              : 'Send verification email',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isPending)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            color: colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting for the user to open the verification link.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: busy ? null : onCheckStatus,
                            icon: const Icon(Icons.task_alt_rounded),
                            label: const Text('Check status'),
                          ),
                          TextButton.icon(
                            onPressed: busy ? null : onResendVerification,
                            icon: const Icon(Icons.mail_outline_rounded),
                            label: const Text('Send again'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (verification.errorMessage != null &&
                phase != RegistrationEmailVerificationPhase.verified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  verification.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerificationStatus {
  const _VerificationStatus({
    required this.accent,
    required this.headerIcon,
    required this.badgeLabel,
    required this.subtitle,
  });

  final Color accent;
  final IconData headerIcon;
  final String badgeLabel;
  final String subtitle;

  factory _VerificationStatus.from({
    required bool isVerified,
    required bool isPending,
    required bool isSending,
    required ColorScheme colorScheme,
  }) {
    if (isVerified) {
      return _VerificationStatus(
        accent: Colors.green,
        headerIcon: Icons.mark_email_read,
        badgeLabel: 'Verified',
        subtitle:
            'This inbox is already confirmed. Complete the registration details in Step 2.',
      );
    }
    if (isSending) {
      return _VerificationStatus(
        accent: colorScheme.primary,
        headerIcon: Icons.send_rounded,
        badgeLabel: 'Sending',
        subtitle: 'Sending a secure verification link to the user\'s inbox…',
      );
    }
    if (isPending) {
      return _VerificationStatus(
        accent: colorScheme.tertiary,
        headerIcon: Icons.mark_email_unread,
        badgeLabel: 'Pending',
        subtitle:
            'A verification link was sent. The user must open it before you can register them.',
      );
    }
    return _VerificationStatus(
      accent: colorScheme.error,
      headerIcon: Icons.lock_outline,
      badgeLabel: 'Unverified',
      subtitle:
          'Send a verification link to the user\'s inbox. Registration unlocks after they confirm the email.',
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});

  final _VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.badgeLabel,
        style: TextStyle(
          color: status.accent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmailSuffixIcon extends StatelessWidget {
  const _EmailSuffixIcon({
    required this.isVerified,
    required this.isPending,
    required this.isSending,
    required this.accent,
  });

  final bool isVerified;
  final bool isPending;
  final bool isSending;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (isSending) {
      return AppAsyncProgressIcon(
        isLoading: true,
        color: accent,
        idle: const SizedBox.shrink(),
      );
    }
    if (isVerified) {
      return const Icon(Icons.verified_rounded, color: Colors.green);
    }
    if (isPending) {
      return Icon(Icons.schedule, color: accent);
    }
    return Icon(Icons.highlight_off_outlined, color: accent);
  }
}
