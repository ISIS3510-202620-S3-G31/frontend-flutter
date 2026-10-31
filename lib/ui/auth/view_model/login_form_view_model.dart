import 'package:flutter/foundation.dart';

import '../../../domain/auth/login_rules.dart';

class LoginFormViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';

  final Set<String> _touched = {};

  String get email => _email;
  String get password => _password;

  String? get emailError => _errorIfTouched('email', LoginRules.email(_email));

  String? get passwordError =>
      _errorIfTouched('password', LoginRules.password(_password));

  /// True when every rule passes, whether the fields were touched or not.
  bool get isValid =>
      LoginRules.email(_email) == null && LoginRules.password(_password) == null;

  void setEmail(String value) => _update('email', () => _email = value);

  void setPassword(String value) =>
      _update('password', () => _password = value);

  String? _errorIfTouched(String field, String? error) =>
      _touched.contains(field) ? error : null;

  void _update(String field, VoidCallback change) {
    change();
    _touched.add(field);
    notifyListeners();
  }
}
