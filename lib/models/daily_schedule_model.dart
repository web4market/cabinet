// lib/models/daily_schedule_model.dart - исправленная версия

class DailySchedule {
  final int id;
  final String title;
  final String startTime;
  final int userId;
  final List<Activity> activities;

  DailySchedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.userId,
    required this.activities,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    print('📦 DailySchedule.fromJson: $json');

    var activitiesList = <Activity>[];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();

      print('📦 Загружено ${activitiesList.length} активностей');
    }

    return DailySchedule(
      id: json['id'] ?? 0,
      title: json['p_name'] ?? 'Расписание',
      startTime: json['start_h'] ?? '08:00',
      userId: json['frontuser'] ?? 0,
      activities: activitiesList,
    );
  }

  // Получаем даты из заголовка расписания
  List<String> get dates {
    // Пример: "Расписание 18.02.2026 - 20.02.2026 для пациента: ..."
    final regex = RegExp(r'(\d{2}\.\d{2}\.\d{4})');
    final matches = regex.allMatches(title).toList();
    return matches.map((m) => m.group(1) ?? '').where((d) => d.isNotEmpty).toList();
  }

  // Получаем имя пациента из заголовка
  String get patientName {
    final parts = title.split('для пациента: ');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return 'Пациент';
  }

  // Группируем активности по дням
  Map<String, List<Activity>> get activitiesByDay {
    final grouped = <String, List<Activity>>{};

    // В данных нет явного разделения по дням, используем id_cell для определения дня
    // id_cell: 1001-1999 - день 1, 2001-2999 - день 2, 3001-3999 - день 3
    for (var activity in activities) {
      String day;
      if (activity.cellId >= 1001 && activity.cellId <= 1999) {
        day = 'День 1';
      } else if (activity.cellId >= 2001 && activity.cellId <= 2999) {
        day = 'День 2';
      } else if (activity.cellId >= 3001 && activity.cellId <= 3999) {
        day = 'День 3';
      } else {
        day = 'День ${activity.cellId ~/ 1000}';
      }

      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(activity);
    }

    // Сортируем активности в каждом дне по времени
    grouped.forEach((key, list) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return grouped;
  }
}

class Activity {
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

  Activity({
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

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      activityId: json['id_activity'],
      cellId: json['id_cell'] ?? 0,
      merge: json['merge'] ?? 0,
      startTime: json['start_t'] ?? '--:--',
      endTime: json['end_t'] ?? '--:--',
      textInCell: json['textincell']?.toString().trim() ?? '',
      duration: json['duration'] ?? 0,
      name: json['act_name'] ?? 'Занятие',
      description: json['description']?.toString().trim() ?? '',
    );
  }

  String get timeRange => '$startTime - $endTime';
  String get durationText => '$duration мин';

  String get room {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) return lines[0].trim();
    return 'Кабинет не указан';
  }

  String get specialist {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length > 1) return lines[1].trim();
    return 'Специалист не указан';
  }
}