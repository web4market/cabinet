import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // для jsonDecode и jsonEncode

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
          return {
            'success': true,
            'token': token,
            'user': data['data']['user']
          };
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
// lib/services/api_service.dart - добавьте отладку в метод getProfile()

  // lib/services/api_service.dart - исправленный метод getProfile

  Future<Map<String, dynamic>> getProfile() async {
    try {
      print('🔍 getProfile() START');

      final token = await getToken();
      print('📌 Токен: ${token != null
          ? token.substring(0, 20) + "..."
          : "NULL"}');

      if (token == null) {
        print('❌ Токен отсутствует');
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      print('📤 Отправка запроса на /profile');
      print('📤 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await _dio.get(
        '/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          },
          responseType: ResponseType.json, // Явно указываем тип ответа
        ),
      );

      print('📥 Статус ответа: ${response.statusCode}');
      print('📥 Заголовки ответа: ${response.headers.map}');

      // ПРИНУДИТЕЛЬНО выводим данные
      print('📥 Тип данных: ${response.data.runtimeType}');
      print('📥 Данные (сырые): $response');
      print('📥 response.data: ${response.data}');

      if (response.data == null) {
        print('❌ response.data = null');
        return {
          'success': false,
          'message': 'Пустой ответ от сервера'
        };
      }

      // Пробуем распарсить
      if (response.data is Map) {
        print('✅ Данные в формате Map');
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        print('📥 Данные в формате String, пробуем распарсить...');
        try {
          final Map<String, dynamic> parsed = jsonDecode(response.data);
          print('✅ JSON распарсен успешно');
          return parsed;
        } catch (e) {
          print('❌ Ошибка парсинга JSON: $e');
          return {
            'success': false,
            'message': 'Ошибка формата данных: $e'
          };
        }
      }

      return {
        'success': false,
        'message': 'Неизвестный формат ответа'
      };
    } on DioException catch (e) {
      print('❌ DIO ОШИБКА:');
      print('   Тип: ${e.type}');
      print('   Статус: ${e.response?.statusCode}');
      print('   Сообщение: ${e.message}');
      print('   Данные ошибки: ${e.response?.data}');

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
        'message': 'Ошибка загрузки профиля: ${e.message}'
      };
    } catch (e) {
      print('❌ Неизвестная ошибка: $e');
      print('   Тип ошибки: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'Неизвестная ошибка: $e'
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
