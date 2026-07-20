import 'secure_token_storage.dart';
import 'token_bundle.dart';

typedef RefreshExecutor = Future<TokenBundle?> Function(String refreshToken);

class TokenLifecycleManager {
  TokenLifecycleManager({
    required this.tokenStorage,
    this.refreshExecutor,
    this.refreshWindow = const Duration(minutes: 2),
  });

  final SecureTokenStorage tokenStorage;
  final RefreshExecutor? refreshExecutor;
  final Duration refreshWindow;

  Future<TokenBundle?> readTokens() {
    return tokenStorage.readTokens();
  }

  Future<void> writeTokens(TokenBundle bundle) {
    return tokenStorage.saveTokens(bundle);
  }

  Future<void> clearTokens() {
    return tokenStorage.clearTokens();
  }

  Future<String?> getValidAccessToken() async {
    final tokens = await tokenStorage.readTokens();
    if (tokens == null) {
      return null;
    }

    if (!tokens.isExpired && !tokens.willExpireWithin(refreshWindow)) {
      return tokens.accessToken;
    }

    final refreshed = await refreshAccessToken();
    return refreshed;
  }

  Future<String?> refreshAccessToken() async {
    final tokens = await tokenStorage.readTokens();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      return null;
    }

    if (refreshExecutor == null) {
      if (!tokens.isExpired) {
        return tokens.accessToken;
      }
      return null;
    }

    final rotated = await refreshExecutor!.call(tokens.refreshToken);
    if (rotated == null) {
      return null;
    }

    await tokenStorage.saveTokens(rotated);
    return rotated.accessToken;
  }
}
