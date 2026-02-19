import 'package:flutter/material.dart';

class ScheduleModel {
  final int id;
  final String title;
  final String startTime;
  final int userId;
  final List<ActivityModel> activities;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.userId,
    required this.activities,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    print('📦 ScheduleModel.fromJson: $json');

    // Безопасное преобразование id в int
    int scheduleId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        scheduleId = json['id'];
      } else if (json['id'] is String) {
        scheduleId = int.tryParse(json['id']) ?? 0;
      }
    }

    // Безопасное преобразование frontuser в int
    int userId = 0;
    if (json['frontuser'] != null) {
      if (json['frontuser'] is int) {
        userId = json['frontuser'];
      } else if (json['frontuser'] is String) {
        userId = int.tryParse(json['frontuser']) ?? 0;
      }
    }

    var activitiesList = <ActivityModel>[];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) => ActivityModel.fromJson(item))
          .toList();
    }

    return ScheduleModel(
      id: scheduleId,
      title: json['p_name']?.toString() ?? 'Расписание',
      startTime: json['start_h']?.toString() ?? '08:00',
      userId: userId,
      activities: activitiesList,
    );
  }

  // Получаем даты из заголовка расписания
  String get scheduleDate {
    final regex = RegExp(r'(\d{2}\.\d{2}\.\d{4})');
    final match = regex.firstMatch(title);
    return match?.group(1) ?? 'Неизвестно';
  }

  // Получаем имя пациента
  String get patientName {
    final parts = title.split('для пациента: ');
    return parts.length > 1 ? parts[1].trim() : 'Пациент';
  }
}

class ActivityModel {
  final int id;
  final int? activityId;
  final int cellId;
  final int merge;
  final String startTime;
  final String endTime;
  final String textInCell;
  final int duration;
  final String name;
  final String description;

  ActivityModel({
    required this.id,
    this.activityId,
    required this.cellId,
    required this.merge,
    required this.startTime,
    required this.endTime,
    required this.textInCell,
    required this.duration,
    required this.name,
    required this.description,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    print('📦 ActivityModel.fromJson: $json');

    // Безопасное преобразование id в int
    int activityId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        activityId = json['id'];
      } else if (json['id'] is String) {
        activityId = int.tryParse(json['id']) ?? 0;
      }
    }

    // Безопасное преобразование id_activity в int?
    int? idActivity;
    if (json['id_activity'] != null) {
      if (json['id_activity'] is int) {
        idActivity = json['id_activity'];
      } else if (json['id_activity'] is String) {
        idActivity = int.tryParse(json['id_activity']);
      }
    }

    // Безопасное преобразование id_cell в int
    int cellId = 0;
    if (json['id_cell'] != null) {
      if (json['id_cell'] is int) {
        cellId = json['id_cell'];
      } else if (json['id_cell'] is String) {
        cellId = int.tryParse(json['id_cell']) ?? 0;
      }
    }

    // Безопасное преобразование merge в int
    int merge = 0;
    if (json['merge'] != null) {
      if (json['merge'] is int) {
        merge = json['merge'];
      } else if (json['merge'] is String) {
        merge = int.tryParse(json['merge']) ?? 0;
      }
    }

    // Безопасное преобразование duration в int
    int duration = 0;
    if (json['duration'] != null) {
      if (json['duration'] is int) {
        duration = json['duration'];
      } else if (json['duration'] is String) {
        duration = int.tryParse(json['duration']) ?? 0;
      }
    }

    return ActivityModel(
      id: activityId,
      activityId: idActivity,
      cellId: cellId,
      merge: merge,
      startTime: json['start_t']?.toString() ?? '--:--',
      endTime: json['end_t']?.toString() ?? '--:--',
      textInCell: _cleanHtmlText(json['textincell']?.toString() ?? ''),
      duration: duration,
      name: json['act_name']?.toString() ?? 'Занятие',
      description: _cleanHtmlText(json['description']?.toString() ?? ''),
    );
  }

  // Очистка HTML тегов из текста
  static String _cleanHtmlText(String html) {
    // Удаляем HTML теги
    String text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // Заменяем множественные пробелы на один
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Декодируем HTML сущности
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");

    return text.trim();
  }

  String get timeRange => '$startTime - $endTime';
  String get durationText => '$duration мин';

  String get room {
    // Пробуем найти кабинет в тексте
    final roomRegex = RegExp(r'Кабинет\s*(\d+)', caseSensitive: false);
    final match = roomRegex.firstMatch(textInCell);
    if (match != null) {
      return 'Кабинет ${match.group(1)}';
    }

    final lines = textInCell.split(' ').where((l) => l.trim().isNotEmpty).toList();
    return lines.isNotEmpty ? lines[0].trim() : 'Кабинет не указан';
  }

  String get specialist {
    // Ищем специалиста (обычно после слова "Кабинет")
    final lines = textInCell.split(' ').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length > 1) {
      // Пропускаем первое слово (Кабинет ХХХ) и берем остальное
      return lines.skip(1).join(' ').trim();
    }
    return 'Специалист не указан';
  }
}