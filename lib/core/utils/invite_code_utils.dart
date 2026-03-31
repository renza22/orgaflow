class InviteCodeUtils {
  static final RegExp _inviteCodePattern =
      RegExp(r'^[A-Z0-9]+-\d{4}-[A-Z0-9]+$');
  static final RegExp _whitespacePattern = RegExp(r'\s+');

  static String normalize(String value) {
    return value.replaceAll(_whitespacePattern, '').toUpperCase();
  }

  static bool isValid(String value) {
    return _inviteCodePattern.hasMatch(normalize(value));
  }
}
