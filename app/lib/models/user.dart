class User {
  final int id;
  final String name;
  final String email;
  final bool? isAdmin;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isAdmin: json['is_admin'],
      createdAt: json['created_at'],
    );
  }
}
