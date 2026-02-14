import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL вашего PHP бэкенда
  static const String _baseUrl = 'https://cabinet.adelipnz.ru/api';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Сохраняем токен
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Получаем токен
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Удаляем токен
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // АВТОРИЗАЦИЯ
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('Login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final token = data['data']['token'];
          await saveToken(token);
          return {'success': true, 'token': token, 'user': data['data']['user']};
        } else {
          return {'success': false, 'error': data['message']};
        }
      }
      return {'success': false, 'error': 'Ошибка сервера'};
    } on DioException catch (e) {
      print('Login error: ${e.response?.data}');
      String errorMessage = 'Ошибка подключения к серверу';

      if (e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  // ПРОВЕРКА ТОКЕНА
  Future<bool> checkToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _dio.get(
        '/check',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ВЫХОД
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          '/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await deleteToken();
    }
  }
}