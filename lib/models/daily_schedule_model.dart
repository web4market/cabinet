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
    }

    return DailySchedule(
      id: json['id'] ?? 0,
      title: json['p_name'] ?? 'Расписание',
      startTime: json['start_h'] ?? '08:00',
      userId: json['frontuser'] ?? 0,
      activities: activitiesList,
    );
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

  // Форматированное время
  String get timeRange => '$startTime - $endTime';

  // Длительность в минутах
  String get durationText => '$duration мин';

  // Извлекаем кабинет из textincell или description
  String get room {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      // Первая строка часто содержит кабинет
      return lines[0].trim();
    }
    return 'Кабинет не указан';
  }

  // Извлекаем специалиста
  String get specialist {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines = text.split('\n');
    if (lines.length > 1) {
      // Вторая строка часто содержит имя специалиста
      return lines[1].trim();
    }
    return 'Специалист не указан';
  }
}