import 'package:dio/dio.dart';

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
  const AuthSession({required this.user, required this.role});

  final UserEntity user;
  final UserRole role;
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
  });

  final NetworkClient networkClient;
  final TokenLifecycleManager tokenLifecycleManager;
  final StorageService storageService;
  final AuthEventPublisher authEventPublisher;

  static const _userIdKey = 'auth.user.id';
  static const _userNameKey = 'auth.user.name';
  static const _userEmailKey = 'auth.user.email';

  Future<AuthSession> login({
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

      final dto = LoginResponseDtoV1.fromJson(payload);
      if (dto.accessToken.trim().isEmpty || dto.refreshToken.trim().isEmpty) {
        throw const AuthSessionException(
          'Authentication tokens are missing from server response.',
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
          refreshToken: dto.refreshToken,
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
      );
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  Future<void> logout() async {
    final session = await currentSession();
    await tokenLifecycleManager.clearTokens();
    await storageService.delete(GuardStorageKeys.authToken);
    await storageService.delete(GuardStorageKeys.userRole);
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

    if (userId == null || userName == null || userEmail == null) {
      return null;
    }

    return AuthSession(
      user: UserEntity(id: userId, name: userName, email: userEmail),
      role: UserRoleStorage.fromStorageValue(roleRaw),
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
    }

    if (error.response?.statusCode == 401) {
      return 'Invalid email or password.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }
}
