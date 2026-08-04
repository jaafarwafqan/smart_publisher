class ScopeAuthorizer {
  const ScopeAuthorizer();

  static const String wildcardScope = '*';

  bool hasScopes({
    required Set<String> grantedScopes,
    required Set<String> requiredScopes,
  }) {
    if (requiredScopes.isEmpty) {
      return true;
    }
    if (grantedScopes.contains(wildcardScope)) {
      return true;
    }
    return requiredScopes.every(grantedScopes.contains);
  }
}
