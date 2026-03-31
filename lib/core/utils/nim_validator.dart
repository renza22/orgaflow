class NimValidator {
  static final RegExp _digitPattern = RegExp(r'^\d+$');

  static String normalize(String value) {
    return value.trim();
  }

  static String? validate(String value, {bool required = true}) {
    final normalized = normalize(value);

    if (normalized.isEmpty) {
      return required ? 'NIM wajib diisi.' : null;
    }

    if (!_digitPattern.hasMatch(normalized)) {
      return 'NIM hanya boleh berisi angka.';
    }

    return null;
  }
}
