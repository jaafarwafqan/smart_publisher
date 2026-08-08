import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): a persistent nudge shown while the
/// account's email is unverified, with a resend action
/// (POST /auth/email/verification-notification). Fails closed toward
/// showing nothing rather than blocking the screen — a status-check
/// failure (offline, etc.) must not itself become an intrusive error.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  bool? _verified;
  bool _resending = false;
  String? _resendError;
  bool _resendSucceeded = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ref
          .read(authSessionControllerProvider)
          .fetchCurrentUserStatus();
      if (!mounted) {
        return;
      }
      setState(() => _verified = status.emailVerified);
    } catch (_) {
      // Fail closed toward showing nothing — see class docblock.
      if (mounted) {
        setState(() => _verified = true);
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendError = null;
    });
    try {
      await ref.read(authSessionControllerProvider).resendVerificationEmail();
      if (!mounted) {
        return;
      }
      setState(() => _resendSucceeded = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resendError = error is AuthSessionException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified != false) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.mark_email_unread_outlined,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _resendSucceeded
                    ? l10n.emailVerificationResendSuccess
                    : (_resendError ?? l10n.emailVerificationBannerMessage),
                style: TextStyle(color: colorScheme.onTertiaryContainer),
              ),
            ),
            if (!_resendSucceeded)
              TextButton(
                onPressed: _resending ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.emailVerificationBannerResendButton),
              ),
          ],
        ),
      ),
    );
  }
}
