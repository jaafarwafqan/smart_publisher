import 'package:dio/dio.dart';

import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/two_factor_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import 'auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): TOTP-based MFA management for the currently
/// authenticated user — enable/confirm/disable. The login-time challenge
/// step lives on [AuthSessionController] instead, since that one runs
/// before a real session exists.
class TwoFactorController {
  TwoFactorController({required this.networkClient});

  final NetworkClient networkClient;

  Future<TwoFactorEnableResponseDtoV1> enable() async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.authTwoFactorEnable,
      );
      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid two-factor enable response from server.',
        );
      }
      return TwoFactorEnableResponseDtoV1.fromJson(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  Future<TwoFactorConfirmResponseDtoV1> confirm({required String code}) async {
    try {
      final response = await networkClient.post(
        LaravelEndpoints.authTwoFactorConfirm,
        data: <String, dynamic>{'code': code},
      );
      final payload = _unwrapPayload(response.data);
      if (payload is! Map<String, dynamic>) {
        throw const AuthSessionException(
          'Invalid two-factor confirm response from server.',
        );
      }
      return TwoFactorConfirmResponseDtoV1.fromJson(payload);
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
  }

  Future<void> disable({required String password}) async {
    try {
      await networkClient.post(
        LaravelEndpoints.authTwoFactorDisable,
        data: <String, dynamic>{'password': password},
      );
    } on DioException catch (error) {
      throw AuthSessionException(_messageFromDio(error));
    }
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
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Check your connection.';
    }
    return 'Request failed. Please try again.';
  }
}
