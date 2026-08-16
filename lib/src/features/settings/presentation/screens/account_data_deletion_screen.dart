import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): self-service account deletion request —
/// POST /account/data-deletion-requests. Deliberately NOT instant: the
/// backend only records the request for an operator's review (connected
/// providers can require token revocation, and a deployment can have
/// legal retention duties) — this screen's copy says so explicitly rather
/// than implying the account is deleted the moment this is submitted.
class AccountDataDeletionScreen extends ConsumerStatefulWidget {
  const AccountDataDeletionScreen({super.key});

  @override
  ConsumerState<AccountDataDeletionScreen> createState() =>
      _AccountDataDeletionScreenState();
}

class _AccountDataDeletionScreenState
    extends ConsumerState<AccountDataDeletionScreen> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _confirmed = false;
  bool _submitting = false;
  String? _error;
  String? _successStatus;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_confirmed) {
      setState(() => _error = l10n.dataDeletionConfirmValidationError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authSessionControllerProvider)
          .requestAccountDeletion(reason: _reasonController.text);
      if (!mounted) {
        return;
      }
      setState(() => _successStatus = result.status);
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataDeletionAppBarTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _successStatus != null
                ? _buildSuccess(l10n, colorScheme)
                : _buildForm(l10n, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l10n, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.dataDeletionSuccessTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.dataDeletionSuccessMessage(_successStatus!),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_outlined,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.dataDeletionWarningTitle,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.dataDeletionWarningMessage,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.dataDeletionReasonLabel,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value ?? false),
            title: Text(l10n.dataDeletionConfirmCheckboxLabel),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(_error!, style: TextStyle(color: colorScheme.error)),
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.dataDeletionSubmitButton),
          ),
        ],
      ),
    );
  }
}
