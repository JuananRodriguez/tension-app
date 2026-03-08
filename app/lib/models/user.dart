class User {
  final int id;
  final String name;
  final String createdAt;

  User({required this.id, required this.name, required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
