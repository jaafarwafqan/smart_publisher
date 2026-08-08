/// Sprint 4 (Commercial SaaS): TOTP-based MFA contracts, matching the
/// backend's `TwoFactorAuthController` (enable/confirm/disable, for the
/// already-authenticated user) and `TwoFactorChallengeController` (the
/// login-time step for an account that already has 2FA confirmed).
class TwoFactorEnableResponseDtoV1 {
  const TwoFactorEnableResponseDtoV1({
    required this.secret,
    required this.otpauthUrl,
  });

  /// Shown to the user once so they can type it into an authenticator app
  /// manually — the backend has no QR-image endpoint, only the raw
  /// otpauth:// URL below.
  final String secret;
  final String otpauthUrl;

  factory TwoFactorEnableResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return TwoFactorEnableResponseDtoV1(
      secret: (json['secret'] ?? '').toString(),
      otpauthUrl: (json['otpauth_url'] ?? '').toString(),
    );
  }
}

class TwoFactorConfirmResponseDtoV1 {
  const TwoFactorConfirmResponseDtoV1({required this.recoveryCodes});

  /// Shown once, in plaintext — the backend cannot show these again after
  /// this response.
  final List<String> recoveryCodes;

  factory TwoFactorConfirmResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final raw = json['recovery_codes'];
    return TwoFactorConfirmResponseDtoV1(
      recoveryCodes: raw is List<dynamic>
          ? raw.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
    );
  }
}
