import 'package:flutter/foundation.dart';

import '../../../domain/auth/registration_rules.dart';

/// Holds what the user typed in the register form and the message each field
/// should show while they type.
///
/// A field only complains once it has been touched, so the form does not open
/// covered in red, but it complains from the first keystroke afterwards.
class RegisterFormViewModel extends ChangeNotifier {
  RegisterFormViewModel({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  String _name = '';
  DateTime? _birthDate;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  final Set<String> _touched = {};

  String get name => _name;
  DateTime? get birthDate => _birthDate;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  DateTime get earliestBirthDate =>
      RegistrationRules.earliestBirthDate(_now());

  DateTime get latestBirthDate => RegistrationRules.latestBirthDate(_now());

  /// Where the date picker opens when the user has not chosen yet.
  DateTime get suggestedBirthDate => DateTime(_now().year - 20);

  /// Age the user will be stored with, null until they pick a date.
  int? get age {
    final birthDate = _birthDate;
    if (birthDate == null) return null;
    return RegistrationRules.ageOn(birthDate, _now());
  }

  String? get nameError => _errorIfTouched('name', RegistrationRules.name(_name));

  String? get birthDateError => _errorIfTouched(
    'birthDate',
    RegistrationRules.birthDate(_birthDate, today: _now()),
  );

  String? get emailError =>
      _errorIfTouched('email', RegistrationRules.email(_email));

  String? get passwordError =>
      _errorIfTouched('password', RegistrationRules.password(_password));

  String? get confirmPasswordError => _errorIfTouched(
    'confirmPassword',
    RegistrationRules.confirmPassword(_confirmPassword, _password),
  );

  /// True when every rule passes, whether the fields were touched or not.
  bool get isValid =>
      RegistrationRules.name(_name) == null &&
      RegistrationRules.birthDate(_birthDate, today: _now()) == null &&
      RegistrationRules.email(_email) == null &&
      RegistrationRules.password(_password) == null &&
      RegistrationRules.confirmPassword(_confirmPassword, _password) == null;

  void setName(String value) => _update('name', () => _name = value);

  void setBirthDate(DateTime value) =>
      _update('birthDate', () => _birthDate = value);

  void setEmail(String value) => _update('email', () => _email = value);

  /// Also refreshes the confirmation, which depends on this value.
  void setPassword(String value) =>
      _update('password', () => _password = value);

  void setConfirmPassword(String value) =>
      _update('confirmPassword', () => _confirmPassword = value);

  String? _errorIfTouched(String field, String? error) =>
      _touched.contains(field) ? error : null;

  void _update(String field, VoidCallback change) {
    change();
    _touched.add(field);
    notifyListeners();
  }
}
