class MediaValidator {
  const MediaValidator();

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Media URL is required.';
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      return 'Media URL must be a valid absolute URL.';
    }

    return null;
  }

  String? validateMimeType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Media MIME type is required.';
    }

    final normalized = value.trim().toLowerCase();
    if (!normalized.contains('/')) {
      return 'Media MIME type must be in the format type/subtype.';
    }

    return null;
  }
}
