/// Extracts the most useful, already-localized human-readable message from
/// a Laravel API error envelope — see `bootstrap/app.php`'s exception
/// renderer on the backend for the exact shape:
/// `{success, message, data, meta, errors}`.
///
/// For a 422 validation failure, `message` is only ever the generic
/// "Validation failed"/"فشل التحقق من صحة البيانات" — the actual reason
/// (e.g. "The email has already been taken.") lives in `errors[field][0]`,
/// so that takes priority. For every other status, `errors` holds internal
/// codes only (`{"code": ["unauthenticated"]}`), never text meant for a
/// user, so `message` (already `$e->getMessage()` or one of the
/// backend's own translated generic strings) is used directly.
///
/// Shared by every repository's error-mapping path
/// (`DefaultFailureMapper`, `PlatformAdminRepository`) so a caught
/// `DioException` never silently discards what the backend actually said
/// in favor of a fixed local fallback string, and never has this parsing
/// logic duplicated per repository.
String? extractBackendErrorMessage(dynamic responseData, int? statusCode) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }

  if (statusCode == 422) {
    final errors = responseData['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
  }

  final message = responseData['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }

  return null;
}
