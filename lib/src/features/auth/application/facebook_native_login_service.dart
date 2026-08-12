import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Android/iOS only wrapper around the flutter_facebook_auth SDK — the
/// existing browser-redirect OAuth flow in dashboard_screen.dart
/// (beginFacebookOAuth/completeFacebookOAuth) remains the only path on
/// Flutter Web and desktop, unchanged.
sealed class FacebookNativeLoginResult {
  const FacebookNativeLoginResult();
}

class FacebookNativeLoginSuccess extends FacebookNativeLoginResult {
  const FacebookNativeLoginSuccess(this.accessToken);

  final String accessToken;
}

/// The user explicitly declined the consent dialog — this must not
/// silently fall back to the browser OAuth flow (that would just show the
/// same consent dialog again in a different UI, defeating the point of
/// respecting the user's answer); only a clear "you said no" message.
class FacebookNativeLoginCancelled extends FacebookNativeLoginResult {
  const FacebookNativeLoginCancelled();
}

/// The SDK flow itself broke down for a reason unrelated to user consent —
/// a platform exception, the real Facebook app not being installed and its
/// own browser fallback also failing, a misconfigured native App
/// ID/Client Token. Safe (and correct, per the spec's own edge-case list)
/// to fall back to Smart Publisher's existing browser OAuth flow from here.
class FacebookNativeLoginFailed extends FacebookNativeLoginResult {
  const FacebookNativeLoginFailed(this.message);

  final String message;
}

class FacebookNativeLoginService {
  const FacebookNativeLoginService();

  /// Kept identical to _facebookOAuthScopes in account_repository_impl.dart
  /// (the web/desktop browser flow) — both paths must request exactly the
  /// permissions actually used, nothing broader.
  static const List<String> permissions = <String>[
    'pages_show_list',
    'pages_read_engagement',
    'pages_manage_posts',
  ];

  /// True only on a real Android/iOS build. Flutter Web reports a
  /// TargetPlatform matching the host OS too (e.g. android Chrome), so
  /// `!kIsWeb` must be checked first — this method must never be called
  /// from a web build regardless of what device is browsing it.
  bool get isSupportedOnThisPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<FacebookNativeLoginResult> login() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: permissions,
        // The SDK's default (LoginTracking.limited) returns an
        // App-Tracking-Transparency-safe identity token that Meta's Graph
        // API rejects for page discovery/publishing — .enabled ("classic"
        // tracking in Meta's own terminology) is the real OAuth access
        // token our backend's verifyNativeToken()/listPages()/publishPost()
        // actually need, the same kind of token the browser-redirect flow
        // already produces.
        loginTracking: LoginTracking.enabled,
      );

      switch (result.status) {
        case LoginStatus.success:
          final token = result.accessToken?.tokenString;
          if (token == null || token.isEmpty) {
            return const FacebookNativeLoginFailed(
              'Facebook did not return an access token.',
            );
          }
          return FacebookNativeLoginSuccess(token);
        case LoginStatus.cancelled:
          return const FacebookNativeLoginCancelled();
        case LoginStatus.failed:
          return FacebookNativeLoginFailed(
            result.message ?? 'Facebook sign-in failed.',
          );
        case LoginStatus.operationInProgress:
          return const FacebookNativeLoginFailed(
            'A Facebook sign-in is already in progress.',
          );
      }
    } catch (e) {
      return FacebookNativeLoginFailed(e.toString());
    }
  }

  /// Best-effort — clears the SDK's own cached session so the next attempt
  /// starts from a real consent prompt instead of silently reusing a token
  /// the backend just rejected (e.g. it was actually for a different app,
  /// or Meta has since forced re-auth).
  Future<void> logOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Nothing meaningful to surface if there was no active SDK session
      // to clear — this is cleanup, not a user-facing operation.
    }
  }
}
