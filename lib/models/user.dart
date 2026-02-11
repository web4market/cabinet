class User {
  final String token;
  final String? name;

  User({required this.token, this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'] ?? json['access_token'] ?? '',
      name: json['name'] ?? json['user_name'],
    );
  }
}