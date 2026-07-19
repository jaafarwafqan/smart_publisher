class PermissionValidator {
  const PermissionValidator();

  String? validateRole(String? role) {
    if (role == null || role.trim().isEmpty) {
      return 'Role is required.';
    }

    final normalized = role.trim().toLowerCase();
    if (!{'admin', 'editor', 'viewer'}.contains(normalized)) {
      return 'Role must be one of: admin, editor, viewer.';
    }

    return null;
  }
}
