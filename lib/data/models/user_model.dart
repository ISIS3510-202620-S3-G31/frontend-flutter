/// User profile model stored in Firestore under 'users/{uid}'.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.age,
  });

  final String uid;
  final String email;
  final String name;
  final int? age;

  UserModel copyWith({String? uid, String? email, String? name, int? age}) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  /// Serializes the user model to a map for Firestore.
  /// Must strictly contain only keys allowed by Firestore rules: ['name', 'age', 'email'].
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age ?? 0,
      'email': email,
    };
  }

  /// Deserializes a Firestore map into a [UserModel].
  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    int? parseAge(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UserModel(
      uid: id ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      age: parseAge(map['age']),
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $name, age: $age)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.age == age;
  }

  @override
  int get hashCode => Object.hash(uid, email, name, age);
}
