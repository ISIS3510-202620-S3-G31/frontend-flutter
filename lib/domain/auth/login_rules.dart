import 'registration_rules.dart';


abstract final class LoginRules {
  static const minPasswordLength = 6;

  static String? email(String value) => RegistrationRules.email(value);

  static String? password(String value) {
    if (value.isEmpty) return 'Enter your password.';
    if (value.length < minPasswordLength) {
      return 'At least $minPasswordLength characters.';
    }
    return null;
  }
}
