class Role {
  final int id;
  final String role;

  Role({required this.id, required this.role});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      role: json['role'],
    );
  }

  Role copyWith({
    int? id,
    String? role,
  }) {
    return Role(
      id: id ?? this.id,
      role: role ?? this.role,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final int roleId;
  final String status;
  final Role role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    required this.status,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roleId: json['role_id'],
      status: json['status'],
      role: Role.fromJson(json['role']),
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    int? roleId,
    String? status,
    Role? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      role: role ?? this.role,
    );
  }
}
