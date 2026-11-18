class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'Student',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '1',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Користувач',
      role: json['role'] ?? 'Student',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
      };

  UserModel copyWith({String? name, String? email}) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role,
    );
  }
}
