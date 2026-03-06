import 'package:flutter/material.dart';

class ErrorHandler {
  // Понятные сообщения для пользователей
  static String getFriendlyErrorMessage(dynamic error) {
    // Проверяем тип ошибки
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection timed out')) {
      return 'Ошибка загрузки. Видимо, есть временные проблемы с интернетом.';
    }

    if (error.toString().contains('HTTP 500') ||
        error.toString().contains('Internal Server Error')) {
      return 'Ошибка загрузки. На сервере ведутся технические работы.';
    }

    if (error.toString().contains('HTTP 401') ||
        error.toString().contains('Unauthorized')) {
      return 'Ошибка авторизации. Пожалуйста, войдите заново.';
    }

    if (error.toString().contains('HTTP 404')) {
      return 'Ошибка загрузки. Данные не найдены.';
    }

    if (error.toString().contains('Timeout')) {
      return 'Ошибка загрузки. Сервер отвечает слишком долго.';
    }

    // По умолчанию
    return 'Ошибка загрузки. Видимо, есть временные проблемы с интернетом.';
  }

  // Получить иконку для ошибки
  static IconData getErrorIcon(dynamic error) {
    if (error.toString().contains('internet') ||
        error.toString().contains('Socket') ||
        error.toString().contains('network')) {
      return Icons.wifi_off;
    }
    if (error.toString().contains('500') ||
        error.toString().contains('server')) {
      return Icons.sync_problem;
    }
    return Icons.error_outline;
  }
}

// Расширение для DioError
extension DioErrorExtension on dynamic {
  bool get isNoInternetError {
    final errorStr = toString().toLowerCase();
    return errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('internet');
  }
}
