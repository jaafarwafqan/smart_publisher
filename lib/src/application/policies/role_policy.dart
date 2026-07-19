import '../validators/permission_validator.dart';

class RolePolicy {
  const RolePolicy({this.validator = const PermissionValidator()});

  final PermissionValidator validator;

  String? validateRole(String? role) {
    return validator.validateRole(role);
  }
}
