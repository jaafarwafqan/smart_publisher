import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Locale;

import 'package:smart_publisher/l10n/app_localizations.dart';
import 'package:smart_publisher/l10n/app_localizations_ar.dart';
import 'package:smart_publisher/l10n/app_localizations_en.dart';

import '../../../backend_contracts/v1/account_contract_v1.dart';
import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/auth_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/router/guard_state_provider.dart';
import '../../../core/security/token_bundle.dart';
import '../../../core/security/token_lifecycle_manager.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/entities/user_entity.dart';
import 'auth_event_publisher.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.role,
    this.isPlatformAdmin = false,
  });

  final UserEntity user;
  final UserRole role;
  final bool isPlatformAdmin;
}

/// The result of [AuthSessionController.login] — a password match alone is
/// not a completed login once the account has 2FA enabled (see Sprint 4's
/// backend AuthController::login(), which short-circuits into a
/// challenge_token instead of issuing real tokens in that case).
sealed class LoginOutcome {
  const LoginOutcome();
}

class LoginSuccess extends LoginOutcome {
  const LoginSuccess(this.session);

  final AuthSession session;
}

class LoginRequiresTwoFactor extends LoginOutcome {
  const LoginRequiresTwoFactor(this.challengeToken);

  final String challengeToken;
}

