class ScopeAuthorizer {
  const ScopeAuthorizer();

  bool hasScopes({
    required Set<String> grantedScopes,
    required Set<String> requiredScopes,
  }) {
    if (requiredScopes.isEmpty) {
      return true;
    }
    return requiredScopes.every(grantedScopes.contains);
  }
}
