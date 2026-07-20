import '../contract_version.dart';

class ApiEnvelopeV1 {
  const ApiEnvelopeV1({
    required this.success,
    required this.data,
    this.version = BackendContractVersion.v1,
  });

  final bool success;
  final dynamic data;
  final BackendContractVersion version;

  static ApiEnvelopeV1 fromJson(Map<String, dynamic> json) {
    return ApiEnvelopeV1(
      success: json['success'] as bool? ?? true,
      data: json['data'],
      version: _parseVersion(json['version']),
    );
  }

  static BackendContractVersion _parseVersion(Object? value) {
    if (value is String && value.toLowerCase() == 'v1') {
      return BackendContractVersion.v1;
    }
    return BackendContractVersion.v1;
  }
}
