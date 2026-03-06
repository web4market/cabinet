import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // для jsonDecode и jsonEncode

class ApiService {
  // URL PHP бэкенда
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

// ===== МЕТОД АВТОРИЗАЦИИ =====

  Future<Map<String, dynamic>> login(String username, String password,
      {bool remember = false}) async {
    if (username.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'error': 'Логин и пароль не могут быть пустыми'
      };
    }

    try {
      print('🔐 login: отправка запроса на $_baseUrl/login');

      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('📥 login ответ: статус ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          String? token;

          if (data['data'] is Map) {
            token = data['data']['token'];
          } else if (data['token'] != null) {
            token = data['token'];
          }

          if (token != null && token.isNotEmpty) {
            await saveToken(token);

            // СОХРАНЯЕМ ЛОГИН
            if (remember) {
              await saveLastLogin(username, remember: true);
            } else {
              await saveLastLogin(username, remember: false);
            }

            print('✅ login: токен сохранен, логин запомнен: $remember');

            return {
              'success': true,
              'token': token,
              'user': data['data']?['user'] ?? data['user']
            };
          }
        }
      }

      return {'success': false, 'error': 'Ошибка авторизации'};
    } on DioException catch (e) {
      print('❌ login ошибка: $e');
      return {'success': false, 'error': _handleDioError(e)};
    }
  }
  // lib/services/api_service.dart - добавьте эти методы

  // Сохраняем последний логин
  static Future<void> saveLastLogin(String username,
      {bool remember = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login', username);
    await prefs.setBool('remember_me', remember);
  }

  // Получаем последний логин
  static Future<String?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_login');
  }

  // Проверяем, нужно ли запоминать
  static Future<bool> shouldRemember() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
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

  // ПОЛУЧЕНИЕ ПРОФИЛЯ
  Future<Map<String, dynamic>> getProfile() async {
    try {
      print('🔍 getProfile() START');

      final token = await getToken();
      print(
          '📌 Токен: ${token != null ? token.substring(0, 20) + "..." : "NULL"}');

      if (token == null) {
        print('❌ Токен отсутствует');
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

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
          return {'success': false, 'message': 'Ошибка формата данных: $e'};
        }
      }

      return {'success': false, 'message': 'Неизвестный формат ответа'};
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
      return {'success': false, 'message': 'Неизвестная ошибка: $e'};
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
        return {'success': false, 'message': 'Нет данных для обновления'};
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
      return {'success': false, 'message': 'Ошибка обновления профиля'};
    }
  }

  // СМЕНА ПАРОЛЯ
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('ߔРchangePassword START');

      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      print('ߓĠОтправка запроса на /profile/change-password');
      print('ߓĠТокен: ${token.substring(0, 20)}...');

      final response = await _dio.post(
        '/profile/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('ߓŠСтатус ответа: ${response.statusCode}');
      print('ߓŠДанные ответа: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          return {'success': false, 'message': 'Сервер вернул пустой ответ'};
        }

        if (response.data is Map) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(response.data);
            return parsed;
          } catch (e) {
            return {
              'success': false,
              'message': 'Ошибка парсинга ответа: ${response.data}'
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Неверный формат ответа: ${response.data.runtimeType}'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Ошибка сервера: ${response.statusCode}'
        };
      }
    } on DioException catch (e) {
      print('❌ DIO Ошибка:');
      print('   Тип: ${e.type}');
      print('   Сообщение: ${e.message}');
      print('   Статус: ${e.response?.statusCode}');
      print('   Данные: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Сессия истекла',
          'needAuth': true
        };
      } else if (e.response?.statusCode == 400) {
        // Пробуем извлечь сообщение из ответа
        if (e.response?.data != null) {
          if (e.response!.data is Map) {
            return {
              'success': false,
              'message':
                  e.response!.data['message'] ?? 'Неверный текущий пароль'
            };
          }
        }
        return {'success': false, 'message': 'Неверный текущий пароль'};
      } else if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Нет подключения к интернету'};
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'Превышено время ожидания'};
      }

      return {'success': false, 'message': 'Ошибка соединения: ${e.message}'};
    } catch (e) {
      print('❌ Неизвестная ошибка: $e');
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  // ПОЛУЧЕНИЕ РАСПИСАНИЯ - ИСПРАВЛЕННАЯ ВЕРСИЯ
  Future<Map<String, dynamic>> getSchedule() async {
    try {
      print('🔍 getSchedule() START');

      final token = await getToken();
      if (token == null) {
        print('❌ Токен отсутствует');
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      print('📤 Запрос к /api/schedule');
      print('📤 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await _dio.get(
        '/schedule', // Простой запрос без параметров
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('📥 Статус ответа: ${response.statusCode}');
      print('📥 Тип данных: ${response.data.runtimeType}');
      print('📥 Данные: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          print('📊 success: ${data['success']}');
          print('📊 total: ${data['total']}');

          if (data['data'] is List) {
            print('📊 data длина: ${(data['data'] as List).length}');
          }

          return data;
        } else if (response.data is String) {
          try {
            final parsed = jsonDecode(response.data);
            return parsed as Map<String, dynamic>;
          } catch (e) {
            print('❌ Ошибка парсинга JSON: $e');
            return {'success': false, 'message': 'Ошибка формата данных'};
          }
        }
      }

      return {'success': false, 'message': 'Ошибка загрузки расписания'};
    } on DioException catch (e) {
      print('❌ DIO Ошибка: ${e.message}');
      if (e.response?.statusCode == 401) {
        await deleteToken();
        return {
          'success': false,
          'message': 'Сессия истекла',
          'needAuth': true
        };
      }
      return {'success': false, 'message': 'Ошибка соединения: ${e.message}'};
    } catch (e) {
      print('❌ Неизвестная ошибка: $e');
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  // ПОЛУЧЕНИЕ ВСЕХ КУРСОВ
  Future<Map<String, dynamic>> getCourses() async {
    try {
      print('🔍 getCourses() START');

      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Не авторизован',
          'needAuth': true
        };
      }

      print('📤 Запрос к /api/courses');

      final response = await _dio.get(
        '/courses',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          },
        ),
      );

      print('📥 Статус: ${response.statusCode}');
      print('📥 Данные: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('❌ Ошибка: ${e.message}');
      if (e.response?.statusCode == 401) {
        await deleteToken();
        return {
          'success': false,
          'message': 'Сессия истекла',
          'needAuth': true
        };
      }
      return {'success': false, 'message': 'Ошибка загрузки курсов'};
    }
  }

  // ПОЛУЧЕНИЕ СТАТИСТИКИ КУРСОВ
  Future<Map<String, dynamic>> getCoursesStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Не авторизован'};
      }

      final response = await _dio.get(
        '/courses/stats',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Ошибка загрузки статистики'};
    }
  }

  // ПОЛУЧЕНИЕ КОНКРЕТНОГО КУРСА
  Future<Map<String, dynamic>> getCourseById(int courseId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Не авторизован'};
      }

      final response = await _dio.get(
        '/courses/$courseId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Ошибка загрузки курса'};
    }
  }

  String _handleDioError(DioException e) {
    print('❌ _handleDioError: ${e.type}');
    print('❌ Сообщение: ${e.message}');

    if (e.response != null) {
      print('❌ Статус: ${e.response?.statusCode}');
      print('❌ Данные: ${e.response?.data}');
    }

    // Обработка различных типов ошибок
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания. Проверьте подключение к интернету.';

      case DioExceptionType.connectionError:
        return 'Нет подключения к интернету. Проверьте сеть.';

      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата безопасности.';

      case DioExceptionType.badResponse:
        // Обработка HTTP ошибок
        if (e.response?.statusCode == 401) {
          return 'Неверный логин или пароль';
        } else if (e.response?.statusCode == 403) {
          return 'Доступ запрещен';
        } else if (e.response?.statusCode == 404) {
          return 'Сервер не найден';
        } else if (e.response?.statusCode == 500) {
          return 'Внутренняя ошибка сервера';
        } else {
          return 'Ошибка сервера: ${e.response?.statusCode}';
        }

      case DioExceptionType.cancel:
        return 'Запрос был отменен';

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') ?? false) {
          return 'Нет подключения к интернету';
        }
        return 'Неизвестная ошибка: ${e.message}';

      default:
        return 'Ошибка подключения: ${e.message}';
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('ߓǠЗапрос на сброс пароля для email: $email');

      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      print('ߓŠОтвет: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Ошибка: $e');
      return {'success': false, 'message': 'Ошибка соединения с сервером'};
    }
  }

  // ПРОВЕРКА EMAIL (для отладки)
  Future<Map<String, dynamic>> checkEmail(String email) async {
    try {
      final response = await _dio.post(
        '/check-email',
        data: {'email': email},
      );
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
