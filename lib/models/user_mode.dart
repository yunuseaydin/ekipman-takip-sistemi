class UserModel {
  final String uid;
  final String name;
  final String surname;
  final String email;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'staff',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'surname': surname, 'email': email, 'role': role};
  }
}
