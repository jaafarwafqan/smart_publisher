import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_guard_snapshot_cache.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): completes a login that
/// [AuthSessionController.login] paused on with [LoginRequiresTwoFactor] —
/// reached via `context.push(RouteNames.twoFactorChallengePath, extra:
/// challengeToken)` from [LoginScreen]. The challenge_token is opaque,
/// single-use, and expires in 5 minutes server-side.
class TwoFactorChallengeScreen extends ConsumerStatefulWidget {
  const TwoFactorChallengeScreen({required this.challengeToken, super.key});

  final String challengeToken;

  @override
  ConsumerState<TwoFactorChallengeScreen> createState() =>
      _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState
    extends ConsumerState<TwoFactorChallengeScreen> {
  final _codeController = TextEditingController();
  final _recoveryCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useRecoveryCode = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authSessionControllerProvider)
          .completeTwoFactorChallenge(
            challengeToken: widget.challengeToken,
            code: _useRecoveryCode ? null : _codeController.text.trim(),
            recoveryCode: _useRecoveryCode
                ? _recoveryCodeController.text.trim()
                : null,
          );
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserRoleProvider);
      ref.invalidate(currentOrganizationAccessProvider);
      ref.invalidate(firstLaunchProvider);
      // See login_screen.dart: RouteGuardSnapshotCache is not a Riverpod
      // provider and survives the provider invalidations above.
      ref.read(routeGuardSnapshotCacheProvider).invalidate();
      if (!mounted) {
        return;
      }
      context.go(RouteNames.dashboardPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is AuthSessionException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.twoFactorChallengeTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        size: AppIconSize.xl,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.twoFactorChallengeSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_useRecoveryCode)
                        TextFormField(
                          key: const ValueKey('recovery-code-field'),
                          controller: _recoveryCodeController,
                          decoration: InputDecoration(
                            labelText: l10n.twoFactorChallengeRecoveryCodeLabel,
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n
                                  .twoFactorChallengeRecoveryCodeValidationError;
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          key: const ValueKey('code-field'),
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: l10n.twoFactorChallengeCodeLabel,
                            prefixIcon: const Icon(Icons.pin_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n.twoFactorChallengeCodeValidationError;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) =>
                              _submitting ? null : _submit(),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _useRecoveryCode = !_useRecoveryCode;
                                _error = null;
                              }),
                        child: Text(
                          _useRecoveryCode
                              ? l10n.twoFactorChallengeUseCodeLink
                              : l10n.twoFactorChallengeUseRecoveryCodeLink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _error!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: AppIconSize.md,
                                height: AppIconSize.md,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.twoFactorChallengeSubmitButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
