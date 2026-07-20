class OAuthConfiguration {
  const OAuthConfiguration({
    required this.clientId,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.redirectUri,
    this.defaultScopes = const <String>{},
  });

  final String clientId;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri redirectUri;
  final Set<String> defaultScopes;
}

class OAuthManager {
  const OAuthManager(this.configuration);

  final OAuthConfiguration configuration;

  Uri buildAuthorizationUri({
    Set<String> scopes = const <String>{},
    String? state,
  }) {
    final effectiveScopes = <String>{...configuration.defaultScopes, ...scopes};

    return configuration.authorizationEndpoint.replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': configuration.clientId,
        'redirect_uri': configuration.redirectUri.toString(),
        'scope': effectiveScopes.join(' '),
        if (state != null && state.isNotEmpty) 'state': state,
      },
    );
  }
}
