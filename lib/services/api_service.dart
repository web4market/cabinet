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
  // Добавляем в класс ApiService:

  // ПОЛУЧЕНИЕ ПРОФИЛЯ
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      final response = await _dio.get(
        '/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;

    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await deleteToken();
        return {
          'success': false,
          'message': 'Сессия истекла',
          'needAuth': true
        };
      }

      return {
        'success': false,
        'message': 'Ошибка загрузки профиля'
      };
    }
  }

  // ОБНОВЛЕНИЕ ПРОФИЛЯ
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      if (data.isEmpty) {
        return {
          'success': false,
          'message': 'Нет данных для обновления'
        };
      }

      final response = await _dio.put(
        '/profile',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;

    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Ошибка обновления профиля'
      };
    }
  }

  // ПОЛУЧЕНИЕ РАСПИСАНИЯ
  Future<Map<String, dynamic>> getSchedule({
    String? dateFrom,
    String? dateTo,
    String period = 'all',
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      final response = await _dio.get(
        '/schedule',
        queryParameters: {
          'period': period,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;

    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await deleteToken();
        return {
          'success': false,
          'message': 'Сессия истекла',
          'needAuth': true
        };
      }

      return {
        'success': false,
        'message': 'Ошибка загрузки расписания'
      };
    }
  }

  // Лучше использовать JSON формат
  Future<Map<String, dynamic>> getScheduleJson({
    String? dateFrom,
    String? dateTo,
    String period = 'all',
  }) async {
    try {
      final token = await getToken();

      Map<String, String> queryParams = {
        'period': period,
        'format': 'json' // Запрашиваем JSON
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await _dio.get(
        '/schedule',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;

    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Ошибка загрузки расписания'
      };
    }
  }

  // СМЕНА ПАРОЛЯ
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      final response = await _dio.post(
        '/profile/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;

    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Ошибка смены пароля'
      };
    }
  }
}