/// The seven engineering fields used by the aptitude test.
/// Display copy lives in [QuizCatalog]; this enum is the scoring identity.
///
/// Letter codes are scoring keys only and must never be rendered in the UI.
enum EngineeringField {
  computer,
  chemistry,
  environment,
  mechanical,
  electrical,
  industrial,
  civil;

  /// Official scoring codes: B, K, Ç, M, E, İ, N.
  String get code => switch (this) {
    EngineeringField.computer => 'B',
    EngineeringField.chemistry => 'K',
    EngineeringField.environment => 'Ç',
    EngineeringField.mechanical => 'M',
    EngineeringField.electrical => 'E',
    EngineeringField.industrial => 'İ',
    EngineeringField.civil => 'N',
  };

  static const Set<String> validCodes = {'B', 'K', 'Ç', 'M', 'E', 'İ', 'N'};

  static EngineeringField fromCode(String code) {
    final normalized = code.trim();
    for (final field in values) {
      if (field.code == normalized) {
        return field;
      }
    }
    throw FormatException('Unknown engineering code: $code');
  }
}
