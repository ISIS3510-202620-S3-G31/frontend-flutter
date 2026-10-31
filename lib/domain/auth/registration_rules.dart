/// Field rules of the register form, as pure functions: each one returns the
/// message to show under the field, or null when the value is good.
///
/// Kept free of Flutter so the rules can be read, reused and tested on their
/// own, without building a screen.
abstract final class RegistrationRules {
  static const minNameLength = 3;
  static const maxNameLength = 40;
  static const minPasswordLength = 8;

  /// Nobody older than this can register, so 1926 is the earliest year.
  static const maxAgeYears = 100;

  /// Nobody younger than this can register.
  static const minAgeYears = 13;

  // Letters of any alphabet, so accents and ñ are names, not symbols.
  static final _letters = RegExp(r'^[\p{L} ]+$', unicode: true);
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _uppercase = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');

  static String? name(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Enter your name.';
    if (name.length < minNameLength) {
      return 'At least $minNameLength letters.';
    }
    if (name.length > maxNameLength) {
      return 'At most $maxNameLength letters.';
    }
    if (!_letters.hasMatch(name)) return 'Letters and spaces only.';
    return null;
  }

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Enter your email.';
    if (!_email.hasMatch(email)) return 'Use the form name@example.com.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Enter a password.';
    if (value.length < minPasswordLength) {
      return 'At least $minPasswordLength characters.';
    }
    if (!_uppercase.hasMatch(value)) return 'Add one uppercase letter.';
    if (!_digit.hasMatch(value)) return 'Add one number.';
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value.isEmpty) return 'Repeat your password.';
    if (value != password) return 'The passwords do not match.';
    return null;
  }

  static String? birthDate(DateTime? value, {required DateTime today}) {
    if (value == null) return 'Pick your date of birth.';
    if (value.isAfter(today)) return 'That date has not happened yet.';
    if (value.isBefore(earliestBirthDate(today))) {
      return 'We cannot register someone that old.';
    }
    if (value.isAfter(latestBirthDate(today))) {
      return 'You must be at least $minAgeYears years old.';
    }
    return null;
  }

  /// January 1st of the earliest year allowed, so the whole year counts.
  static DateTime earliestBirthDate(DateTime today) =>
      DateTime(today.year - maxAgeYears);

  /// The day someone turning [minAgeYears] today was born, so the birthday
  /// itself already counts.
  static DateTime latestBirthDate(DateTime today) =>
      DateTime(today.year - minAgeYears, today.month, today.day);

  static int ageOn(DateTime birthDate, DateTime today) {
    final age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    return hadBirthday ? age : age - 1;
  }
}
