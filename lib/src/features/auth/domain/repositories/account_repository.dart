import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/account_entity.dart';
import '../entities/account_health_check_entity.dart';
import '../entities/social_page_entity.dart';

abstract class AccountRepository extends BaseRepository<AccountEntity> {
  const AccountRepository();

  Future<AppResult<List<AccountEntity>>> getAccounts({required String userId});
  Future<AppResult<AccountEntity>> connectAccount(
    AccountEntity account, {
    required String userId,
  });
  Future<AppResult<void>> disconnectAccount(
    AccountEntity account, {
    required String userId,
  });
  Future<AppResult<AccountEntity>> refreshToken(
    AccountEntity account, {
    required String userId,
  });

  /// Verifies this specific connection's stored access token still works —
  /// distinct from System Settings' app-level Test Connection. Callers
  /// should reload the account list afterward since a real check can flip
  /// [AccountEntity.status] server-side (self-healing or newly-expired).
  Future<AppResult<AccountHealthCheckEntity>> testConnection(
    AccountEntity account, {
    required String userId,
  });

  /// Connects a real Telegram bot (no OAuth — a Bot Token from @BotFather).
  Future<AppResult<AccountEntity>> connectTelegramBot({
    required String userId,
    required String botToken,
  });

  Future<AppResult<List<SocialPageEntity>>> getPages(
    AccountEntity account, {
    required String userId,
  });

  /// Facebook/Instagram-style accounts re-fetch the full page list; Telegram/
  /// WhatsApp-style accounts re-verify each already-added channel instead.
  Future<AppResult<List<SocialPageEntity>>> syncPages(
    AccountEntity account, {
    required String userId,
  });

  /// Manually adds and verifies a channel/page by its provider identifier
  /// (Telegram: `@channel` or a numeric chat id).
  Future<AppResult<SocialPageEntity>> addPage(
    AccountEntity account, {
    required String userId,
    required String identifier,
  });

  Future<AppResult<List<SocialPageEntity>>> selectPages(
    AccountEntity account, {
    required String userId,
    required List<String> pageIds,
  });

  Future<AppResult<void>> deletePage(
    AccountEntity account, {
    required String userId,
    required String pageId,
  });

  /// Starts the real Facebook OAuth redirect flow — returns the Facebook
  /// authorize URL to navigate the browser to (no in-app webview/popup).
  Future<AppResult<String>> beginFacebookOAuth({
    required String userId,
    required String redirectUri,
  });

  /// Completes the Facebook OAuth flow after the browser redirects back with
  /// `code`/`state` query parameters.
  Future<AppResult<AccountEntity>> completeFacebookOAuth({
    required String userId,
    required String code,
    required String state,
  });

  /// Android/iOS only: completes a native Facebook sign-in (the
  /// flutter_facebook_auth SDK, not a browser redirect) by handing its own
  /// real access token to the backend for independent server-side
  /// re-verification against Meta's /debug_token — never trust a
  /// client-asserted token at face value. Distinct from
  /// [beginFacebookOAuth]/[completeFacebookOAuth], which remain unchanged
  /// for web/desktop.
  Future<AppResult<AccountEntity>> connectFacebookNative({
    required String userId,
    required String accessToken,
  });

  /// Starts the real WhatsApp OAuth redirect flow — WhatsApp Business
  /// connects via Facebook Login under the hood, same as [beginFacebookOAuth].
  Future<AppResult<String>> beginWhatsAppOAuth({
    required String userId,
    required String redirectUri,
  });

  /// Completes the WhatsApp OAuth flow. The returned account will not yet
  /// have a Meta Business ID — call [setWhatsAppBusinessId] next before
  /// pages/numbers can be discovered.
  Future<AppResult<AccountEntity>> completeWhatsAppOAuth({
    required String userId,
    required String code,
    required String state,
  });

  /// One-time manual input: the Meta Business ID needed to look up WhatsApp
  /// Business Accounts and phone numbers under it (can't always be derived
  /// from the access token alone).
  Future<AppResult<AccountEntity>> setWhatsAppBusinessId({
    required String userId,
    required String socialAccountId,
    required String businessId,
  });
}
