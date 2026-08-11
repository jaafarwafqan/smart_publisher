import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): the forgot-password step
/// (POST /api/v1/auth/forgot-password). Always shows the same generic
/// success message regardless of whether the email is registered — the
/// backend itself is deliberately silent about that to avoid leaking
/// which emails exist, and the UI must not undo that by reacting
/// differently to a "real" vs. "unknown" email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
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
          .forgotPassword(email: _emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _submitted = true);
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

    // A live visual review caught this: with the title living in a plain
    // AppBar and the card vertically centered below it, desktop viewports
    // left a large empty gap between them, reading as two disconnected
    // pieces of UI rather than one form. Restructured to match
    // LoginScreen/RegisterScreen exactly — gradient background, no
    // opaque AppBar, title+subtitle as the first elements inside the same
    // card as the form — so all three auth screens read as one continuous
    // flow. A transparent AppBar is kept (title-less, back arrow only) so
    // push()-based back navigation from the login screen still has an
    // explicit on-screen affordance, without reintroducing the visual gap.
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[colorScheme.primary, colorScheme.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: _submitted
                        ? _SuccessState(
                            l10n: l10n,
                            onBackToLogin: () =>
                                context.go(RouteNames.loginPath),
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  l10n.forgotPasswordTitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.forgotPasswordSubtitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: l10n.forgotPasswordEmailLabel,
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
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
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
                                      : Text(l10n.forgotPasswordSubmitButton),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: () => context.push(
                                    RouteNames.resetPasswordPath,
                                  ),
                                  child: Text(l10n.forgotPasswordHaveTokenLink),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.go(RouteNames.loginPath),
                                  child: Text(
                                    l10n.forgotPasswordBackToLoginLink,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.l10n, required this.onBackToLogin});

  final AppLocalizations l10n;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.mark_email_read_outlined,
          size: AppIconSize.xl,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.forgotPasswordSuccessMessage, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: onBackToLogin,
          child: Text(l10n.forgotPasswordBackToLoginLink),
        ),
      ],
    );
  }
}
