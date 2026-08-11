import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../application/auth_session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(authSessionControllerProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      switch (outcome) {
        case LoginRequiresTwoFactor(:final challengeToken):
          context.push(
            RouteNames.twoFactorChallengePath,
            extra: challengeToken,
          );
          return;
        case LoginSuccess():
          ref.invalidate(authStateProvider);
          ref.invalidate(currentUserRoleProvider);
          ref.invalidate(currentOrganizationAccessProvider);
          ref.invalidate(firstLaunchProvider);
          context.go(RouteNames.dashboardPath);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = error is AuthSessionException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
    // Deliberately no `finally`-style reset of _submitting on the success
    // paths above: context.go()/context.push() only *start* navigation —
    // GoRouter's async redirect (RouteGuards.guardPath) still has to
    // resolve, which does real sequential network calls
    // (currentPlatformAdminProvider, then currentOrganizationAccessProvider)
    // before the new route actually replaces this screen. A prior version
    // reset _submitting unconditionally here, so during that window the
    // form re-enabled itself and looked like a fresh, unsubmitted login
    // screen — confusing enough that a live tester read it as "login
    // succeeds in the backend but the UI stays on the login page." Leaving
    // the button in its loading state until this widget is actually
    // disposed by the route change gives continuous, honest feedback
    // instead.
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: const Icon(
                              Icons.campaign_outlined,
                              color: Colors.white,
                              size: AppIconSize.xl,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.loginTitle,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.loginSubtitle,
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
                              labelText: l10n.loginEmailLabel,
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty || !text.contains('@')) {
                                return l10n.loginEmailValidationError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.loginPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 6) {
                                return l10n.loginPasswordValidationError;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                _submitting ? null : _login(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (_error != null)
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.error_outline,
                                      color: colorScheme.onErrorContainer,
                                      size: AppIconSize.md,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submitting ? null : _login,
                              child: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(l10n.loginButton),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => context.push(
                                        RouteNames.forgotPasswordPath,
                                      ),
                                child: Text(l10n.loginForgotPasswordLink),
                              ),
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(
                                l10n.loginNoAccountPrompt,
                                style: textTheme.bodySmall,
                              ),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () =>
                                          context.push(RouteNames.registerPath),
                                child: Text(l10n.loginCreateAccountLink),
                              ),
                            ],
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  context.push(RouteNames.aboutPath),
                              child: Text(
                                l10n.welcomeAboutLinkLabel(l10n.appName),
                              ),
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
