class TitleValidator {
  const TitleValidator();

  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required.';
    }

    final normalized = value.trim();
    if (normalized.length < 3) {
      return 'Title must be at least 3 characters long.';
    }

    if (normalized.length > 120) {
      return 'Title must not exceed 120 characters.';
    }

    return null;
  }
}
