class User {
  final int? id;
  final String name;
  final String email;
  final String role;
  final String password;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        role: json["role"],
        password: '', // لا تُرسل من API
      );
}