class AuthSessionException implements Exception {
  const AuthSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSessionController {
  AuthSessionController({
    required this.networkClient,
    required this.tokenLifecycleManager,
    required this.storageService,
    required this.authEventPublisher,
    this.localeReader,
  });

  final NetworkClient networkClient;
  final TokenLifecycleManager tokenLifecycleManager;
  final StorageService storageService;
  final AuthEventPublisher authEventPublisher;
  // Same convention as LocaleHeaderInterceptor: a plain Dart service class
  // has no BuildContext to read AppLocalizations.of() from, so the current
  // locale is threaded in as a callback instead. Nullable/defaults to
  // English so tests that never wire this up keep working — only the 3
  // client-synthesized fallback strings in _messageFromDio below are
  // affected; every other message already comes pre-localized from the
  // backend (see backend_error_message.dart's docblock).
  final Locale Function()? localeReader;

  static const _userIdKey = 'auth.user.id';
  static const _userNameKey = 'auth.user.name';
  static const _userEmailKey = 'auth.user.email';

  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.authLogin,
        data: LoginRequestDtoV1(email: email, password: password).toJson(),
        options: Options(headers: <String, Object>{'Authorization': ''}),
      );

      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException('Invalid login response from server.');
      }

      if (payload['two_factor_required'] == true) {
        final challengeToken = (payload['challenge_token'] ?? '').toString();
        if (challengeToken.trim().isEmpty) {
          throw const AuthSessionException(
            'Two-factor challenge token is missing from server response.',
          );
        }
        return LoginRequiresTwoFactor(challengeToken);
      }

      return LoginSuccess(await _finalizeSession(payload));
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    } catch (error) {
      throw AuthSessionException(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Sprint 4 (Commercial SaaS): public self-registration — auto-logs the
  /// new account in exactly like [login] on success (same token pair
  /// shape), so this returns a completed [AuthSession] directly rather than
  /// a [LoginOutcome]: a brand-new account can never already have 2FA
  /// confirmed.
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.authRegister,
        data: RegisterRequestDtoV1(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ).toJson(),
        options: Options(headers: <String, Object>{'Authorization': ''}),
      );

      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid registration response from server.',
        );
      }

      return _finalizeSession(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    } catch (error) {
      throw AuthSessionException(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Completes a login that [login] paused on with [LoginRequiresTwoFactor]
  /// — exactly one of [code] (a TOTP code) or [recoveryCode] must be
  /// provided, matching the backend's own either/or validation.
  Future<AuthSession> completeTwoFactorChallenge({
    required String challengeToken,
    String? code,
    String? recoveryCode,
  }) async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.authTwoFactorChallenge,
        data: <String, dynamic>{
          'challenge_token': challengeToken,
          if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
          if (recoveryCode != null && recoveryCode.trim().isNotEmpty)
            'recovery_code': recoveryCode.trim(),
        },
        options: Options(headers: <String, Object>{'Authorization': ''}),
      );

      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid two-factor challenge response from server.',
        );
      }

      return _finalizeSession(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    } catch (error) {
      throw AuthSessionException(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Always succeeds from the caller's point of view — the backend
  /// deliberately returns the same generic message whether or not the
  /// email belongs to a real account, to avoid leaking which emails are
  /// registered.
  Future<void> forgotPassword({required String email}) async {
    try {
      await networkClient.post(
        LaravelEndpoints.authForgotPassword,
        data: ForgotPasswordRequestDtoV1(email: email).toJson(),
        options: Options(headers: <String, Object>{'Authorization': ''}),
      );
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await networkClient.post(
        LaravelEndpoints.authResetPassword,
        data: ResetPasswordRequestDtoV1(
          email: email,
          token: token,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ).toJson(),
        options: Options(headers: <String, Object>{'Authorization': ''}),
      );
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  /// Requires an active session — resends the verification link for the
  /// currently authenticated (but not yet verified) account.
  Future<void> resendVerificationEmail() async {
    try {
      await networkClient.post(LaravelEndpoints.authEmailVerificationResend);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  /// Reads the current account's 2FA/verification status from GET /me —
  /// there is no dedicated status endpoint for either.
  Future<CurrentUserStatusDtoV1> fetchCurrentUserStatus() async {
    try {
      final response = await networkClient.get(LaravelEndpoints.me);
      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid account status response from server.',
        );
      }
      return CurrentUserStatusDtoV1.fromJson(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  /// GET /account/data-export — spans every organization the account has
  /// ever belonged to, not just the currently active one (matches the
  /// backend's own scope for this endpoint).
  Future<DataExportDtoV1> exportMyData() async {
    try {
      final response = await networkClient.get(
        LaravelEndpoints.accountDataExport,
      );
      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid data export response from server.',
        );
      }
      return DataExportDtoV1.fromJson(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  /// POST /account/data-deletion-requests — records a request for an
  /// operator to review; does not delete anything immediately (see the
  /// backend controller's own docblock for why).
  Future<DataDeletionRequestDtoV1> requestAccountDeletion({
    String? reason,
  }) async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.accountDataDeletionRequests,
        data: <String, dynamic>{
          'confirm': true,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid deletion request response from server.',
        );
      }
      return DataDeletionRequestDtoV1.fromJson(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  Future<void> logout() async {
    final session = await currentSession();

    try {
      await networkClient.post(LaravelEndpoints.authLogout);
    } catch (_) {
      // Best-effort: the server-side token(s) may already be expired/revoked,
      // or the device may be offline. Local cleanup below must still happen.
    }

    await tokenLifecycleManager.clearTokens();
    await storageService.delete(GuardStorageKeys.authToken);
    await storageService.delete(GuardStorageKeys.userRole);
    await storageService.delete(GuardStorageKeys.platformAdmin);
    await storageService.delete(_userIdKey);
    await storageService.delete(_userNameKey);
    await storageService.delete(_userEmailKey);

    if (session != null) {
      await authEventPublisher.publishLoggedOut(userId: session.user.id);
    }
  }

  Future<AuthSession?> currentSession() async {
    final tokens = await tokenLifecycleManager.readTokens();
    if (tokens == null || tokens.accessToken.trim().isEmpty) {
      return null;
    }

    final userId = await storageService.readString(_userIdKey);
    final userName = await storageService.readString(_userNameKey);
    final userEmail = await storageService.readString(_userEmailKey);
    final roleRaw = await storageService.readString(GuardStorageKeys.userRole);
    final isPlatformAdmin = await storageService.readString(
      GuardStorageKeys.platformAdmin,
    );

    if (userId == null || userName == null || userEmail == null) {
      return null;
    }

    return AuthSession(
      user: UserEntity(id: userId, name: userName, email: userEmail),
      role: UserRoleStorage.fromStorageValue(roleRaw),
      isPlatformAdmin: isPlatformAdmin?.toLowerCase() == 'true',
    );
  }

  /// Shared by [login], [register], and [completeTwoFactorChallenge] — all
  /// three receive the identical AuthResource-shaped payload (access/
  /// refresh token pair + user) and must persist it identically.
  Future<AuthSession> _finalizeSession(Map<String, dynamic> payload) async {
    final dto = LoginResponseDtoV1.fromJson(payload);
    if (dto.accessToken.trim().isEmpty) {
      throw const AuthSessionException(
        'Authentication access token is missing from server response.',
      );
    }

    final scopes = dto.scope
        .split(' ')
        .where((scope) => scope.trim().isNotEmpty)
        .toSet();
    final role = UserRoleStorage.fromStorageValue(dto.user.role);

    await tokenLifecycleManager.writeTokens(
      TokenBundle(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken?.trim() ?? '',
        expiresAt: DateTime.now().add(Duration(seconds: dto.expiresIn)),
        scopes: scopes,
      ),
    );
    await storageService.writeString(
      GuardStorageKeys.authToken,
      dto.accessToken,
    );
    await storageService.writeString(
      GuardStorageKeys.userRole,
      role.toStorageValue(),
    );
    await storageService.writeString(
      GuardStorageKeys.platformAdmin,
      dto.user.isSuperAdmin.toString(),
    );
    await storageService.writeString(
      GuardStorageKeys.firstLaunchCompleted,
      'true',
    );
    await storageService.writeString(_userIdKey, dto.user.id);
    await storageService.writeString(_userNameKey, dto.user.name);
    await storageService.writeString(_userEmailKey, dto.user.email);

    await authEventPublisher.publishLoggedIn(
      userId: dto.user.id,
      email: dto.user.email,
    );

    return AuthSession(
      user: UserEntity(
        id: dto.user.id,
        name: dto.user.name,
        email: dto.user.email,
      ),
      role: role,
      isPlatformAdmin: dto.user.isSuperAdmin,
    );
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  String _messageFromDio(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final errors = responseData['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        if (firstError is String && firstError.trim().isNotEmpty) {
          return firstError;
        }
      }
    }

    final l10n = _localizations();
    if (error.response?.statusCode == 401) {
      return l10n.authInvalidCredentials;
    }
    if (error.type == DioExceptionType.connectionError) {
      return l10n.authConnectionError;
    }
    return l10n.authGenericFailure;
  }

  // A live visual review caught this: a network-interruption error on the
  // login screen showed hardcoded English text inside an otherwise-Arabic
  // UI, because these 3 fallback strings (unlike every backend-sourced
  // message above) were literal Dart strings with no locale awareness at
  // all. AppLocalizationsEn/Ar can be constructed directly — no
  // BuildContext needed, same as the generated class's own widget-facing
  // delegate does internally — so this needs no async asset load.
  AppLocalizations _localizations() {
    return localeReader?.call().languageCode == 'ar'
        ? AppLocalizationsAr()
        : AppLocalizationsEn();
  }
}
