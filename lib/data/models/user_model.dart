import 'package:intl/intl.dart';

import '../../domain/auth/registration_rules.dart';


class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.birthDate,
    this._age,
  });

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final String uid;
  final String email;
  final String name;

  /// Null in profiles saved before the date was stored; they only have an age.
  final DateTime? birthDate;

  final int? _age;

  int? get age {
    final birthDate = this.birthDate;
    if (birthDate == null) return _age;
    return RegistrationRules.ageOn(birthDate, DateTime.now());
  }


  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'age': ?age,
    'birthDate': ?_formatDay(birthDate),
  };

  /// Reads the document as this app or the Kotlin app saved it.
  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final birthDate = map['birthDate'];
    return UserModel(
      uid: id ?? _text(map['uid']),
      email: _text(map['email']),
      name: _text(map['name']),
      birthDate: birthDate is String ? DateTime.tryParse(birthDate) : null,
      age: _readAge(map['age']),
    );
  }

  static String? _formatDay(DateTime? day) =>
      day == null ? null : _dayFormat.format(day);

  static String _text(Object? value) => value is String ? value : '';


  static int? _readAge(Object? value) {
    final age = switch (value) {
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
    return age != null && age > 0 ? age : null;
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $name, '
      'birthDate: $birthDate, age: $age)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.birthDate == birthDate &&
        other._age == _age;
  }

  @override
  int get hashCode => Object.hash(uid, email, name, birthDate, _age);
}
