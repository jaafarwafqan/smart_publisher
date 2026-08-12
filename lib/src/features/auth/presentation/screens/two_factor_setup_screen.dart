import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../application/auth_session_controller.dart';

enum _Stage {
  loading,
  disabled,
  enabling,
  showRecoveryCodes,
  enabled,
  disabling,
}

/// Sprint 4 (Commercial SaaS): enable/confirm/disable TOTP-based MFA for
/// the currently authenticated user. Reached from Settings ->
/// "Two-factor authentication".
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  _Stage _stage = _Stage.loading;
  String? _secret;
  String? _otpauthUrl;
  List<String> _recoveryCodes = const <String>[];
  String? _error;
  bool _busy = false;

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmFormKey = GlobalKey<FormState>();
  final _disableFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _stage = _Stage.loading;
      _error = null;
    });
    try {
      final status = await ref
          .read(authSessionControllerProvider)
          .fetchCurrentUserStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = status.twoFactorEnabled ? _Stage.enabled : _Stage.disabled;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _Stage.disabled;
        _error = error is AuthSessionException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _startEnable() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ref.read(twoFactorControllerProvider).enable();
      if (!mounted) {
        return;
      }
      setState(() {
        _secret = response.secret;
        _otpauthUrl = response.otpauthUrl;
        _stage = _Stage.enabling;
      });
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
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirm() async {
    if (!_confirmFormKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(twoFactorControllerProvider)
          .confirm(code: _codeController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _recoveryCodes = response.recoveryCodes;
        _stage = _Stage.showRecoveryCodes;
      });
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
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _disable() async {
    if (!_disableFormKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(twoFactorControllerProvider)
          .disable(password: _passwordController.text);
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      setState(() => _stage = _Stage.disabled);
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
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copy(String value, String confirmationMessage) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(confirmationMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.twoFactorSetupAppBarTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: _buildStage(l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.loading:
        return const Center(child: CircularProgressIndicator());
      case _Stage.disabled:
        return _buildDisabledStage(l10n);
      case _Stage.enabling:
        return _buildEnablingStage(l10n);
      case _Stage.showRecoveryCodes:
        return _buildRecoveryCodesStage(l10n);
      case _Stage.enabled:
        return _buildEnabledStage(l10n);
      case _Stage.disabling:
        return _buildDisablingStage(l10n);
    }
  }

  Widget _buildDisabledStage(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.shield_outlined,
          size: AppIconSize.xl,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.twoFactorSetupDisabledStatus, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.twoFactorSetupIntro,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) _ErrorBanner(message: _error!),
        FilledButton(
          onPressed: _busy ? null : _startEnable,
          child: _busy
              ? const SizedBox(
                  width: AppIconSize.md,
                  height: AppIconSize.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.twoFactorSetupEnableButton),
        ),
      ],
    );
  }

  Widget _buildEnablingStage(AppLocalizations l10n) {
    return Form(
      key: _confirmFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l10n.twoFactorSetupSecretLabel, style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          _CopyableField(
            value: _secret ?? '',
            onCopy: () =>
                _copy(_secret ?? '', l10n.twoFactorSetupCopiedMessage),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.twoFactorSetupSecretHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.twoFactorSetupOtpAuthUrlLabel, style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          _CopyableField(
            value: _otpauthUrl ?? '',
            onCopy: () =>
                _copy(_otpauthUrl ?? '', l10n.twoFactorSetupCopiedMessage),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.twoFactorSetupCodeLabel,
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return l10n.twoFactorSetupCodeValidationError;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null) _ErrorBanner(message: _error!),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _stage = _Stage.disabled),
                  child: Text(l10n.twoFactorSetupCancelButton),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: _busy
                      ? const SizedBox(
                          width: AppIconSize.md,
                          height: AppIconSize.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.twoFactorSetupConfirmButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodesStage(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.check_circle_outline,
          size: AppIconSize.xl,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.twoFactorSetupRecoveryCodesTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.twoFactorSetupRecoveryCodesWarning,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            children: _recoveryCodes
                .map(
                  (code) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _copy(
            _recoveryCodes.join('\n'),
            l10n.twoFactorSetupCopiedMessage,
          ),
          icon: const Icon(Icons.copy_outlined),
          label: Text(l10n.twoFactorSetupCopyTooltip),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => setState(() => _stage = _Stage.enabled),
          child: Text(l10n.twoFactorSetupDoneButton),
        ),
      ],
    );
  }

  Widget _buildEnabledStage(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.verified_user_outlined,
          size: AppIconSize.xl,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.twoFactorSetupEnabledStatus, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) _ErrorBanner(message: _error!),
        OutlinedButton(
          onPressed: () => setState(() {
            _stage = _Stage.disabling;
            _error = null;
          }),
          child: Text(l10n.twoFactorSetupDisableButton),
        ),
      ],
    );
  }

  Widget _buildDisablingStage(AppLocalizations l10n) {
    return Form(
      key: _disableFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.twoFactorSetupDisablePasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return l10n.twoFactorSetupDisablePasswordValidationError;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null) _ErrorBanner(message: _error!),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _stage = _Stage.enabled;
                          _error = null;
                        }),
                  child: Text(l10n.twoFactorSetupCancelButton),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _disable,
                  child: _busy
                      ? const SizedBox(
                          width: AppIconSize.md,
                          height: AppIconSize.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.twoFactorSetupDisableConfirmButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({required this.value, required this.onCopy});

  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.twoFactorSetupCopyTooltip,
            icon: const Icon(Icons.copy_outlined),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(message, style: TextStyle(color: colorScheme.error)),
    );
  }
}
