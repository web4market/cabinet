class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? name;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.name,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('🔧 UserModel.fromJson: $json');

    // Пробуем разные варианты получения данных
    // Вариант 1: данные прямо в корне
    if (json.containsKey('id')) {
      return UserModel(
        id: _parseInt(json['id']),
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString(),
        name: json['name']?.toString(),
        createdAt: _parseDate(json['created_at']),
        lastLogin: _parseDate(json['last_login']),
      );
    }

    // Вариант 2: данные в поле 'data'
    if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;
      return UserModel(
        id: _parseInt(data['id']),
        username: data['username']?.toString() ?? '',
        email: data['email']?.toString(),
        name: data['name']?.toString(),
        createdAt: _parseDate(data['created_at']),
        lastLogin: _parseDate(data['last_login']),
      );
    }

    // Если ничего не подошло
    print('❌ Неизвестный формат JSON: $json');
    throw FormatException('Неверный формат данных пользователя');
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Ошибка парсинга даты: $value');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}