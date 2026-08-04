/// Parses a Facebook OAuth redirect landing on the app's root URL —
/// `?code=...&state=...` on success, `?error=...&error_description=...` if
/// the user denied consent. Pulled out as a pure function (rather than
/// inlined in a widget) so it's testable without touching the real browser
/// location.
class FacebookOAuthCallback {
  const FacebookOAuthCallback._({this.code, this.state, this.error});

  final String? code;
  final String? state;
  final String? error;

  bool get isCallback => code != null || error != null;
  bool get isSuccess => code != null && state != null;

  static const FacebookOAuthCallback none = FacebookOAuthCallback._();

  factory FacebookOAuthCallback.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final error = params['error'];
    if (error != null && error.isNotEmpty) {
      return FacebookOAuthCallback._(error: error);
    }

    final code = params['code'];
    final state = params['state'];
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return FacebookOAuthCallback.none;
    }

    return FacebookOAuthCallback._(code: code, state: state);
  }
}
