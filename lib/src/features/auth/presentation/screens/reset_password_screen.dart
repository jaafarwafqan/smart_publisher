import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): the reset-password step
/// (POST /api/v1/auth/reset-password). The reset token is entered
/// manually here rather than parsed from a deep link — there is no real
/// mail provider wired yet (MAIL_MAILER=log per the user's Sprint 4
/// decision), so today the token is read out of the backend's own log by
/// whoever operates it and handed to the account holder out of band.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _succeeded = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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
          .resetPassword(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmationController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() => _succeeded = true);
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
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: _succeeded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_outline,
                            size: AppIconSize.xl,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.resetPasswordSuccessMessage,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: () => context.go(RouteNames.loginPath),
                            child: Text(l10n.resetPasswordBackToLoginLink),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              l10n.resetPasswordSubtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.resetPasswordEmailLabel,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty || !text.contains('@')) {
                                  return l10n
                                      .forgotPasswordEmailValidationError;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _tokenController,
                              decoration: InputDecoration(
                                labelText: l10n.resetPasswordTokenLabel,
                                prefixIcon: const Icon(Icons.vpn_key_outlined),
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return l10n.resetPasswordTokenLabel;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: l10n.resetPasswordNewPasswordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if ((value ?? '').length < 8) {
                                  return l10n
                                      .resetPasswordPasswordValidationError;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _passwordConfirmationController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.resetPasswordConfirmPasswordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return l10n
                                      .resetPasswordConfirmPasswordValidationError;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _submitting ? null : _submit(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
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
                                  : Text(l10n.resetPasswordSubmitButton),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: () => context.go(RouteNames.loginPath),
                              child: Text(l10n.resetPasswordBackToLoginLink),
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
